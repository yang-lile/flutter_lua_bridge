/// Lua C API 类型检查
///
/// 此文件包含 Lua C API 中所有类型检查相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 检查是否为布尔值
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是布尔值，否则返回 0
int luaIsboolean(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isboolean(L, idx);
}

/// 检查是否为 C 函数
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是 C 函数，否则返回 0
int luaIscfunction(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_iscfunction(L, idx);
}

/// 检查是否为函数
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是函数，否则返回 0
int luaIsfunction(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isfunction(L, idx);
}

/// 检查是否为整数
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是整数，否则返回 0
int luaIsinteger(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isinteger(L, idx);
}

/// 检查是否为轻量用户数据
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是轻量用户数据，否则返回 0
int luaIslightuserdata(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_islightuserdata(L, idx);
}

/// 检查是否为 nil
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是 nil，否则返回 0
int luaIsnil(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isnil(L, idx);
}

/// 检查是否无效
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示无效，否则返回 0
int luaIsnone(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isnone(L, idx);
}

/// 检查是否无效或 nil
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示无效或 nil，否则返回 0
int luaIsnoneornil(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isnoneornil(L, idx);
}

/// 检查是否为数字
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是数字，否则返回 0
int luaIsnumber(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isnumber(L, idx);
}

/// 检查是否为字符串
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是字符串，否则返回 0
int luaIsstring(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isstring(L, idx);
}

/// 检查是否为表
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是表，否则返回 0
int luaIstable(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_istable(L, idx);
}

/// 检查是否为线程
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是线程，否则返回 0
int luaIsthread(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isthread(L, idx);
}

/// 检查是否为用户数据
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示是用户数据，否则返回 0
int luaIsuserdata(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_isuserdata(L, idx);
}

/// 检查是否可 yield
///
/// [L] - Lua 状态
/// 返回 1 表示可 yield，否则返回 0
int luaIsyieldable(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_isyieldable(L);
}
