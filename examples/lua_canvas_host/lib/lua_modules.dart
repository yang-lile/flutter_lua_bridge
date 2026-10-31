// lib/lua_modules.dart
//
// Lua 模块清单解析与落盘。
//
// 不依赖 Flutter，所以命令行工具与单元测试都能直接用。

import 'dart:convert';
import 'dart:io';

import 'package:flutter_lua_bridge/raw.dart';

/// Lua 模块加载结果。
class LuaModules {
  LuaModules({
    required this.root,
    required this.sources,
    required this.missing,
  });

  /// 可供 Lua require 的目录（临时目录）。
  final String root;

  /// assets 路径 -> 源码内容。
  final Map<String, String> sources;

  /// 清单里声明但没能加载的路径。
  final List<String> missing;

  int get count => sources.length;
}

/// 从清单文本里取出 assets 路径。
///
/// 清单同时被 Flutter assets 与本模块消费，规则必须一致。
List<String> parseLuaManifest(String text) {
  const prefix = 'assets/lua/';
  final out = <String>[];
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (!line.startsWith(prefix)) continue;
    out.add(line);
  }
  return out;
}

/// 同步版本：模块内容已在内存里（CLI 从磁盘读到）。
LuaModules materializeLuaModules(
  List<String> assetPaths,
  String Function(String assetPath) reader, {
  String? tempPrefix,
}) {
  final dir = Directory.systemTemp.createTempSync(tempPrefix ?? 'lua_canvas_');
  final sources = <String, String>{};
  final missing = <String>[];

  const prefix = 'assets/lua/';

  for (final assetPath in assetPaths) {
    final String content;
    try {
      content = reader(assetPath);
    } catch (_) {
      missing.add(assetPath);
      continue;
    }

    sources[assetPath] = content;
    final subPath = assetPath.startsWith(prefix)
        ? assetPath.substring(prefix.length)
        : assetPath;

    File('${dir.path}/$subPath')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  return LuaModules(root: dir.path, sources: sources, missing: missing);
}

/// 异步版本：应用侧 rootBundle 只能异步读，所以这是应用用的主实现。
Future<LuaModules> materializeLuaModulesAsync(
  List<String> assetPaths,
  Future<String> Function(String assetPath) reader, {
  String? tempPrefix,
}) async {
  final dir = Directory.systemTemp.createTempSync(tempPrefix ?? 'lua_canvas_');
  final sources = <String, String>{};
  final missing = <String>[];

  const prefix = 'assets/lua/';

  for (final assetPath in assetPaths) {
    final String content;
    try {
      content = await reader(assetPath);
    } catch (_) {
      missing.add(assetPath);
      continue;
    }

    sources[assetPath] = content;
    final subPath = assetPath.startsWith(prefix)
        ? assetPath.substring(prefix.length)
        : assetPath;

    File('${dir.path}/$subPath')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  return LuaModules(root: dir.path, sources: sources, missing: missing);
}

/// 从磁盘加载（命令行工具、测试用）。
LuaModules loadLuaModulesFromDisk({String assetsDir = 'assets/lua'}) {
  final manifestFile = File('$assetsDir/manifest.txt');
  if (!manifestFile.existsSync()) {
    throw StateError('缺少 $assetsDir/manifest.txt');
  }

  final paths = parseLuaManifest(manifestFile.readAsStringSync());

  return materializeLuaModules(paths, (path) {
    final f = File(path);
    if (!f.existsSync()) {
      throw StateError('文件不存在：$path');
    }
    return f.readAsStringSync();
  });
}
// ============ 字节码预编译 ============
//
// ## 为什么需要
//
// 沙箱每次执行都重建 LuaState（这是有意的：复用会导致全局变量泄漏，
// 出现"删了一行代码但行为没变"这类难查的问题）。
// 代价是**每次执行都要把全部 Lua 模块重新解析一遍**。
//
// 实测（每次执行）：
//
//   解析源码      0.629 ms      <- 基本等于整条链路的固定成本
//   加载字节码    0.075 ms      <- 快 8 倍
//
// 也就是说：固定成本里**九成是重复解析源码**，不是 FFI、不是跨界。
//
// ## 为什么在运行时生成而不是构建时
//
// Lua 字节码**与解释器版本绑定**。当前 flutter_lua_bridge 和仓库里用于跑测试
// 的 `lua` CLI 都是 Lua 5.4；仍然由应用运行时生成，确保字节码始终来自实际
// 加载它的解释器，避免工具链升级或旧产物导致 "bad header"。
//
// 所以必须由**将要加载它的那个解释器**来生成，即应用自己，在首次执行前做一次。
// 生成物落在 assets 落盘时的临时目录里，进程结束即消失，不会有陈旧问题。
//
// ## 预编译用的 state 是开全套库的
//
// 写文件需要 io，而正式执行的 state 是**故意不开 io** 的（见 sandbox.dart 的
// newRestrictedState）。这两件事互不干涉：预编译是一次性的独立 state。

/// 预编译产物在临时目录里的子目录名。
const String kBytecodeDir = '__bc';

/// 把 [root] 下的 Lua 模块编译成字节码，写到 `<root>/__bc/`。
///
/// 只做一次，调用方负责在合适时机（worker 启动前）调它。
/// 失败不抛——字节码只是优化，没有它一样能跑（只是慢）。
///
/// 返回成功编译的模块名。
List<String> precompileLuaModules(String root, List<String> modules) {
  final compiled = <String>[];
  final bcRoot = '$root/$kBytecodeDir';
  try {
    // 先把每个模块的目标目录建出来。`io.open(..., "wb")` 不会创建父目录，
    // 只有顶层模块（perf / guard）能写成功，子目录的（canvas/init、
    // host/cli、ui/init）会静默失败——而且失败得很像"编译没生效"。
    for (final name in modules) {
      final rel = name.replaceAll('.', '/');
      final dir = rel.contains('/') ? '$bcRoot/${rel.substring(0, rel.lastIndexOf('/'))}' : bcRoot;
      Directory(dir).createSync(recursive: true);
    }
  } catch (_) {
    return compiled;
  }

  LuaState? lua;
  try {
    // 这里**必须**开全套库：要 io 写文件，也要 require 走 package.path。
    lua = LuaState.newState();
    lua.openLibs();

    lua.pushString(root);
    lua.setGlobal('__pre_root');
    lua.pushString(bcRoot);
    lua.setGlobal('__pre_out');
    lua.pushString(modules.join(','));
    lua.setGlobal('__pre_modules');

    final r = lua.doString(r'''
local root, out, mods = __pre_root, __pre_out, __pre_modules
local done = {}
for name in mods:gmatch("[^,]+") do
  -- 包名 -> require 约定的路径。两种形态都要试：
  --   a.b  -> a/b.lua 或 a/b/init.lua
  -- 少了后一种，canvas / host / ui 这三个就静默编译不出来。
  local rel = name:gsub("%.", "/")
  local src = root .. "/" .. rel .. ".lua"
  local chunk = loadfile(src)
  if not chunk then
    src = root .. "/" .. rel .. "/init.lua"
    chunk = loadfile(src)
  end
  if chunk then
    local dump = string.dump(chunk)
    -- 字节码必须与解释器版本一致，所以只能运行时生成（见文件头说明）
    -- 父目录由 Dart 侧预先建好：io.open 不会自动建目录
    local dest = out .. "/" .. rel .. ".luac"
    local f = io.open(dest, "wb")
    if f then
      f:write(dump)
      f:close()
      done[#done + 1] = name
    end
  end
end
return table.concat(done, ",")
''');

    if (r.isOk && !lua.isNil(-1)) {
      final raw = lua.getString(-1);
      if (raw != null && raw.isNotEmpty) {
        compiled.addAll(raw.split(','));
      }
    }
  } catch (_) {
    // 预编译失败就走源码路径，不影响功能
  } finally {
    try {
      lua?.close();
    } catch (_) {
      // 关不掉也不该让启动失败
    }
  }

  return compiled;
}

/// 给 package.path 用的字节码搜索路径。
///
/// 放在 `.lua` **前面**：Lua 的搜索器按 package.path 的顺序逐个试，
/// 谁先命中用谁。
String bytecodePathEntry(String root) => '$root/$kBytecodeDir/?.luac';

/// 列出 [root] 下可 `require` 的模块名。
///
/// 从磁盘扫而不是从 manifest 传进来：worker 只拿到一个路径字符串，
/// 扫一遍临时目录最省事，也避免"清单和实际不一致"这类问题。
///
/// 跳过的目录：
///   `__bc/`   —— 预编译产物，不是模块
///   `spec/`   —— 测试，不参与运行时
List<String> listLuaModuleNames(String root) {
  final names = <String>[];
  void walk(Directory dir, String prefix) {
    final entries = dir.listSync();
    for (final e in entries) {
      if (e is! File) continue;
      final p = e.path;
      final rel = p.substring(root.length + 1);
      final parts = rel.split('/');
      if (parts.any((s) => s == kBytecodeDir || s == 'spec')) continue;
      if (!p.endsWith('.lua')) continue;
      // a/b.lua -> a.b；a/init.lua -> a
      final stem = rel.substring(0, rel.length - 4);
      if (stem.endsWith('/init')) {
        names.add(stem.substring(0, stem.length - 5).replaceAll('/', '.'));
      } else {
        names.add(stem.replaceAll('/', '.'));
      }
    }
    for (final e in entries) {
      if (e is Directory) {
        final rel = e.path.substring(root.length + 1);
        if (rel == kBytecodeDir || rel == 'spec' || rel == 'out') continue;
        walk(e, '$prefix${rel.split('/').last}.');
      }
    }
  }

  final dir = Directory(root);
  if (!dir.existsSync()) return names;
  walk(dir, '');
  names.sort();
  return names;
}
