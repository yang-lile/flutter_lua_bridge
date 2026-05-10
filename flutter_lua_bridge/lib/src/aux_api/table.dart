/// Lua 辅助库表和元表操作
///
/// 此文件包含 Lua 辅助库中所有表和元表操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 调用元方法
///
/// [L] - Lua 状态
/// [obj] - 对象索引
/// [e] - 事件名
/// 返回 1 表示成功，否则返回 0
int luaLibCallmeta(
  ffi.Pointer<gen.lua_State> L,
  int obj,
  ffi.Pointer<ffi.Char> e,
) {
  return gen.flutter_lua_bridgeL_callmeta(L, obj, e);
}

/// 获取元表字段
///
/// [L] - Lua 状态
/// [obj] - 对象索引
/// [e] - 事件名
/// 返回 1 表示成功，否则返回 0
int luaLibGetmetafield(
  ffi.Pointer<gen.lua_State> L,
  int obj,
  ffi.Pointer<ffi.Char> e,
) {
  return gen.flutter_lua_bridgeL_getmetafield(L, obj, e);
}

/// 获取元表
///
/// [L] - Lua 状态
/// [tname] - 类型名称
/// 返回 1 表示成功，否则返回 0
int luaLibGetmetatable(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> tname) {
  return gen.flutter_lua_bridgeL_getmetatable(L, tname);
}

/// 获取子表
///
/// [L] - Lua 状态
/// [idx] - 表索引
/// [fname] - 字段名
/// 返回 1 表示成功，否则返回 0
int luaLibGetsubtable(
  ffi.Pointer<gen.lua_State> L,
  int idx,
  ffi.Pointer<ffi.Char> fname,
) {
  return gen.flutter_lua_bridgeL_getsubtable(L, idx, fname);
}

/// 全局替换
///
/// [L] - Lua 状态
/// [s] - 源字符串
/// [p] - 模式
/// [r] - 替换字符串
/// 返回结果字符串
ffi.Pointer<ffi.Char> luaLibGsub(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> s,
  ffi.Pointer<ffi.Char> p,
  ffi.Pointer<ffi.Char> r,
) {
  return gen.flutter_lua_bridgeL_gsub(L, s, p, r);
}


/// 创建新元表
///
/// [L] - Lua 状态
/// [tname] - 类型名称
/// 返回 1 表示新创建，0 表示已存在
int luaLibNewmetatable(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> tname) {
  return gen.flutter_lua_bridgeL_newmetatable(L, tname);
}

/// 设置元表
///
/// [L] - Lua 状态
/// [tname] - 类型名称
void luaLibSetmetatable(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> tname) {
  gen.flutter_lua_bridgeL_setmetatable(L, tname);
}
