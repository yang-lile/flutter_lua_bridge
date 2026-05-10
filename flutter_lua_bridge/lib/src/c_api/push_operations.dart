/// Lua C API 压栈操作
///
/// 此文件包含 Lua C API 中所有压栈操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 压入布尔值
///
/// [L] - Lua 状态
/// [b] - 布尔值（非 0 为 true）
void luaPushboolean(ffi.Pointer<gen.lua_State> L, int b) {
  gen.flutter_lua_bridge_pushboolean(L, b);
}

/// 压入 C 闭包
///
/// [L] - Lua 状态
/// [fn] - C 函数指针
/// [n] - 上值数量
void luaPushcclosure(ffi.Pointer<gen.lua_State> L, LuaCFunction fn, int n) {
  gen.flutter_lua_bridge_pushcclosure(L, fn, n);
}

/// 压入 C 函数
///
/// [L] - Lua 状态
/// [f] - C 函数指针
void luaPushcfunction(ffi.Pointer<gen.lua_State> L, LuaCFunction f) {
  gen.flutter_lua_bridge_pushcfunction(L, f);
}

/// 压入外部字符串
///
/// [L] - Lua 状态
/// [s] - 字符串
/// [len] - 字符串长度
/// [falloc] - 分配函数
/// [ud] - 用户数据
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaPushexternalstring(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> s,
  int len,
  LuaAlloc falloc,
  ffi.Pointer<ffi.Void> ud,
) {
  return gen.flutter_lua_bridge_pushexternalstring(L, s, len, falloc, ud);
}

/// 压入格式化字符串
///
/// [L] - Lua 状态
/// [fmt] - 格式化字符串
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaPushfstring(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> fmt,
) {
  return gen.flutter_lua_bridge_pushfstring(L, fmt);
}

/// 压入全局表
///
/// [L] - Lua 状态
void luaPushglobaltable(ffi.Pointer<gen.lua_State> L) {
  gen.flutter_lua_bridge_pushglobaltable(L);
}

/// 压入整数
///
/// [L] - Lua 状态
/// [n] - 整数值
void luaPushinteger(ffi.Pointer<gen.lua_State> L, LuaInteger n) {
  gen.flutter_lua_bridge_pushinteger(L, n);
}

/// 压入轻量用户数据
///
/// [L] - Lua 状态
/// [p] - 指针
void luaPushlightuserdata(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Void> p) {
  gen.flutter_lua_bridge_pushlightuserdata(L, p);
}

/// 压入字符串字面量
///
/// [L] - Lua 状态
/// [s] - 字符串
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaPushliteral(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> s,
) {
  return gen.flutter_lua_bridge_pushliteral(L, s);
}

/// 压入指定长度字符串
///
/// [L] - Lua 状态
/// [s] - 字符串
/// [len] - 字符串长度
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaPushlstring(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> s,
  int len,
) {
  return gen.flutter_lua_bridge_pushlstring(L, s, len);
}

/// 压入 nil
///
/// [L] - Lua 状态
void luaPushnil(ffi.Pointer<gen.lua_State> L) {
  gen.flutter_lua_bridge_pushnil(L);
}

/// 压入数字
///
/// [L] - Lua 状态
/// [n] - 数字值
void luaPushnumber(ffi.Pointer<gen.lua_State> L, LuaNumber n) {
  gen.flutter_lua_bridge_pushnumber(L, n);
}

/// 压入字符串
///
/// [L] - Lua 状态
/// [s] - 字符串
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaPushstring(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> s,
) {
  return gen.flutter_lua_bridge_pushstring(L, s);
}

/// 压入线程
///
/// [L] - Lua 状态
/// 返回 1 表示是主线程，0 表示不是
int luaPushthread(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_pushthread(L);
}

/// 压入可变参数格式化字符串
///
/// [L] - Lua 状态
/// [fmt] - 格式化字符串
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaPushvfstring(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> fmt,
) {
  return gen.flutter_lua_bridge_pushvfstring(L, fmt);
}
