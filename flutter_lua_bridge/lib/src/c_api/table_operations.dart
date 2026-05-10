/// Lua C API 表操作
///
/// 此文件包含 Lua C API 中所有表访问和操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 获取字段
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [k] - 字段名
/// 返回字段值的类型
int luaGetfield(ffi.Pointer<gen.lua_State> L, int idx, ffi.Pointer<ffi.Char> k) {
  return gen.flutter_lua_bridge_getfield(L, idx, k);
}

/// 获取全局变量
///
/// [L] - Lua 状态
/// [name] - 变量名
/// 返回变量值的类型
int luaGetglobal(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> name) {
  return gen.flutter_lua_bridge_getglobal(L, name);
}

/// 获取数组元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [n] - 数组索引
/// 返回元素值的类型
int luaGeti(ffi.Pointer<gen.lua_State> L, int idx, LuaInteger n) {
  return gen.flutter_lua_bridge_geti(L, idx, n);
}

/// 获取表元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// 返回元素值的类型
int luaGettable(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_gettable(L, idx);
}

/// 原始获取
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// 返回元素值的类型
int luaRawget(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_rawget(L, idx);
}

/// 原始获取数组元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [n] - 数组索引
/// 返回元素值的类型
int luaRawgeti(ffi.Pointer<gen.lua_State> L, int idx, LuaInteger n) {
  return gen.flutter_lua_bridge_rawgeti(L, idx, n);
}

/// 原始获取指针键元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [p] - 指针键
/// 返回元素值的类型
int luaRawgetp(ffi.Pointer<gen.lua_State> L, int idx, ffi.Pointer<ffi.Void> p) {
  return gen.flutter_lua_bridge_rawgetp(L, idx, p);
}

/// 获取原始长度
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回长度
int luaRawlen(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_rawlen(L, idx);
}

/// 原始设置
///
/// [L] - Lua 状态
/// [idx] - 表索引
void luaRawset(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_rawset(L, idx);
}

/// 原始设置数组元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [n] - 数组索引
void luaRawseti(ffi.Pointer<gen.lua_State> L, int idx, LuaInteger n) {
  gen.flutter_lua_bridge_rawseti(L, idx, n);
}

/// 原始设置指针键元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [p] - 指针键
void luaRawsetp(ffi.Pointer<gen.lua_State> L, int idx, ffi.Pointer<ffi.Void> p) {
  gen.flutter_lua_bridge_rawsetp(L, idx, p);
}

/// 设置字段
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [k] - 字段名
void luaSetfield(ffi.Pointer<gen.lua_State> L, int idx, ffi.Pointer<ffi.Char> k) {
  gen.flutter_lua_bridge_setfield(L, idx, k);
}

/// 设置全局变量
///
/// [L] - Lua 状态
/// [name] - 变量名
void luaSetglobal(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> name) {
  gen.flutter_lua_bridge_setglobal(L, name);
}

/// 设置数组元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [n] - 数组索引
void luaSeti(ffi.Pointer<gen.lua_State> L, int idx, LuaInteger n) {
  gen.flutter_lua_bridge_seti(L, idx, n);
}

/// 设置表元素
///
/// [L] - Lua 状态
/// [idx] - 表索引
void luaSettable(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_settable(L, idx);
}

/// 遍历表
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// 返回 0 表示遍历结束，1 表示继续
int luaNext(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_next(L, idx);
}
