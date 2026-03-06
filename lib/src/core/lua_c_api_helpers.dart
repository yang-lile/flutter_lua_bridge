// ignore_for_file: non_constant_identifier_names
///
/// Lua C API 辅助函数
///
/// 这些函数在 C 语言 Lua API 中是宏或内联函数，
/// 在 Dart 中需要手动实现。
///

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../gen/flutter_lua_bridge.g.dart';

/// lua_pop 宏: lua_settop(L, -(n)-1)
///
/// 从栈中弹出 n 个元素
void lua_pop(Pointer<lua_State> L, int n) => lua_settop(L, -n - 1);

/// lua_tostring 别名: lua_tolstring(L, idx, NULL)
///
/// 将栈中指定索引的值转换为 C 字符串指针
Pointer<Char> lua_tostring(Pointer<lua_State> L, int idx) =>
    lua_tolstring(L, idx, nullptr);

/// lua_pcall 别名: lua_pcallk(L, nargs, nresults, errfunc, 0, NULL)
///
/// 以保护模式调用 Lua 函数
int lua_pcall(Pointer<lua_State> L, int nargs, int nresults, int errfunc) =>
    lua_pcallk(L, nargs, nresults, errfunc, 0, nullptr);

/// luaL_dostring 宏: luaL_loadstring(L, s) || lua_pcall(L, 0, LUA_MULTRET, 0)
///
/// 加载并执行 Lua 代码字符串
int luaL_dostring(Pointer<lua_State> L, Pointer<Char> s) {
  final status = luaL_loadstring(L, s);
  if (status != 0) return status;
  return lua_pcall(L, 0, LUA_MULTRET, 0);
}
