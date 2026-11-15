// lib/sandbox.dart
//
// Lua 执行沙箱。
//
// 运行时来自 flutter_lua_bridge（内置 Lua 源码，自动构建原生库），
// 全部通过 LuaRuntime 这一个入口访问。
//
// 执行模型：**用户代码是一个返回显示列表的 Lua 函数**。
//
// ```lua
// return function()
//   local c = canvas.new({ width = 360, height = 200 })
//   c:circle(70, 70, 40, { fill = "#4a9eff" })
//   return json.encode(c:build())
// end
// ```
//
// Dart 侧先执行 chunk 拿到这个函数，再调用它读返回值。
// 用 Lua 原生的返回值语义，不需要魔法全局变量。
//
// 核心约束：每次执行都重建 LuaRuntime，执行完立即销毁。
// 复用会导致全局变量泄漏，出现"删了一行代码但行为没变"这类难排查的问题。

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

/// 一次执行的结果。
class ExecResult {
  /// 显示列表 JSON。函数返回字符串时非空。
  final String? displayListJson;

  /// UI 契约信封 JSON。[runUi] 成功时非空。
  ///
  /// 与 [displayListJson] 分开而不是合并成一个 `json` 字段：
  /// 两种模式的产物结构完全不同，共用一个字段名只会让调用方靠
  /// “我这次调的是哪个函数”来猜类型。
  final String? uiTreeJson;

  /// print 的输出。
  final List<String> logs;

  /// 错误信息。成功时为 null。
  final String? error;

  /// 耗时（微秒）。
  final int elapsedMicros;

  ExecResult({
    this.displayListJson,
    this.uiTreeJson,
    this.logs = const [],
    this.error,
    required this.elapsedMicros,
  });

  bool get ok => error == null;
}

/// Lua 沙箱。每次 [run] 都是干净环境。
class LuaSandbox {
  /// 执行中标记。GUI 的防抖定时器可能在前一次执行未返回时再次触发。
  bool _busy = false;

  /// 执行一段 Lua；成功返回 null，失败返回错误信息。
  String? _exec(LuaRuntime lua, String code) {
    try {
      for (final value in lua.run(code)) {
        if (value is LuaRef) value.release();
      }
      return null;
    } on LuaBridgeException catch (e) {
      return e.message;
    }
  }

  /// 执行用户代码。
  ///
  /// [libraryPath] 指向 assets/lua，让用户代码能 require 到 canvas 等模块。
  /// [userCode] 必须返回一个函数；该函数应返回显示列表的 JSON 字符串。
  ///
  /// [budgetMs] 大于 0 时用 canvas_guard 包一层，给用户代码加协作式时间限制。
  /// 这比宿主侧超时更可靠——见[run] 里 budgetMs 的说明。
  ExecResult run(String userCode, {
    required String libraryPath,
    int budgetMs = 0,
  }) {
    final sw = Stopwatch()..start();

    // 直接拒绝重入而不是排队——编辑器场景下丢弃一次是合理的。
    if (_busy) {
      sw.stop();
      return ExecResult(
        error: '(上一轮仍在执行，本次已跳过)',
        elapsedMicros: sw.elapsedMicroseconds,
      );
    }
    _busy = true;

    LuaRuntime? runtime;
    try {
      final lua = runtime = newRestrictedState();

      // 库路径作为全局字符串传入，而不是内联进 Lua 源码。
      // 内联要用长括号包裹，路径里含 `]` 就会破坏语法。
      lua['__studio_libpath'] = libraryPath;

      var error = _exec(lua, sandboxBootstrap);
      if (error != null) {
        return ExecResult(
          error: '引导脚本执行失败: $error',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 用户代码
      const prelude = studioPrelude;
      final chunk = buildStudioSource(userCode);

      // 执行 prelude（预置能力绑定 + 执行保护安装），再把用户函数存进全局槽。
      // prelude 必须在 package.path 设好之后跑，
      // 否则 require("host.cli") 找不到文件。
      if (budgetMs > 0) {
        _exec(lua, '__studio_budget = $budgetMs');
      }
      error = _exec(lua, prelude);
      if (error != null) {
        return ExecResult(
          error: '预置能力加载失败: $error',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 用 load() 把 chunk 加载成函数再取出结果。
      // chunk 通过 [==[ ]==] 包裹，避免内容里的引号/括号干扰。
      //
      // 执行保护通过 **chunk 内的 __studio_invoke 间接层** 实现，
      // 不在 Dart 侧重新包装 __studio_fn——见下面那段 Lua。
      error = _exec(
        lua,
        'local f, err = load([==[$chunk]==], "editor")\n'
        'if not f then error(err) end\n'
        '__studio_fn = f()',
      );

      // 用户代码的语法/运行错误：日志也要取到
      if (error != null) {
        return ExecResult(
          error: error,
          logs: _decodeLogs(_takeLogs(lua)),
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      var function = lua['__studio_fn'];
      if (function is! LuaFunction) {
        return ExecResult(
          error: '代码必须返回函数。\n'
              '写法：return function() ... end\n'
              '当前返回的是 ${_typeName(function)}',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 装执行保护。必须在 __studio_fn 就位之后、调用之前。
      if (budgetMs > 0) {
        error = _exec(lua, studioGuardSetup);
        if (error != null) {
          return ExecResult(
            error: '无法启用执行保护：$error',
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
        // 取回被包装的函数
        function = lua['__studio_fn'];
      }

      final Object? value;
      try {
        final results = (function! as LuaFunction).call();
        value = results.isEmpty ? null : results.first;
      } on LuaBridgeException catch (e) {
        return ExecResult(
          error: e.message,
          logs: _decodeLogs(_takeLogs(lua)),
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      if (value is num) {
        return ExecResult(
          error: '函数应返回字符串（显示列表的 JSON），实际返回数字 ${value.toDouble()}',
          logs: _decodeLogs(_takeLogs(lua)),
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }
      if (value != null && value is! String) {
        return ExecResult(
          error: '函数应返回字符串（显示列表的 JSON），实际返回 ${_typeName(value)}',
          logs: _decodeLogs(_takeLogs(lua)),
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      return ExecResult(
        displayListJson: value as String?,
        logs: _decodeLogs(_takeLogs(lua)),
        elapsedMicros: sw.elapsedMicroseconds,
      );
    } catch (e) {
      return ExecResult(
        error: '沙箱异常: $e',
        elapsedMicros: sw.elapsedMicroseconds,
      );
    } finally {
      // 每次都销毁，杜绝状态残留
      try {
        runtime?.close();
      } catch (_) {
        // 关不掉也不能让应用崩
      }
      _busy = false;
      sw.stop();
    }
  }

  /// 执行 UI 模式的用户代码。
  ///
  /// 与 [run] 的关键差别：**用户代码是一个立即执行的 chunk**，不是返回函数。
  ///
  /// ```lua
  /// local app = ui.app({ state = {...}, handlers = {...}, view = function(b, s) ... end })
  /// return json.encode(app:build())
  /// ```
  ///
  /// chunk 执行时 `ui.app` 就把 app 登记到了模块级槽位，
  /// 所以 [eventName] 不为空时可以紧接着分发事件——不需要再跑一遍 view。
  ///
  /// [stateJson] 是上一轮的 UI 状态。原样透传给 `ui.seed_state`，
  /// `app.state` 省略时就用它。**这是事件能累积状态的关键**：
  /// 宿主每次执行都重建 Lua state，不注入的话每次事件都会把状态重置回初始值。
  ///
  /// [eventArgsJson] 是事件参数的 JSON（可为 null）。
  ExecResult runUi(String userCode, {
    required String libraryPath,
    String? stateJson,
    String? eventName,
    String? eventArgsJson,
    int budgetMs = 0,
  }) {
    final sw = Stopwatch()..start();

    if (_busy) {
      sw.stop();
      return ExecResult(
        error: '(上一轮仍在执行，本次已跳过)',
        elapsedMicros: sw.elapsedMicroseconds,
      );
    }
    _busy = true;

    LuaRuntime? runtime;
    try {
      final lua = runtime = newRestrictedState();

      ExecResult failed(String error, {bool withLogs = true}) => ExecResult(
        error: error,
        logs: withLogs ? _decodeLogs(_takeLogs(lua)) : const [],
        elapsedMicros: sw.elapsedMicroseconds,
      );

      lua['__studio_libpath'] = libraryPath;

      var error = _exec(lua, sandboxBootstrap);
      if (error != null) {
        return failed('引导脚本执行失败: $error', withLogs: false);
      }

      error = _exec(lua, uiPrelude);
      if (error != null) {
        return failed('预置能力加载失败: $error', withLogs: false);
      }

      // 状态 / 事件参数走全局槽传入，不内联进源码。
      // 内联要用长括号包 JSON，而 JSON 里可能含 `]==]`；走全局就没有这个坑。
      if (stateJson != null && stateJson.isNotEmpty) {
        lua['__studio_state'] = stateJson;
        // 必须真的调 ui.seed_state：`__studio_state` 只是中转站，
        // 模块读的是自己的 _STUDIO_UI_STATE。漏掉这一步的表现是
        // 「每次点按钮状态都回到初始值」，而界面看上去完全正常。
        error = _exec(lua, 'ui.seed_state(__studio_state)');
        if (error != null) return failed('状态注入失败：$error');
      }
      if (eventName != null) {
        lua['__studio_event'] = eventName;
        lua['__studio_event_args'] = eventArgsJson ?? '';
      }

      if (budgetMs > 0) {
        _exec(lua, '__studio_budget = $budgetMs');
      }

      // 加载成函数（而不是直接执行），这样执行保护能装在调用之前。
      //
      // chunk 内容用 [==[ ]==] 包裹，避免用户代码里的引号/括号干扰 Lua 语法。
      final chunk = userCode;
      error = _exec(
        lua,
        'local f, err = load([==[$chunk]==], "ui-editor")\n'
        'if not f then error(err) end\n'
        '__studio_fn = f',
      );
      if (error != null) return failed(error);

      if (budgetMs > 0) {
        error = _exec(
          lua,
          '__studio_fn = ui.wrap(__studio_fn, __studio_budget)',
        );
        if (error != null) return failed('无法启用执行保护：$error');
      }

      // 先跑用户 chunk（注册 app 并产出初始信封）。
      Object? value;
      try {
        final results = (lua['__studio_fn']! as LuaFunction).call();
        value = results.isEmpty ? null : results.first;
      } on LuaBridgeException catch (e) {
        return failed(e.message);
      }

      if (eventName != null) {
        // 事件阶段：以 dispatch 的结果为准，chunk 的返回值只是中间产物。
        try {
          value = lua.eval(
            'return ui.dispatch(__studio_event, __studio_event_args)',
          );
        } on LuaBridgeException catch (e) {
          return failed(e.message);
        }
      }

      // 构建阶段：chunk 的返回值就是契约信封。
      final bad = _rejectNonString(value);
      if (bad != null) return failed(bad);

      return ExecResult(
        uiTreeJson: value as String?,
        logs: _decodeLogs(_takeLogs(lua)),
        elapsedMicros: sw.elapsedMicroseconds,
      );
    } catch (e) {
      return ExecResult(
        error: '沙箱异常: $e',
        elapsedMicros: sw.elapsedMicroseconds,
      );
    } finally {
      try {
        runtime?.close();
      } catch (_) {
        // 关不掉也不能让应用崩
      }
      _busy = false;
      sw.stop();
    }
  }

  /// 调用 __studio_take_logs 取回日志。日志问题不该让执行失败。
  String? _takeLogs(LuaRuntime lua) {
    try {
      final take = lua['__studio_take_logs'];
      if (take is! LuaFunction) return null;
      final results = take.call();
      final logs = results.isEmpty ? null : results.first;
      return logs is String ? logs : null;
    } catch (_) {
      return null;
    }
  }

  /// Lua 值的类型名，用于错误提示。
  String _typeName(Object? value) => switch (value) {
    null => 'nil',
    bool() => 'boolean',
    num() => 'number',
    String() => 'string',
    LuaTable() => 'table',
    LuaFunction() => 'function',
    LuaThread() => 'thread',
    _ => 'userdata',
  };

  /// 检查返回值是不是字符串。是则返回 null，否则返回一条可直接展示的错误。
  String? _rejectNonString(Object? value) {
    if (value == null) {
      return '代码必须返回 UI 契约的 JSON 字符串，实际返回 nil。\n'
          '写法：return json.encode(app:build())';
    }
    if (value is String) return null;
    if (value is num) {
      return '代码必须返回 JSON 字符串，实际返回数字 ${value.toDouble()}';
    }
    return '代码必须返回 JSON 字符串，实际返回 ${_typeName(value)}';
  }

  /// 解码日志数组。
  ///
  /// 日志已由 Lua 侧 tostring 处理过，这里只需取出字符串。
  /// 解析失败就原样返回——日志问题不该让执行失败。
  List<String> _decodeLogs(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      final out = <String>[];
      final re = RegExp(r'"((?:[^"\\]|\\.)*)"');
      for (final m in re.allMatches(json)) {
        final raw = m.group(1)!;
        out.add(raw
            .replaceAll(r'\"', '"')
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\t', '\t')
            .replaceAll(r'\\', r'\'));
      }
      return out;
    } catch (_) {
      return [json];
    }
  }
}

/// 只打开 Lua 侧**声明过**的标准库。
///
/// 为什么不是 `openLibs()`：
///
/// 1. 性能——`io` / `coroutine` / `utf8` 全开是有成本的，而打包的 Lua 模块
///    一个都用不到（它们只用到 string / table / math / os.clock / debug /
///    package）。
/// 2. **更重要：这是把能力契约落到实处。** `host/init.lua` 一直声称
///    "业务 Lua 不直接碰 io / os / 网络"，但 `openLibs()` 把 io 也开了，
///    契约只是一句空话。开了门就等于没锁。
///
/// 掩码由 Lua 侧汇总（`assets/lua/perf.lua` 的 `declare_libs`）：
/// 新增一个需要 `io` 的能力时会**自动**把 io 纳进来，宿主这边不用改。
///
/// 掩码常量与 Lua 5.4 的 `lualib.h` 一致（对应 perf.lua 的 LIB_MASKS）。
const int kLuaLibGlb = 1;        // 基础库，永远需要
const int kLuaLibLoadlib = 2;    // package / require
const int kLuaLibColib = 4;      // coroutine
const int kLuaLibDblib = 8;      // debug
const int kLuaLibIolib = 16;     // io
const int kLuaLibMathlib = 32;   // math
const int kLuaLibOslib = 64;     // os
const int kLuaLibStrlib = 128;   // string
const int kLuaLibTablib = 256;   // table
const int kLuaLibUtf8lib = 512;  // utf8

/// 引导集：跑 `require("perf")` 把声明读出来所需要的最少集合。
///
/// 故意留够：读声明之后如果声明集合落在引导集内，就不用重建 state
/// （Lua 没有"卸载某个库"的 API，只能关掉整个 state 重开）。
/// os / debug 在这里是因为 guard 自己就要用（os.clock + debug.sethook）。
const int kBootstrapLibMask =
    kLuaLibGlb |
    kLuaLibLoadlib |
    kLuaLibStrlib |
    kLuaLibTablib |
    kLuaLibMathlib |
    kLuaLibOslib |
    kLuaLibDblib;

/// 回退掩码：读不到声明时用它。宁可多开也不要打不开——
/// 少开一个库的表现是用户代码报 `attempt to index a nil value (global 'io')`，
/// 这种错出现在业务代码里极难定位；多开只是慢一点。
const int kFullLibMask =
    kBootstrapLibMask | kLuaLibIolib | kLuaLibColib | kLuaLibUtf8lib;

/// 把 Lua 侧声明的掩码换算成 [LuaLibrary] 掩码。
///
/// `package` 对应不受限的 package 库：打包的模块要靠 package.path 从文件加载。
/// 没声明 io 时，运行时会顺带拿掉 dofile / loadfile，并让 load 只接受文本。
int _toRuntimeLibraries(int mask) {
  const mapping = <int, int>{
    kLuaLibGlb: LuaLibrary.base,
    kLuaLibLoadlib: LuaLibrary.package,
    kLuaLibColib: LuaLibrary.coroutine,
    kLuaLibDblib: LuaLibrary.debug,
    kLuaLibIolib: LuaLibrary.io,
    kLuaLibMathlib: LuaLibrary.math,
    kLuaLibOslib: LuaLibrary.os,
    kLuaLibStrlib: LuaLibrary.string,
    kLuaLibTablib: LuaLibrary.table,
    kLuaLibUtf8lib: LuaLibrary.utf8,
  };
  var libraries = LuaLibrary.none;
  for (final entry in mapping.entries) {
    if (mask & entry.key != 0) libraries |= entry.value;
  }
  return libraries;
}

/// 新建一个只带「声明过的库」的 state。
///
/// [onMask] 回报实际使用的掩码与库名，测试与诊断用；业务路径可以不管。
///
/// ## 为什么要缓存
///
/// 声明来自打包进 assets 的 Lua 源码，**在一次进程内是常量**
/// （assets 变了就得重新构建，进程也就重启了）。
/// 而每次执行都跑两遍 `doString` 去读它，是纯开销——实测每执行多花 0.2ms，
/// 比省下来的开库时间还多。所以只读一次。
LuaRuntime newRestrictedState({
  void Function(int mask, List<String> libs)? onMask,
}) {
  final mask = _declaredLibMask();
  final libs = onMask != null ? _declaredLibNames() : _cachedLibNames;

  final lua = LuaRuntime.create(libraries: _toRuntimeLibraries(mask));
  if (onMask != null) onMask(mask, libs ?? const []);
  return lua;
}

int? _cachedMask;
List<String>? _cachedLibNames;

/// 取汇总出来的库掩码，只算一次。
int _declaredLibMask() {
  _cachedMask ??= _probeDeclaredMask();
  return _cachedMask!;
}

List<String>? _declaredLibNames() {
  if (_cachedLibNames != null) return _cachedLibNames;
  _cachedLibNames = _probeDeclaredLibNames();
  return _cachedLibNames;
}

/// 读声明用的临时 state：必须先全开，因为 perf 自己就在被声明的那些模块里。
int _probeDeclaredMask() {
  final probe = LuaRuntime.create(libraries: LuaLibrary.all);
  try {
    return _readDeclaredMask(probe) ?? kFullLibMask;
  } finally {
    probe.close();
  }
}

List<String> _probeDeclaredLibNames() {
  final probe = LuaRuntime.create(libraries: LuaLibrary.all);
  try {
    return _readDeclaredLibs(probe);
  } finally {
    probe.close();
  }
}

/// 读 Lua 侧汇总的库掩码。读失败返回 null（调用方决定回退）。
int? _readDeclaredMask(LuaRuntime lua) {
  try {
    final mask = lua.eval(
      'local ok, perf = pcall(require, "perf")\n'
      'if not ok then return nil end\n'
      'return perf.lib_mask()',
    );
    if (mask is! num) return null;
    return mask <= 0 ? null : mask.toInt();
  } on LuaBridgeException {
    return null;
  }
}

/// 读库名列表，只用于诊断输出。
List<String> _readDeclaredLibs(LuaRuntime lua) {
  try {
    final names = lua.eval(
      'local ok, perf = pcall(require, "perf")\n'
      'if not ok then return "" end\n'
      'local _, names = perf.lib_mask()\n'
      'return table.concat(names, ",")',
    );
    if (names is! String || names.isEmpty) return const [];
    return names.split(',');
  } on LuaBridgeException {
    return const [];
  }
}

/// 引导脚本：设 package.path、加载日志与 json 能力、接管 print。
///
/// 与具体模式无关，画布与 UI 两条链路共用。
///
/// 顺序不能反——host/cli 在 assets/lua/host/cli.lua，
/// 路径没设好会报 "no file './host/cli.lua'"。
const String sandboxBootstrap = '''
local root = __studio_libpath
package.path = table.concat({
  -- 字节码优先。Lua 的搜索器按 package.path 顺序逐个试，谁先命中用谁。
  --
  -- 每次执行都重建 LuaRuntime，所以"找文件 + 解析源码"是**每次都要付**的：
  -- 实测打包的 6 个模块解析一遍 0.63ms，而加载字节码只要 0.075ms。
  -- 放在后面（而不是取代 .lua）是为了留退路——字节码缺失或版本不匹配时，
  -- Lua 会静默落到 .lua 上，功能不受影响，只是慢一点。
  root .. "/__bc/?.luac",
  root .. "/__bc/?/init.luac",
  root .. "/?.lua",
  root .. "/?/init.lua",
  root .. "/vendor/?.lua",
  package.path,
}, ";")

require("host.cli")

__studio_logs = {}
print = function(...)
  local n = select("#", ...)
  local parts = {}
  for i = 1, n do parts[i] = tostring((select(i, ...))) end
  __studio_logs[#__studio_logs + 1] = table.concat(parts, " ")
end

-- 执行完毕后由 Dart 读取，把日志编码成 JSON 传回。
-- 必须在用户代码调用前定义：用户代码里的 print 依赖它。
__studio_take_logs = function()
  local json = require("host").require_cap("json")
  local out = json.encode(__studio_logs)
  __studio_logs = {}
  return out
end
''';

/// 预置能力绑定。单独执行，让用户代码保持干净。
///
/// 必须用全局（不带 local）——用户代码是另一个 chunk，
/// 局部变量在它那里不可见。
const String studioPrelude = '''
host = require("host")
canvas = require("canvas")
json = host.require_cap("json")
''';

/// UI 模式的预置绑定。
///
/// 与画布模式的差别只有一个：`ui`。
/// 两个全局都在同一个 chunk 里设，但**分两次执行**——
/// 因为用户代码属于两种互斥的模式，prelude 多加载一个模块的代价很小，
/// 而拆开能让 [run] / [runUi] 共用同一段引导代码。
const String uiPrelude = '''
host = require("host")
ui = require("ui")
json = host.require_cap("json")
''';

/// 在用户函数装进全局槽**之后**执行，给它套上时间保护。
///
/// 单独一个 chunk，因为要等 __studio_fn 就位。
/// [budgetMs] 已经被 Dart 侧写进 __studio_budget。
const String studioGuardSetup = '''
if __studio_budget and __studio_budget > 0 then
  __studio_fn = canvas.wrap(__studio_fn, __studio_budget)
end
''';

/// 构造用户函数。
///
/// 支持两种写法：
///
/// **1. 显式返回函数**（推荐，能带参数、可复用）
/// ```lua
/// return function(scale)
///   local c = canvas.new({ width = 300 * scale, height = 200 })
///   c:circle(150, 100, 60)
///   return json.encode(c:build())
/// end
/// ```
///
/// **2. 直接写代码体**（等价于自动包一层 function）
/// ```lua
/// local c = canvas.new({ width = 300, height = 200 })
/// c:circle(150, 100, 60)
/// return json.encode(c:build())
/// ```
///
/// 两种都支持：编辑器里写片段更自然，完整文件通常用显式形式。
/// 产出是一个返回 function 的表达式，由调用方决定怎么执行。
String buildStudioSource(String userCode) {
  // 情况 1：用户显式写了 return function
  if (RegExp(r'return\s+function').hasMatch(userCode)) {
    return userCode;
  }

  // 情况 2：把代码体包进函数。
  // 即使用户只写了 `local x = 1`（无 return），包起来也无害——
  // 函数返回 nil，宿主会提示"没有产出显示列表"。
  return 'return function()\n$userCode\nend';
}
