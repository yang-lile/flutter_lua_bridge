/// Lua 辅助库其他操作
///
/// 此文件包含 Lua 辅助库中所有其他操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 分配函数
///
/// [ud] - 用户数据
/// [ptr] - 指针
/// [osize] - 旧大小
/// [nsize] - 新大小
/// 返回分配的指针
ffi.Pointer<ffi.Void> luaLibAlloc(
  ffi.Pointer<ffi.Void> ud,
  ffi.Pointer<ffi.Void> ptr,
  int osize,
  int nsize,
) {
  return gen.flutter_lua_bridgeL_alloc(ud, ptr, osize, nsize);
}

/// 生成种子
///
/// [L] - Lua 状态
/// 返回种子值
int luaLibMakeseed(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridgeL_makeseed(L);
}

/// 推入失败值
///
/// [L] - Lua 状态
void luaLibPushfail(ffi.Pointer<gen.lua_State> L) {
  gen.flutter_lua_bridgeL_pushfail(L);
}

/// 创建引用
///
/// [L] - Lua 状态
/// [t] - 表索引
/// 返回引用 ID
int luaLibRef(ffi.Pointer<gen.lua_State> L, int t) {
  return gen.flutter_lua_bridgeL_ref(L, t);
}

/// 测试用户数据
///
/// [L] - Lua 状态
/// [ud] - 参数索引
/// [tname] - 类型名称
/// 返回用户数据指针
ffi.Pointer<ffi.Void> luaLibTestudata(
  ffi.Pointer<gen.lua_State> L,
  int ud,
  ffi.Pointer<ffi.Char> tname,
) {
  return gen.flutter_lua_bridgeL_testudata(L, ud, tname);
}

/// 释放引用
///
/// [L] - Lua 状态
/// [t] - 表索引
/// [ref] - 引用 ID
void luaLibUnref(ffi.Pointer<gen.lua_State> L, int t, int ref) {
  gen.flutter_lua_bridgeL_unref(L, t, ref);
}
