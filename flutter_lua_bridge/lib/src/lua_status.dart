import 'gen/flutter_lua_bridge.g.dart';

/// Extension type wrapping Lua status codes for type-safe checks.
extension type const LuaStatusCode(int value) {
  static const ok = LuaStatusCode(LUA_OK);
  static const yield = LuaStatusCode(LUA_YIELD);
  static const errRun = LuaStatusCode(LUA_ERRRUN);
  static const errSyntax = LuaStatusCode(LUA_ERRSYNTAX);
  static const errMem = LuaStatusCode(LUA_ERRMEM);
  static const errErr = LuaStatusCode(LUA_ERRERR);
  static const errFile = LuaStatusCode(LUA_ERRFILE);

  /// Whether the status represents success ([LUA_OK]).
  bool get isOk => value == LUA_OK;

  /// Whether the status represents a yield ([LUA_YIELD]).
  bool get isYield => value == LUA_YIELD;

  /// Whether the status represents any kind of error
  /// ([LUA_ERRRUN], [LUA_ERRSYNTAX], [LUA_ERRMEM], [LUA_ERRERR], [LUA_ERRFILE]).
  bool get isError => value >= LUA_ERRRUN;
}
