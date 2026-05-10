/// Lua C API 值转换
///
/// 此文件包含 Lua C API 中所有值转换相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 转换为布尔值
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示 true，0 表示 false
int luaToboolean(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_toboolean(L, idx);
}

/// 转换为 C 函数
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 C 函数指针
LuaCFunction luaTocfunction(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_tocfunction(L, idx);
}

/// 转换为整数
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回整数值
LuaInteger luaTointeger(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_tointeger(L, idx);
}

/// 转换为整数（带状态）
///
/// [L] - Lua 状态
/// [idx] - 索引
/// [isnum] - 输出参数，是否为数字
/// 返回整数值
LuaInteger luaTointegerx(
  ffi.Pointer<gen.lua_State> L,
  int idx,
  ffi.Pointer<ffi.Int> isnum,
) {
  return gen.flutter_lua_bridge_tointegerx(L, idx, isnum);
}

/// 转换为字符串
///
/// [L] - Lua 状态
/// [idx] - 索引
/// [len] - 输出参数，字符串长度
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaTolstring(
  ffi.Pointer<gen.lua_State> L,
  int idx,
  ffi.Pointer<ffi.Size> len,
) {
  return gen.flutter_lua_bridge_tolstring(L, idx, len);
}

/// 转换为数字
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回数字值
LuaNumber luaTonumber(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_tonumber(L, idx);
}

/// 转换为数字（带状态）
///
/// [L] - Lua 状态
/// [idx] - 索引
/// [isnum] - 输出参数，是否为数字
/// 返回数字值
LuaNumber luaTonumberx(
  ffi.Pointer<gen.lua_State> L,
  int idx,
  ffi.Pointer<ffi.Int> isnum,
) {
  return gen.flutter_lua_bridge_tonumberx(L, idx, isnum);
}

/// 转换为指针
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回值对应的指针
ffi.Pointer<ffi.Void> luaTopointer(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_topointer(L, idx);
}

/// 转换为字符串
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaTostring(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_tostring(L, idx);
}

/// 转换为线程
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回线程状态指针
ffi.Pointer<gen.lua_State> luaTothread(
  ffi.Pointer<gen.lua_State> L,
  int idx,
) {
  return gen.flutter_lua_bridge_tothread(L, idx);
}

/// 转换为用户数据
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回用户数据指针
ffi.Pointer<ffi.Void> luaTouserdata(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_touserdata(L, idx);
}

/// 获取类型
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回类型代码
int luaType(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_type(L, idx);
}

/// 获取类型名称
///
/// [L] - Lua 状态
/// [tp] - 类型代码
/// 返回类型名称
ffi.Pointer<ffi.Char> luaTypename(ffi.Pointer<gen.lua_State> L, int tp) {
  return gen.flutter_lua_bridge_typename(L, tp);
}
