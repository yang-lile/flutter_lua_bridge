// lib/lua_loader.dart
//
// 应用侧的 Lua 模块加载：走 Flutter assets。
//
// 只在 Flutter 环境用；命令行工具请用 lua_modules.dart，
// 那份不依赖 Flutter，纯 Dart 入口不会把 UI 层拖进来。

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'lua_modules.dart';

/// 基于 Flutter assets 的加载器。
class LuaLoader {
  LuaLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  LuaModules? _modules;

  /// 已加载的模块数。
  int get moduleCount => _modules?.count ?? 0;

  /// 加载失败的路径。
  List<String> get missing => _modules?.missing ?? const [];

  /// 加载一次并返回可供 require 的目录。重复调用返回同一结果。
  Future<String> init() async {
    final cached = _modules;
    if (cached != null) return cached.root;

    const manifestAsset = 'assets/lua/manifest.txt';
    final manifest = await _bundle.loadString(manifestAsset);
    final paths = parseLuaManifest(manifest);

    _modules = await materializeLuaModulesAsync(paths, _bundle.loadString);

    final m = _modules!;
    if (m.missing.isNotEmpty) {
      // 说明 pubspec 的 assets 声明与清单不一致，
      // 构建期应由 tools/check_manifest.sh 拦住
      throw StateError(
        '以下 Lua 模块未打进包：\n  ${m.missing.join('\n  ')}\n'
        '请确认 pubspec.yaml 的 assets 声明完整。',
      );
    }

    return m.root;
  }
}