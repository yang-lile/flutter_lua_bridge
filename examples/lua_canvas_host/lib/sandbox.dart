// lib/sandbox.dart
//
// Lua 执行沙箱。
//
// 运行时来自 flutter_lua_bridge（源码内置 Lua 5.4，自动构建原生库）。
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
// Dart 侧先 loadString 把这个函数压栈，再 pcall 调用它读返回值。
// 用 Lua 原生的返回值语义，不需要魔法全局变量。
//
// 核心约束：每次执行都重建 LuaState，执行完立即销毁。
// 复用会导致全局变量泄漏，出现"删了一行代码但行为没变"这类难排查的问题。

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:flutter_lua_bridge/raw.dart';
import 'package:flutter_lua_bridge/raw.dart' as flb;

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
  /// 执行中标记。LuaState 不是线程安全的也不是可重入的。
  bool _busy = false;

  /// 保护调用：调用栈顶函数，取 nresults 个返回值。
  ///
  /// 走底层 [FlutterLuaBridge.cApi] 的 lua_pcallk，而非 LuaState.pcall。
  ///
  /// 原因：LuaState.pcall 绑定的是 `lua_pcall`，而它在 Lua 头文件里
  /// 是**宏**（展开为 6 参的 lua_pcallk）。ffigen 按 4 参生成了绑定，
  /// 实测调用后栈顶仍是函数本身而非调用结果。
  /// `lua_pcallk` 才是真实的 6 参函数，这里直接用它。
  LuaStatusCode _call(LuaState lua, int nresults) {
    final status = FlutterLuaBridge.cApi.lua_pcallk(
      lua.rawState,
      0, // nargs
      nresults,
      0, // msgh
      0, // ctx
      ffi.nullptr, // k（NULL 表示不允许 yield）
    );
    return LuaStatusCode(status);
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

    // GUI 的防抖定时器可能在前一次执行未返回时再次触发。
    // 直接拒绝重入而不是排队——编辑器场景下丢弃一次是合理的。
    if (_busy) {
      sw.stop();
      return ExecResult(
        error: '(上一轮仍在执行，本次已跳过)',
        elapsedMicros: sw.elapsedMicroseconds,
      );
    }
    _busy = true;

    LuaState? lua;
    try {
      lua = newRestrictedState();

      // 库路径作为全局字符串传入，而不是内联进 Lua 源码。
      // 内联要用长括号包裹，路径里含 `]` 就会破坏语法。
      lua.pushString(libraryPath);
      lua.setGlobal('__studio_libpath');

      if (!lua.doString(sandboxBootstrap).isOk) {
        return ExecResult(
          error: '引导脚本执行失败: ${_takeError(lua)}',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 用户代码
      const prelude = studioPrelude;
      final chunk = buildStudioSource(userCode);

      // 执行 prelude（预置能力绑定 + 执行保护安装），再把用户函数存进全局槽。
      //
      // 为什么保护装在 Lua 侧而不是 Dart 侧包一层：
      // flutter_lua_bridge 的 doString 走 luaL_loadstring，
      // 内部含 pcall；而 canvas.wrap 也用 pcall。实测这条路径下
      // 从 Dart 侧再包一层会导致执行挂起。放在 prelude 里
      // 由纯 Lua 完成，绕开了这个问题。
      //
      // 同时 prelude 必须在 package.path 设好之后跑，
      // 否则 require("host.cli") 找不到文件。
      if (budgetMs > 0) {
        lua.doString('__studio_budget = $budgetMs');
      }
      if (!lua.doString(prelude).isOk) {
        final err = _takeError(lua);
        return ExecResult(
          error: '预置能力加载失败: $err',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 用 load() 把 chunk 加载成函数再取出结果。
      // 不能写成 `__studio_fn = return function...`——
      // Lua 里 return 不是表达式，不能出现在赋值右侧。
      // chunk 通过 [=[ ]=] 包裹，避免内容里的引号/括号干扰。
      //
      // 执行保护通过 **chunk 内的 __studio_invoke 间接层** 实现，
      // 不在 Dart 侧重新包装 __studio_fn——见下面那段 Lua。
      final chunkStatus = lua.doString(
        'local f, err = load([==[$chunk]==], "editor")\n'
        'if not f then error(err) end\n'
        '__studio_fn = f()',
      );

      // 用户代码的语法/运行错误：日志也要取到
      if (!chunkStatus.isOk) {
        final err = _takeError(lua);
        final logs = _decodeLogs(_takeLogs(lua));
        return ExecResult(
          error: err,
          logs: logs,
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      lua.getGlobal('__studio_fn');
      if (!lua.isFunction(-1)) {
        final t = lua.typeNameAt(-1) ?? '?';
        lua.setTop(0);
        return ExecResult(
          error: '代码必须返回函数。\n'
              '写法：return function() ... end\n'
              '当前返回的是 $t',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }
      lua.setTop(0);

      // 装执行保护。必须在 __studio_fn 就位之后、调用之前。
      if (budgetMs > 0) {
        final guardStatus = lua.doString(studioGuardSetup);
        if (!guardStatus.isOk) {
          final err = _takeError(lua);
          return ExecResult(
            error: '无法启用执行保护：$err',
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
      }

      // 取回被包装的函数并调用
      lua.getGlobal('__studio_fn');
      final status = _call(lua, 1);

      if (!status.isOk) {
        // 出错时栈顶是错误信息。日志要在清栈前取，否则错误也丢了。
        final err = _takeError(lua);
        final logs = _decodeLogs(_takeLogs(lua));
        return ExecResult(
          error: err,
          logs: logs,
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 栈顶是返回值——必须先读出来。
      // _takeLogs 内部会做 setTop(0) 清栈，顺序反了结果就没了。
      final String? result;
      if (lua.isNil(-1) || lua.isNone(-1)) {
        result = null;
      } else if (lua.isString(-1)) {
        // 注意：Lua 里 lua_isstring 对数字也返回 true（数字可转字符串），
        // 所以还要排除 number，否则 return 123 会被当成合法结果。
        if (lua.isNumber(-1)) {
          final n = lua.toNumber(-1);
          lua.setTop(0);
          return ExecResult(
            error: '函数应返回字符串（显示列表的 JSON），实际返回数字 $n',
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
        result = lua.getString(-1);
      } else {
        final t = lua.typeNameAt(-1) ?? '?';
        lua.setTop(0);
        return ExecResult(
          error: '函数应返回字符串（显示列表的 JSON），实际返回 $t',
          logs: _decodeLogs(_takeLogs(lua)),
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 值已拷到 Dart 侧，现在可以安全清栈再取日志
      lua.setTop(0);
      final logs = _decodeLogs(_takeLogs(lua));

      return ExecResult(
        displayListJson: result,
        logs: logs,
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
        lua?.close();
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

    LuaState? lua;
    try {
      lua = newRestrictedState();

      lua.pushString(libraryPath);
      lua.setGlobal('__studio_libpath');

      if (!lua.doString(sandboxBootstrap).isOk) {
        return ExecResult(
          error: '引导脚本执行失败: ${_takeError(lua)}',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      if (!lua.doString(uiPrelude).isOk) {
        return ExecResult(
          error: '预置能力加载失败: ${_takeError(lua)}',
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      // 状态 / 事件参数走全局槽传入，不内联进源码。
      // 内联要用长括号包 JSON，而 JSON 里可能含 `]==]`；走全局就没有这个坑。
      if (stateJson != null && stateJson.isNotEmpty) {
        lua.pushString(stateJson);
        lua.setGlobal('__studio_state');
        // 必须真的调 ui.seed_state：`__studio_state` 只是中转站，
        // 模块读的是自己的 _STUDIO_UI_STATE。漏掉这一步的表现是
        // 「每次点按钮状态都回到初始值」，而界面看上去完全正常。
        final seed = lua.doString('ui.seed_state(__studio_state)');
        if (!seed.isOk) {
          return ExecResult(
            error: '状态注入失败：${_takeError(lua)}',
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
      }
      if (eventName != null) {
        lua.pushString(eventName);
        lua.setGlobal('__studio_event');
        lua.pushString(eventArgsJson ?? '');
        lua.setGlobal('__studio_event_args');
      }

      if (budgetMs > 0) {
        lua.doString('__studio_budget = $budgetMs');
      }

      // 加载成函数（而不是直接 doString），这样执行保护能装在调用之前。
      //
      // chunk 内容用 [==[ ]==] 包裹，避免用户代码里的引号/括号干扰 Lua 语法。
      final chunk = userCode;
      final loadStatus = lua.doString(
        'local f, err = load([==[$chunk]==], "ui-editor")\n'
        'if not f then error(err) end\n'
        '__studio_fn = f',
      );
      if (!loadStatus.isOk) {
        final err = _takeError(lua);
        return ExecResult(
          error: err,
          logs: _decodeLogs(_takeLogs(lua)),
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      if (budgetMs > 0) {
        final guardStatus = lua.doString(
          '__studio_fn = ui.wrap(__studio_fn, __studio_budget)',
        );
        if (!guardStatus.isOk) {
          final err = _takeError(lua);
          return ExecResult(
            error: '无法启用执行保护：$err',
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
      }

      // 先跑用户 chunk（注册 app 并产出初始信封）。
      lua.getGlobal('__studio_fn');
      final status = _call(lua, 1);
      if (!status.isOk) {
        final err = _takeError(lua);
        return ExecResult(
          error: err,
          logs: _decodeLogs(_takeLogs(lua)),
          elapsedMicros: sw.elapsedMicroseconds,
        );
      }

      String? envelope;
      if (eventName == null) {
        // 构建阶段：chunk 的返回值就是契约信封。
        final bad = _rejectNonString(lua);
        if (bad != null) {
          return ExecResult(
            error: bad,
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
        envelope = lua.getString(-1);
      }

      lua.setTop(0);

      if (eventName != null) {
        // 事件阶段：以 dispatch 的结果为准，chunk 的返回值只是中间产物。
        final dispatch = lua.doString(
          'return ui.dispatch(__studio_event, __studio_event_args)',
        );
        if (!dispatch.isOk) {
          final err = _takeError(lua);
          return ExecResult(
            error: err,
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
        final bad = _rejectNonString(lua);
        if (bad != null) {
          return ExecResult(
            error: bad,
            logs: _decodeLogs(_takeLogs(lua)),
            elapsedMicros: sw.elapsedMicroseconds,
          );
        }
        envelope = lua.getString(-1);
      }

      // 值已拷到 Dart 侧，现在可以安全清栈再取日志
      lua.setTop(0);
      return ExecResult(
        uiTreeJson: envelope,
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
        lua?.close();
      } catch (_) {
        // 关不掉也不能让应用崩
      }
      _busy = false;
      sw.stop();
    }
  }

  /// 调用 __studio_take_logs 取回日志。
  ///
  /// 只清理自己压栈的那个元素，不做 setTop(0)——
  /// 清整个栈会连带丢掉调用方还没读的返回值或错误信息。
  String? _takeLogs(LuaState lua) {
    final base = lua.getTop;

    lua.getGlobal('__studio_take_logs');
    if (!lua.isFunction(-1)) {
      lua.setTop(base);
      return null;
    }

    final st = _call(lua, 1);
    if (!st.isOk) {
      lua.setTop(base);
      return null;
    }

    final v = lua.getString(-1);
    lua.setTop(base);
    return v;
  }

  /// 读栈顶错误信息并清栈。
  String _takeError(LuaState lua) {
    final s = lua.getString(-1);
    lua.setTop(0);
    return s ?? '(未知错误)';
  }

  /// 检查栈顶是不是字符串。是则返回 null，否则返回一条可直接展示的错误。
  ///
  /// 不动栈——由调用方决定是清栈还是继续读。
  String? _rejectNonString(LuaState lua) {
    if (lua.isNil(-1) || lua.isNone(-1)) {
      return '代码必须返回 UI 契约的 JSON 字符串，实际返回 nil。\n'
          '写法：return json.encode(app:build())';
    }
    if (lua.isString(-1)) {
      // lua_isstring 对数字也返回 true（数字可转字符串），要再排除 number。
      if (lua.isNumber(-1)) {
        final n = lua.toNumber(-1);
        return '代码必须返回 JSON 字符串，实际返回数字 $n';
      }
      return null;
    }
    final t = lua.typeNameAt(-1) ?? '?';
    return '代码必须返回 JSON 字符串，实际返回 $t';
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

@pragma('vm:entry-point')
int _openBase(ffi.Pointer<flb.lua_State> L) => flb.luaopen_base(L);

@pragma('vm:entry-point')
int _openPackage(ffi.Pointer<flb.lua_State> L) => flb.luaopen_package(L);

@pragma('vm:entry-point')
int _openCoroutine(ffi.Pointer<flb.lua_State> L) => flb.luaopen_coroutine(L);

@pragma('vm:entry-point')
int _openTable(ffi.Pointer<flb.lua_State> L) => flb.luaopen_table(L);

@pragma('vm:entry-point')
int _openIo(ffi.Pointer<flb.lua_State> L) => flb.luaopen_io(L);

@pragma('vm:entry-point')
int _openOs(ffi.Pointer<flb.lua_State> L) => flb.luaopen_os(L);

@pragma('vm:entry-point')
int _openString(ffi.Pointer<flb.lua_State> L) => flb.luaopen_string(L);

@pragma('vm:entry-point')
int _openMath(ffi.Pointer<flb.lua_State> L) => flb.luaopen_math(L);

@pragma('vm:entry-point')
int _openUtf8(ffi.Pointer<flb.lua_State> L) => flb.luaopen_utf8(L);

@pragma('vm:entry-point')
int _openDebug(ffi.Pointer<flb.lua_State> L) => flb.luaopen_debug(L);

final class _LuaLibrary {
  const _LuaLibrary(this.mask, this.name, this.open);

  final int mask;
  final String name;
  final flb.lua_CFunction open;
}

final flb.lua_CFunction _openBaseCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openBase, 0);
final flb.lua_CFunction _openPackageCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openPackage, 0);
final flb.lua_CFunction _openCoroutineCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openCoroutine, 0);
final flb.lua_CFunction _openTableCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openTable, 0);
final flb.lua_CFunction _openIoCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openIo, 0);
final flb.lua_CFunction _openOsCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openOs, 0);
final flb.lua_CFunction _openStringCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openString, 0);
final flb.lua_CFunction _openMathCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openMath, 0);
final flb.lua_CFunction _openUtf8Callback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openUtf8, 0);
final flb.lua_CFunction _openDebugCallback =
    ffi.Pointer.fromFunction<flb.lua_CFunctionFunction>(_openDebug, 0);

final List<_LuaLibrary> _luaLibraries = <_LuaLibrary>[
  _LuaLibrary(kLuaLibGlb, '_G', _openBaseCallback),
  _LuaLibrary(kLuaLibLoadlib, 'package', _openPackageCallback),
  _LuaLibrary(kLuaLibColib, 'coroutine', _openCoroutineCallback),
  _LuaLibrary(kLuaLibTablib, 'table', _openTableCallback),
  _LuaLibrary(kLuaLibIolib, 'io', _openIoCallback),
  _LuaLibrary(kLuaLibOslib, 'os', _openOsCallback),
  _LuaLibrary(kLuaLibStrlib, 'string', _openStringCallback),
  _LuaLibrary(kLuaLibMathlib, 'math', _openMathCallback),
  _LuaLibrary(kLuaLibUtf8lib, 'utf8', _openUtf8Callback),
  _LuaLibrary(kLuaLibDblib, 'debug', _openDebugCallback),
];

/// 按掩码调用 Lua 5.4 的标准库入口。当前 runtime 包只暴露
/// `luaL_openlibs`，所以这里用 `luaL_requiref` 复现 Lua 官方初始化表，
/// 同时保留按能力声明选择库的行为。
void _openSelected(LuaState lua, int mask) {
  pkg_ffi.using((arena) {
    for (final lib in _luaLibraries) {
      if (mask & lib.mask == 0) continue;
      final name = lib.name.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      FlutterLuaBridge.auxApi.luaL_requiref(
        lua.rawState,
        name,
        lib.open,
        1,
      );
      lua.pop(1);
    }
  });
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
LuaState newRestrictedState({
  void Function(int mask, List<String> libs)? onMask,
}) {
  final mask = _declaredLibMask();
  final libs = onMask != null ? _declaredLibNames() : _cachedLibNames;

  final lua = LuaState.newState();
  _openSelected(lua, mask);
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
  final probe = LuaState.newState()..openLibs();
  final mask = _readDeclaredMask(probe);
  _closeQuietly(probe);
  return mask ?? kFullLibMask;
}

List<String> _probeDeclaredLibNames() {
  final probe = LuaState.newState()..openLibs();
  final names = _readDeclaredLibs(probe);
  _closeQuietly(probe);
  return names;
}

void _closeQuietly(LuaState lua) {
  try {
    lua.close();
  } catch (_) {
    // 关不掉也不该让整次执行失败
  }
}

/// 读 Lua 侧汇总的库掩码。读失败返回 null（调用方决定回退）。
int? _readDeclaredMask(LuaState lua) {
  final r = lua.doString(
    'local ok, perf = pcall(require, "perf")\n'
    'if not ok then return nil end\n'
    'return perf.lib_mask()',
  );
  if (!r.isOk) {
    _discardTop(lua);
    return null;
  }
  if (lua.isNil(-1) || lua.isNone(-1)) {
    _discardTop(lua);
    return null;
  }
  final mask = lua.toNumber(-1).toInt();
  _discardTop(lua);
  return mask <= 0 ? null : mask;
}

/// 读库名列表，只用于诊断输出。
List<String> _readDeclaredLibs(LuaState lua) {
  final r = lua.doString(
    'local ok, perf = pcall(require, "perf")\n'
    'if not ok then return "" end\n'
    'local _, names = perf.lib_mask()\n'
    'return table.concat(names, ",")',
  );
  if (!r.isOk) {
    _discardTop(lua);
    return const [];
  }
  final raw = lua.getString(-1) ?? '';
  _discardTop(lua);
  if (raw.isEmpty) return const [];
  return raw.split(',');
}

void _discardTop(LuaState lua) {
  try {
    lua.setTop(0);
  } catch (_) {
    // 栈已经不可信也不要因此让整次执行失败
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
  -- 每次执行都重建 LuaState，所以"找文件 + 解析源码"是**每次都要付**的：
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
