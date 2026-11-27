import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';

import 'errors.dart';
import 'flb.g.dart';
import 'runtime.dart';

/// Prepares the runtime of a [LuaWorker] inside the worker isolate: loads
/// modules, registers Dart functions. It must be sendable to another isolate,
/// for example a top-level or static function.
typedef LuaWorkerSetup = FutureOr<void> Function(LuaRuntime runtime);

/// A [LuaRuntime] on a background isolate, so that Lua work does not block
/// the calling isolate and running code can be stopped from outside.
///
/// The worker runs one call at a time, in the order of the calls; the others
/// wait. Arguments and results are plain data: `null`, `bool`, `int`,
/// `double`, `String`, `Uint8List`, and `List` / `Map` of those. A Lua table
/// result arrives as a `List` (keys exactly `1..n`) or a `Map`; a function,
/// coroutine or userdata cannot leave the worker and fails the call.
///
/// A failure arrives as the [LuaBridgeException] the call threw in the worker.
/// Its [LuaBridgeException.cause] is then the `toString()` of the Dart error.
///
/// ```dart
/// final worker = await LuaWorker.spawn(setup: loadRules);
/// try {
///   final score = await worker.call(
///     'rules.score',
///     [board],
///     timeout: const Duration(milliseconds: 200),
///   );
/// } on LuaBridgeException catch (e) {
///   // e.status == LuaStatus.interrupted when the timeout stopped it.
/// } finally {
///   await worker.close();
/// }
/// ```
class LuaWorker {
  LuaWorker._(this._requests, this._state, this._token, this._ports);

  /// Starts an isolate with a new runtime and runs [setup] on it there.
  /// [libraries] and [memoryLimit] are as in [LuaRuntime.create]. Fails with
  /// the error of [setup], as a [LuaBridgeException].
  static Future<LuaWorker> spawn({
    LuaWorkerSetup? setup,
    int libraries = LuaLibrary.safe,
    int memoryLimit = 0,
    String debugName = 'LuaWorker',
  }) async {
    final ports = _Ports();
    final ready = Completer<LuaWorker>();
    LuaWorker? worker;
    ports.replies.handler = (Object? message) {
      final current = worker;
      if (current != null) {
        current._reply(message! as List<Object?>);
      } else if (message case [
        'ready',
        final SendPort requests,
        final int state,
        final int token,
      ]) {
        final created = worker = LuaWorker._(requests, state, token, ports);
        ready.complete(created);
      } else if (message case [
        'failed',
        final String error,
        final String stack,
      ]) {
        ports.close();
        ready.completeError(
          LuaBridgeException('LuaWorker setup failed: $error'),
          StackTrace.fromString(stack),
        );
      }
    };
    ports.exit.handler = (_) {
      final current = worker;
      if (current != null) {
        current._exited();
      } else if (!ready.isCompleted) {
        ports.close();
        ready.completeError(
          LuaBridgeException('LuaWorker exited during setup'),
        );
      }
    };
    try {
      await Isolate.spawn(
        _workerMain,
        _Start(ports.replies.sendPort, setup, libraries, memoryLimit),
        onExit: ports.exit.sendPort,
        debugName: debugName,
      );
    } catch (_) {
      ports.close();
      rethrow;
    }
    return ready.future;
  }

  final SendPort _requests;
  final int _state;
  final int _token;
  final _Ports _ports;
  final _queue = Queue<_Request>();
  _Request? _running;
  int _nextId = 0;
  bool _closing = false;
  bool _gone = false;
  final _exit = Completer<void>();

  /// Whether [close] was called or the worker isolate ended.
  bool get isClosed => _closing || _gone;

  /// Runs a text chunk and returns everything it returns. With [timeout] the
  /// chunk is interrupted once it has run that long, and the call fails with
  /// [LuaStatus.interrupted].
  Future<List<Object?>> run(String code, {String? name, Duration? timeout}) =>
      _submit(['run', code, name], timeout);

  /// Calls the global function [function] (a dotted path such as
  /// `"rules.score"` looks it up in nested tables) and returns everything it
  /// returns. [timeout] is as in [run].
  Future<List<Object?>> call(
    String function,
    List<Object?> arguments, {
    Duration? timeout,
  }) => _submit(['call', function, arguments], timeout);

  /// Stops the Lua code of the call that is running now, if any; it fails
  /// with [LuaStatus.interrupted]. Waiting calls are not affected.
  ///
  /// Lua checks for the interruption every 1000 VM instructions, so a Dart
  /// function that Lua called is not stopped until it returns.
  void interrupt() {
    final running = _running;
    if (running != null && !_gone) _stop(running);
  }

  /// Interrupts the running call, fails the waiting ones with a
  /// [StateError], closes the runtime and ends the isolate. Idempotent.
  Future<void> close() {
    if (!_closing && !_gone) {
      _closing = true;
      final running = _running;
      if (running != null) _stop(running);
      final error = StateError('The LuaWorker is closed');
      while (_queue.isNotEmpty) {
        _queue.removeFirst().completer.completeError(error);
      }
      _requests.send(const [0, 'close']);
    }
    return _exit.future;
  }

  void _interrupt() {
    if (!_tokenReleased) flb_interrupt(Pointer.fromAddress(_state));
  }

  /// Interrupts [item] and repeats it until its reply arrives: a call clears
  /// an interruption that lands before it starts, which would otherwise let
  /// a call that was stopped early run unbounded.
  void _stop(_Request item) {
    _interrupt();
    item.repeat ??= Timer.periodic(const Duration(milliseconds: 5), (_) {
      if (identical(_running, item)) _interrupt();
    });
  }

  bool _tokenReleased = false;

  void _releaseToken() {
    if (_tokenReleased) return;
    _tokenReleased = true;
    flb_token_release(Pointer.fromAddress(_token));
  }

  Future<List<Object?>> _submit(List<Object?> request, Duration? timeout) {
    if (isClosed) {
      return Future.error(StateError('The LuaWorker is closed'));
    }
    final item = _Request(++_nextId, request, timeout);
    _queue.add(item);
    _next();
    return item.completer.future;
  }

  void _next() {
    if (_running != null || _queue.isEmpty || isClosed) return;
    final item = _running = _queue.removeFirst();
    _requests.send([item.id, ...item.message]);
    final timeout = item.timeout;
    if (timeout != null) {
      item.timer = Timer(timeout, () {
        if (identical(_running, item)) {
          item.timedOut = true;
          _stop(item);
        }
      });
    }
  }

  void _reply(List<Object?> message) {
    final item = _running;
    if (item == null || message[0] != item.id) return;
    _running = null;
    item.cancelTimers();
    if (message case [_, true, final List<Object?> values]) {
      item.completer.complete(values);
    } else if (message case [
      _,
      false,
      final String text,
      final int status,
      final String traceback,
      final String? cause,
      final String? causeStack,
    ]) {
      final interrupted = status == LuaStatus.interrupted.index;
      item.completer.completeError(
        LuaBridgeException(
          interrupted && item.timedOut
              ? 'timed out after ${item.timeout}'
              : text,
          status: LuaStatus.values[status],
          traceback: traceback,
          cause: cause,
          causeStackTrace: causeStack == null
              ? null
              : StackTrace.fromString(causeStack),
        ),
      );
    }
    _next();
  }

  void _exited() {
    _gone = true;
    _releaseToken();
    _ports.close();
    final error = _closing
        ? StateError('The LuaWorker is closed')
        : LuaBridgeException('The LuaWorker isolate exited');
    final running = _running;
    _running = null;
    running?.cancelTimers();
    if (running != null) running.completer.completeError(error);
    while (_queue.isNotEmpty) {
      _queue.removeFirst().completer.completeError(error);
    }
    if (!_exit.isCompleted) _exit.complete();
  }
}

class _Ports {
  final replies = RawReceivePort(null, 'LuaWorker replies');
  final exit = RawReceivePort(null, 'LuaWorker exit');

  void close() {
    replies.close();
    exit.close();
  }
}

class _Request {
  _Request(this.id, this.message, this.timeout);
  final int id;
  final List<Object?> message;
  final Duration? timeout;
  final completer = Completer<List<Object?>>();
  Timer? timer;
  Timer? repeat;
  bool timedOut = false;

  void cancelTimers() {
    timer?.cancel();
    repeat?.cancel();
  }
}

class _Start {
  _Start(this.replies, this.setup, this.libraries, this.memoryLimit);
  final SendPort replies;
  final LuaWorkerSetup? setup;
  final int libraries;
  final int memoryLimit;
}

// ---- Worker isolate --------------------------------------------------------

Future<void> _workerMain(_Start start) async {
  final LuaRuntime runtime;
  try {
    runtime = LuaRuntime.create(
      libraries: start.libraries,
      memoryLimit: start.memoryLimit,
    );
  } catch (error, stack) {
    start.replies.send(['failed', '$error', '$stack']);
    return;
  }
  final ({int state, int token}) handle;
  try {
    await start.setup?.call(runtime);
    handle = luaInterruptHandle(runtime);
  } catch (error, stack) {
    runtime.close();
    start.replies.send(['failed', '$error', '$stack']);
    return;
  }
  final requests = RawReceivePort(null, 'LuaWorker requests');
  requests.handler = (Object? message) {
    final [id, operation, ...arguments] = message! as List<Object?>;
    if (operation == 'close') {
      requests.close();
      runtime.close();
      return;
    }
    start.replies.send([id, ..._execute(runtime, operation, arguments)]);
  };
  start.replies.send(['ready', requests.sendPort, handle.state, handle.token]);
}

List<Object?> _execute(
  LuaRuntime runtime,
  Object? operation,
  List<Object?> arguments,
) {
  try {
    final results = switch (operation) {
      'run' => runtime.run(
        arguments[0]! as String,
        name: arguments[1] as String?,
      ),
      'call' => _call(
        runtime,
        arguments[0]! as String,
        arguments[1]! as List<Object?>,
      ),
      _ => throw StateError('Unknown LuaWorker request $operation'),
    };
    return [true, _sendable(results)];
  } on LuaBridgeException catch (error) {
    return [
      false,
      error.message,
      error.status.index,
      error.traceback,
      error.cause?.toString(),
      error.causeStackTrace?.toString(),
    ];
  } catch (error) {
    return [false, '$error', LuaStatus.bridge.index, '', null, null];
  }
}

List<Object?> _call(LuaRuntime runtime, String path, List<Object?> arguments) {
  final parts = path.split('.');
  var value = runtime[parts.first];
  for (final part in parts.skip(1)) {
    if (value is! LuaTable) {
      _releaseAll([value]);
      throw LuaBridgeException('$path is not a function');
    }
    final next = value[part];
    value.release();
    value = next;
  }
  if (value is! LuaFunction) {
    _releaseAll([value]);
    throw LuaBridgeException('$path is not a function');
  }
  try {
    return value.call(arguments);
  } finally {
    value.release();
  }
}

List<Object?> _sendable(List<Object?> results) {
  try {
    return [
      for (final value in results)
        switch (value) {
          LuaTable() => value.toDart(),
          LuaRef() => throw LuaBridgeException(
            'A ${value.runtimeType} cannot leave the LuaWorker; '
            'return plain data',
          ),
          _ => value,
        },
    ];
  } finally {
    _releaseAll(results);
  }
}

void _releaseAll(List<Object?> values) {
  for (final value in values) {
    if (value is LuaRef) value.release();
  }
}
