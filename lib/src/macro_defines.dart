// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

extension FlutterLuaBridgeBindingsMacroDefines on FlutterLuaBridgeBindings {
  int luaL_dostring(Pointer<lua_State> L, Pointer<Char> s) =>
      luaL_loadstring(L, s) | lua_pcall(L, 0, LUA_MULTRET, 0);

  int lua_pcall(Pointer<lua_State> L, int nargs, int nresults, int errfunc) =>
      lua_pcallk(L, nargs, nresults, errfunc, 0, nullptr);

  String lua_tostring(Pointer<lua_State> L, int idx) =>
      lua_tolstring(L, idx, nullptr).toDartString();

  void lua_pop(Pointer<lua_State> L, int idx) => lua_settop(L, -idx - 1);

  void lua_pushcfunction(Pointer<lua_State> L, lua_CFunction fn) =>
      lua_pushcclosure(L, fn, 0);
}
