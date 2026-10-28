/// Script, module binding or host callback failure, including a Lua traceback.
class LuaBridgeException implements Exception {
  LuaBridgeException(this.message);
  final String message;
  @override
  String toString() => 'LuaBridgeException: $message';
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
