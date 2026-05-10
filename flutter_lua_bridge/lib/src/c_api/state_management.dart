/// Lua C API 状态管理
///
/// 此文件包含 Lua C API 中所有状态管理相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 创建新状态
///
/// [f] - 分配函数
/// [ud] - 用户数据
/// 返回新状态指针
ffi.Pointer<gen.lua_State> luaNewstate(ffi.Pointer<ffi.Void> f, ffi.Pointer<ffi.Void> ud) {
  return gen.flutter_lua_bridge_newstate(f, ud);
}

/// 关闭状态
///
/// [L] - Lua 状态
void luaClose(ffi.Pointer<gen.lua_State> L) {
  gen.flutter_lua_bridge_close(L);
}

/// 获取状态
///
/// [L] - Lua 状态
/// 返回状态码
int luaStatus(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_status(L);
}

/// 获取版本
///
/// [L] - Lua 状态
/// 返回版本号
LuaNumber luaVersion(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_version(L);
}

/// 检查栈空间
///
/// [L] - Lua 状态
/// [n] - 需要的额外栈空间
/// 返回 1 表示有足够空间，否则返回 0
int luaCheckstack(ffi.Pointer<gen.lua_State> L, int n) {
  return gen.flutter_lua_bridge_checkstack(L, n);
}

/// 抛出错误
///
/// [L] - Lua 状态
/// 返回状态码（永远不会返回）
int luaError(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_error(L);
}

/// 创建新线程
///
/// [L] - Lua 状态
/// 返回新线程指针
ffi.Pointer<gen.lua_State> luaNewthread(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_newthread(L);
}
