import 'gen/flutter_lua_bridge.g.dart';

/// Extension type wrapping Lua status codes for type-safe checks.
extension type const LuaStatus._(int value) {
  static const ok = LuaStatus._(LUA_OK);
  static const yield = LuaStatus._(LUA_YIELD);
  static const errRun = LuaStatus._(LUA_ERRRUN);
  static const errSyntax = LuaStatus._(LUA_ERRSYNTAX);
  static const errMem = LuaStatus._(LUA_ERRMEM);
  static const errErr = LuaStatus._(LUA_ERRERR);

  /// Whether the status represents success ([LUA_OK]).
  bool get isOk => value == LUA_OK;

  /// Whether the status represents any kind of error.
  bool get isError => value != LUA_OK;
}

/// Shorthand to treat a raw Lua status [int] as a [LuaStatus].
extension LuaStatusExt on int {
  LuaStatus get asLuaStatus => LuaStatus._(this);
}
