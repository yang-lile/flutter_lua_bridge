/// Why a Lua operation failed.
enum LuaStatus {
  /// An error raised by Lua code.
  runtime,

  /// The chunk could not be compiled.
  syntax,

  /// The memory limit was reached or the system ran out of memory.
  memory,

  /// An error was raised while handling another error.
  handler,

  /// The operation was given a value it cannot use.
  argument,

  /// The run was stopped with `LuaRuntime.interrupt`.
  interrupted,

  /// A Dart function called from Lua threw; see [LuaBridgeException.cause].
  host,

  /// The failure was detected by the Dart side of the bridge.
  bridge,
}

/// A script, module binding or host callback failure.
class LuaBridgeException implements Exception {
  LuaBridgeException(
    this.message, {
    this.status = LuaStatus.bridge,
    this.traceback = '',
    this.cause,
    this.causeStackTrace,
  });

  /// The error message, without the traceback.
  final String message;
  final LuaStatus status;

  /// The Lua traceback, empty when Lua code was not running.
  final String traceback;

  /// The Dart error thrown by a host function, when [status] is
  /// [LuaStatus.host].
  final Object? cause;
  final StackTrace? causeStackTrace;

  @override
  String toString() => traceback.isEmpty || traceback.startsWith(message)
      ? 'LuaBridgeException: ${traceback.isEmpty ? message : traceback}'
      : 'LuaBridgeException: $message\n$traceback';
}

/// A value does not satisfy the generated interface contract.
class LuaTypeException extends LuaBridgeException {
  LuaTypeException(String path, String expected, Object? actual)
    : super('$path: expected $expected, got ${actual.runtimeType} ($actual)');
}

/// The result envelope returned by generated O1/O2 Lua bindings.
enum LuaResultStatus { ok, error }

enum LuaErrorKind { type, runtime, protocol }

sealed class LuaCallResult<T> {
  const LuaCallResult(this.status);

  final LuaResultStatus status;
  bool get isOk => status == LuaResultStatus.ok;
  bool get isError => status == LuaResultStatus.error;
}

final class LuaSuccess<T> extends LuaCallResult<T> {
  const LuaSuccess(this.value) : super(LuaResultStatus.ok);

  final T value;
}

final class LuaFailure<T> extends LuaCallResult<T> {
  const LuaFailure({required this.kind, required this.message})
    : super(LuaResultStatus.error);

  final LuaErrorKind kind;
  final String message;
}
