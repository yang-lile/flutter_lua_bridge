/// Lua C API 内存管理
///
/// 此文件包含 Lua C API 中所有内存管理相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 获取分配函数
///
/// [L] - Lua 状态
/// [ud] - 输出参数，用户数据
/// 返回分配函数指针
ffi.Pointer<ffi.Void> luaGetallocf(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Pointer<ffi.Void>> ud,
) {
  return gen.flutter_lua_bridge_getallocf(L, ud);
}

/// 设置分配函数
///
/// [L] - Lua 状态
/// [f] - 分配函数
/// [ud] - 用户数据
void luaSetallocf(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Void> f,
  ffi.Pointer<ffi.Void> ud,
) {
  gen.flutter_lua_bridge_setallocf(L, f, ud);
}

/// 获取额外空间
///
/// [L] - Lua 状态
/// 返回额外空间指针
ffi.Pointer<ffi.Void> luaGetextraspace(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_getextraspace(L);
}

/// 创建用户数据
///
/// [L] - Lua 状态
/// [sz] - 大小
/// 返回用户数据指针
ffi.Pointer<ffi.Void> luaNewuserdata(
  ffi.Pointer<gen.lua_State> L,
  int sz,
) {
  return gen.flutter_lua_bridge_newuserdata(L, sz);
}

/// 创建用户数据（带值）
///
/// [L] - Lua 状态
/// [sz] - 大小
/// [nuvalue] - 用户值数量
/// 返回用户数据指针
ffi.Pointer<ffi.Void> luaNewuserdatauv(
  ffi.Pointer<gen.lua_State> L,
  int sz,
  int nuvalue,
) {
  return gen.flutter_lua_bridge_newuserdatauv(L, sz, nuvalue);
}

/// 获取用户数据值
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回值类型
int luaGetuservalue(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_getuservalue(L, idx);
}

/// 设置用户数据值
///
/// [L] - Lua 状态
/// [idx] - 索引
void luaSetuservalue(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_setuservalue(L, idx);
}

/// 获取用户数据值（索引）
///
/// [L] - Lua 状态
/// [idx] - 索引
/// [n] - 值索引
void luaGetiuservalue(ffi.Pointer<gen.lua_State> L, int idx, int n) {
  gen.flutter_lua_bridge_getiuservalue(L, idx, n);
}

/// 设置用户数据值（索引）
///
/// [L] - Lua 状态
/// [idx] - 索引
/// [n] - 值索引
void luaSetiuservalue(ffi.Pointer<gen.lua_State> L, int idx, int n) {
  gen.flutter_lua_bridge_setiuservalue(L, idx, n);
}

/// 关闭线程
///
/// [L] - Lua 状态
/// [from] - 源线程
/// 返回状态码
int luaClosethread(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<gen.lua_State> from,
) {
  return gen.flutter_lua_bridge_closethread(L, from);
}
