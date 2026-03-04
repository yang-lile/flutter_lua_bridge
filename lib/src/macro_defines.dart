// ignore_for_file: non_constant_identifier_names
///
/// @Deprecated('使用 lib/src/core/lua_constants.dart 中的常量')
///
/// 此文件保留用于向后兼容。
/// 建议使用新的 API：
/// - LuaState 类（面向对象封装）
/// - lua_constants.dart（常量定义）

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'gen/flutter_lua_bridge.g.dart';

/// @Deprecated('使用 lua_constants.dart 中的常量')
const int LUA_MULTRET = -1;

/// @Deprecated('使用 lua_constants.dart 中的常量')
const int LUA_NOREF = -2;

/// @Deprecated('使用 lua_constants.dart 中的常量')
const int LUA_REFNIL = -1;

@Deprecated('使用 LuaState.doString() 或 LuaStateX.doString 扩展')
int luaL_dostring(Pointer<lua_State> L, Pointer<Char> s) =>
    luaL_loadstring(L, s) | lua_pcall(L, 0, LUA_MULTRET, 0);

@Deprecated('使用 LuaState.call()')
int lua_pcall(Pointer<lua_State> L, int nargs, int nresults, int errfunc) =>
    lua_pcallk(L, nargs, nresults, errfunc, 0, nullptr);

@Deprecated('使用 LuaStateX.toLuaString 扩展')
String lua_tostring(Pointer<lua_State> L, int idx) =>
    lua_tolstring(L, idx, nullptr).cast<Utf8>().toDartString();

@Deprecated('使用 LuaStateX.pop 扩展')
void lua_pop(Pointer<lua_State> L, int n) => lua_settop(L, -n - 1);

@Deprecated('使用 lua_pushcclosure')
void lua_pushcfunction(Pointer<lua_State> L, lua_CFunction fn) =>
    lua_pushcclosure(L, fn, 0);
