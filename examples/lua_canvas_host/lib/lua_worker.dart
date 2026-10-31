// lib/lua_worker.dart
//
// 在独立 isolate 里执行 Lua。
//
// ## 为什么必须有这一层
//
// Lua 通过 FFI 调用是**同步阻塞**的：调用返回前，当前 isolate 的事件循环
// 完全停摆。这带来两个必然结果：
//
// 1. 执行期间 Timer 无法触发——包括防抖自动运行本身。
//    用户写个 `while true do end`，窗口就永久冻结，没有任何手段能救。
// 2. 执行期间 UI 无法响应（重绘、输入、动画全部停住）。
//
// 实测（20 万图元的绘制）单次执行要 1105ms，这段时间界面是完全僵的。
//
// 所以 Lua 必须跑在**另一个 isolate** 里。主 isolate 只负责发请求和收结果，
// 即使 worker 卡死，主 isolate 依然能响应用户操作，还能按超时把它丢弃掉。
//
// ## 性能
//
// 常驻 worker 而不是每次 spawn——后者每次都要重新绑定 FFI 符号（约 685ms）。
// 实测：worker 就绪 8ms，首轮 685ms，之后每轮 1–2ms。
//
// ## 注意
//
// - worker 入口必须是**顶层函数**。用闭包会让 isolate 迟迟不 check in。
// - worker 内**不要写 stderr/stdout**。`IOSink` 在子 isolate 里会抛异常，
//   把正在跑的 Lua 打断。

import 'dart:async';
import 'dart:isolate';

import 'lua_modules.dart';
import 'sandbox.dart';

/// 一次执行的结果（含超时与被取代两种宿主侧状态）。
class WorkerResult {
  const WorkerResult({
    this.displayListJson,
    this.uiTreeJson,
    this.logs = const [],
    this.error,
    this.elapsedMicros = 0,
  });

  /// 显示列表 JSON。
  final String? displayListJson;

  /// UI 契约信封 JSON。[runUi] 成功时非空。
  final String? uiTreeJson;

  /// print 的输出。
  final List<String> logs;

  /// 错误信息。成功时为 null。
  final String? error;

  /// Lua 侧耗时（微秒）。超时场景下没有意义。
  final int elapsedMicros;

  bool get ok => error == null;
}

/// 在独立 isolate 中执行 Lua 的常驻 worker。
class LuaWorker {
  LuaWorker({
    this.timeout = const Duration(seconds: 4),
    this.budgetMs = 1500,
  });

  /// 宿主侧兜底超时。
  ///
  /// 比 [budgetMs] 大：正常情况下 Lua 的 guard 会先中断，
  /// 这个只是最后一道防线（guard 失效时，比如 debug 库被裁掉）。
  final Duration timeout;

  /// 传给 Lua 的 canvas_guard 时间预算（毫秒）。
  final int budgetMs;

  String _libraryPath = '';
  bool _ready = false;
  bool _disposed = false;

  Isolate? _iso;
  SendPort? _commands;
  ReceivePort? _results;

  /// VM 用来报告崩溃与退出的端口。必须独立于 [_results]，
  /// 否则 worker 被 kill 后 VM 收不到消息，进程无法退出。
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;

  int _seq = 0;

  bool _precompiled = false;

  /// 请求 id -> 等待中的 Completer。
  final _pending = <int, Completer<WorkerResult>>{};

  /// 是否有请求在飞。用于实现"新编辑取代旧执行"。
  bool get busy => _pending.isNotEmpty;

  bool get ready => _ready;

  /// 启动 worker。重复调用是安全的。
  ///
  /// [libraryPath] 是 Lua 模块落盘后的目录，会随每次请求一起传过去。
  Future<void> start(String libraryPath) async {
    if (_disposed) {
      throw StateError('worker 已释放');
    }
    _libraryPath = libraryPath;
    if (_ready) return;
    await _spawn();
  }

  /// 执行一段画布模式的用户代码。
  ///
  /// 超时或 worker 死亡时返回带 [error] 的结果，不会抛异常——
  /// 编辑器场景下任何失败都该显示在界面上，而不是让调用方处理异常。
  Future<WorkerResult> run(String code) {
    return _dispatch(code, null);
  }

  /// 执行一段 UI 模式的用户代码。
  ///
  /// [stateJson] 是上一轮的 UI 状态，[eventName] 非空时会顺便分发该事件。
  Future<WorkerResult> runUi(
    String code, {
    String? stateJson,
    String? eventName,
    String? eventArgsJson,
  }) {
    return _dispatch(code, (m) {
      m['ui'] = true;
      m['state'] = stateJson;
      m['event'] = eventName;
      m['eventArgs'] = eventArgsJson;
    });
  }

  Future<WorkerResult> _dispatch(
    String code,
    void Function(Map<String, dynamic>)? extra,
  ) async {
    if (_disposed) {
      return const WorkerResult(error: 'worker 已释放');
    }

    // 上一轮还在飞就作废它。
    //
    // 注意：只在 Dart 侧完成 Completer 是不够的——worker 是串行的，
    // 如果它正卡在死循环里，新请求进了队列永远等不到。
    // 所以这里要连 worker 一起重启，让新请求有干净的执行环境。
    // 实测：只清 Completer 会让后续所有请求一起超时。
    if (_pending.isNotEmpty) {
      await _discardWorker(reason: '(已被新的编辑取代)');
      if (_disposed) {
        return const WorkerResult(error: 'worker 已释放');
      }
    }

    if (!_ready) {
      // 还没就绪时也不静默丢弃——先把 worker 拉起来再跑，
      // 调用方（UI）会显示"正在启动"。
      try {
        await start(_libraryPath);
      } catch (e) {
        return WorkerResult(error: 'worker 启动失败：$e');
      }
    }

    final commands = _commands;
    if (commands == null) {
      return const WorkerResult(error: 'worker 未就绪');
    }

    final id = ++_seq;
    final completer = Completer<WorkerResult>();
    _pending[id] = completer;

    final message = <String, dynamic>{
      'id': id,
      'code': code,
      'path': _libraryPath,
      'budget': budgetMs,
    };
    if (extra != null) {
      extra(message);
    }
    commands.send(message);

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _pending.remove(id);
      // 超时的 worker 内部状态不可信（可能正卡在 C 代码里，
      // 也可能 Lua 的栈已经错乱），必须整个丢弃。
      // 不在这里重建——下一次 run() 会走未就绪分支，
      // 中间隔了一个事件循环，VM 才有机会回收旧 isolate 的资源。
      await _discardWorker();
      return WorkerResult(
        error: '执行超时（${timeout.inMilliseconds}ms），已终止。\n'
            '检查是否有死循环或超大循环。',
      );
    }
  }

  /// 释放 worker。
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _ready = false;
    for (final entry in _pending.entries.toList()) {
      _pending.remove(entry.key)?.complete(
        const WorkerResult(error: 'worker 已释放'),
      );
    }
    _iso?.kill(priority: Isolate.immediate);
    _results?.close();
    _errorPort?.close();
    _exitPort?.close();
    _iso = null;
    _results = null;
    _errorPort = null;
    _exitPort = null;
    _commands = null;
  }

  // ---------- 内部 ----------

  Future<void> _spawn() async {
    // 预编译字节码：只做一次，之后每次执行都省下重新解析源码的钱。
    // 在主 isolate 上做，不占用 worker 的首轮执行时间。
    if (!_precompiled) {
      _precompiled = true;
      precompileLuaModules(_libraryPath, listLuaModuleNames(_libraryPath));
    }

    final results = ReceivePort();
    final initPort = ReceivePort();

    // onError / onExit 必须用**独立的端口**，不能复用 results。
    //
    // 这两个端口由 VM 内部持有并等待消息：如果和 results 共用，
    // worker 被 kill 后 VM 仍在等待该端口，而结果端口一关就再也没人读，
    // 进程会卡在 "waiting for isolate to check in" 里无法退出。
    // 单独开端口并在丢弃时关闭，VM 才能正常完成回收。
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();

    final iso = await Isolate.spawn(
      _luaWorkerMain,
      [results.sendPort, initPort.sendPort, _libraryPath],
      debugName: 'lua-worker',
      errorsAreFatal: false,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    // 握手：worker 建立好命令端口后才算就绪。
    // 这一步实测 8ms，绝大部分开销在随后的第一次 FFI 调用里。
    final commands = await initPort.first as SendPort;
    initPort.close();

    _iso = iso;
    _commands = commands;
    _results = results;
    _errorPort = errorPort;
    _exitPort = exitPort;
    _ready = true;

    results.listen(_onMessage);

    // 崩溃时立刻置为未就绪，让下一次 run() 重建
    errorPort.listen((dynamic _) {
      _ready = false;
      _failAllPending(
        const WorkerResult(error: 'Lua worker 崩溃，已准备重启'),
      );
    });

    // 正常或异常退出都算结束
    exitPort.listen((dynamic _) {
      _ready = false;
    });
  }

  /// 处理 worker 回传的执行结果。
  ///
  /// 崩溃与退出通知不走这里——它们由 [_spawn] 里独立的端口处理，
  /// 因为 VM 会等这两个端口收消息，复用本端口会导致进程无法退出。
  void _onMessage(dynamic raw) {
    final m = raw as Map<dynamic, dynamic>;
    final id = m['id'];
    if (id is! int) return;

    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) return;

    completer.complete(WorkerResult(
      displayListJson: m['json'] as String?,
      uiTreeJson: m['uiJson'] as String?,
      logs: (m['logs'] as List?)?.cast<String>() ?? const [],
      error: m['err'] as String?,
      elapsedMicros: (m['us'] as int?) ?? 0,
    ));
  }

  /// 丢弃 worker。[respawn] 为真时立刻重建。
  ///
  /// 超时、崩溃、被新编辑取代后调用。[reason] 会传给所有在飞的请求。
  ///
  /// **不要在这里无条件重建。** 被 kill 的 isolate 占用的运行时资源
  /// 由 VM 异步回收，紧接着 spawn 新 isolate 会触发
  /// "waiting for isolate to check in" 的重试等待——实测会让进程无法退出。
  /// 需要立刻继续执行时，由 [run] 走"未就绪 -> start"这条路径重建，
  /// 中间天然隔了一个 await，回收能完成。
  Future<void> _discardWorker({
    String reason = 'worker 已重启',
    bool respawn = false,
  }) async {
    _ready = false;
    _failAllPending(WorkerResult(error: reason));

    _iso?.kill(priority: Isolate.immediate);
    _results?.close();
    _errorPort?.close();
    _exitPort?.close();
    _iso = null;
    _results = null;
    _errorPort = null;
    _exitPort = null;
    _commands = null;

    if (_disposed || !respawn) return;

    // 立刻拉起新的，让下一次编辑不必再等
    try {
      await _spawn();
    } catch (_) {
      // 重建失败也没关系——下一次 run() 会再试一次
    }
  }

  void _failAllPending(WorkerResult r) {
    for (final entry in _pending.entries.toList()) {
      _pending.remove(entry.key)?.complete(r);
    }
  }
}

/// worker 入口。**必须是顶层函数**，否则 isolate 无法正常启动。
///
/// 收 [_toMain, _init, libraryPath]，启动后把命令端口发回 _init。
void _luaWorkerMain(List<dynamic> args) {
  final toMain = args[0] as SendPort;
  final initPort = args[1] as SendPort;
  final libraryPath = args[2] as String;

  final fromMain = ReceivePort();
  final sandbox = LuaSandbox();

  fromMain.listen((dynamic raw) {
    final m = raw as Map<dynamic, dynamic>;
    final id = m['id'] as int;
    try {
      // budgetMs 让 Lua 侧用 guard 自我中断。
      // 这比宿主侧超时更根本：isolate.kill 打断不了 FFI 调用，
      // 只有 Lua 自己抛错才能让 worker 恢复干净。
      final isUi = m['ui'] == true;
      final r = isUi
          ? sandbox.runUi(
              m['code'] as String,
              libraryPath: (m['path'] as String?) ?? libraryPath,
              stateJson: m['state'] as String?,
              eventName: m['event'] as String?,
              eventArgsJson: m['eventArgs'] as String?,
              budgetMs: (m['budget'] as int?) ?? 0,
            )
          : sandbox.run(
              m['code'] as String,
              libraryPath: (m['path'] as String?) ?? libraryPath,
              budgetMs: (m['budget'] as int?) ?? 0,
            );
      toMain.send({
        'id': id,
        'err': r.error,
        'json': r.displayListJson,
        'uiJson': r.uiTreeJson,
        'logs': r.logs,
        'us': r.elapsedMicros,
      });
    } catch (e) {
      toMain.send({
        'id': id,
        'err': '沙箱异常：$e',
        'json': null,
        'uiJson': null,
        'logs': const <String>[],
        'us': 0,
      });
    }
  });

  initPort.send(fromMain.sendPort);
}
