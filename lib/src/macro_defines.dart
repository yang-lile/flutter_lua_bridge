/// 此文件保留用于向后兼容。
/// 建议使用新的 API：
/// - LuaState 类（面向对象封装）
/// - lua_constants.dart（常量定义）
// ignore_for_file: non_constant_identifier_names

library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'gen/flutter_lua_bridge.g.dart';

int luaL_dostring(Pointer<lua_State> L, Pointer<Char> s) => luaL_loadstring(L, s) | lua_pcall(L, 0, LUA_MULTRET, 0);

int lua_pcall(Pointer<lua_State> L, int nargs, int nresults, int errfunc) =>
    lua_pcallk(L, nargs, nresults, errfunc, 0, nullptr);

String lua_tostring(Pointer<lua_State> L, int idx) => lua_tolstring(L, idx, nullptr).cast<Utf8>().toDartString();

void lua_pop(Pointer<lua_State> L, int n) => lua_settop(L, -n - 1);

void lua_pushcfunction(Pointer<lua_State> L, lua_CFunction fn) => lua_pushcclosure(L, fn, 0);

void luaL_openlibs(Pointer<lua_State> L) => luaL_openselectedlibs(L, ~0, 0);
