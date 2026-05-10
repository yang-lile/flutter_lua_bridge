/// Lua 辅助库缓冲区操作
///
/// 此文件包含 Lua 辅助库中所有缓冲区操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 添加字符
///
/// [B] - 缓冲区
/// [c] - 字符
void luaLibAddchar(ffi.Pointer<ffi.Void> B, int c) {
  gen.flutter_lua_bridgeL_addchar(B, c);
}

/// 添加替换字符串
///
/// [B] - 缓冲区
/// [s] - 源字符串
/// [p] - 模式
/// [r] - 替换字符串
void luaLibAddgsub(
  ffi.Pointer<ffi.Void> B,
  ffi.Pointer<ffi.Char> s,
  ffi.Pointer<ffi.Char> p,
  ffi.Pointer<ffi.Char> r,
) {
  gen.flutter_lua_bridgeL_addgsub(B, s, p, r);
}

/// 添加字符串
///
/// [B] - 缓冲区
/// [s] - 字符串
/// [l] - 长度
void luaLibAddlstring(ffi.Pointer<ffi.Void> B, ffi.Pointer<ffi.Char> s, int l) {
  gen.flutter_lua_bridgeL_addlstring(B, s, l);
}

/// 添加大小
///
/// [B] - 缓冲区
/// [n] - 大小
void luaLibAddsize(ffi.Pointer<ffi.Void> B, int n) {
  gen.flutter_lua_bridgeL_addsize(B, n);
}

/// 添加字符串
///
/// [B] - 缓冲区
/// [s] - 字符串
void luaLibAddstring(ffi.Pointer<ffi.Void> B, ffi.Pointer<ffi.Char> s) {
  gen.flutter_lua_bridgeL_addstring(B, s);
}

/// 添加值
///
/// [B] - 缓冲区
void luaLibAddvalue(ffi.Pointer<ffi.Void> B) {
  gen.flutter_lua_bridgeL_addvalue(B);
}

/// 获取缓冲区地址
///
/// [B] - 缓冲区
/// 返回缓冲区地址
ffi.Pointer<ffi.Char> luaLibBuffaddr(ffi.Pointer<ffi.Void> B) {
  return gen.flutter_lua_bridgeL_buffaddr(B);
}

/// 初始化缓冲区
///
/// [L] - Lua 状态
/// [B] - 缓冲区
void luaLibBuffinit(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Void> B) {
  gen.flutter_lua_bridgeL_buffinit(L, B);
}

/// 初始化缓冲区（指定大小）
///
/// [L] - Lua 状态
/// [B] - 缓冲区
/// [sz] - 大小
/// 返回缓冲区地址
ffi.Pointer<ffi.Char> luaLibBuffinitsize(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Void> B,
  int sz,
) {
  return gen.flutter_lua_bridgeL_buffinitsize(L, B, sz);
}

/// 获取缓冲区长度
///
/// [B] - 缓冲区
/// 返回缓冲区长度
int luaLibBufflen(ffi.Pointer<ffi.Void> B) {
  return gen.flutter_lua_bridgeL_bufflen(B);
}

/// 减少缓冲区大小
///
/// [B] - 缓冲区
/// [n] - 减少的数量
void luaLibBuffsub(ffi.Pointer<ffi.Void> B, int n) {
  gen.flutter_lua_bridgeL_buffsub(B, n);
}

/// 准备缓冲区
///
/// [B] - 缓冲区
/// 返回缓冲区地址
ffi.Pointer<ffi.Char> luaLibPrepbuffer(ffi.Pointer<ffi.Void> B) {
  return gen.flutter_lua_bridgeL_prepbuffer(B);
}

/// 准备缓冲区（指定大小）
///
/// [B] - 缓冲区
/// [sz] - 大小
/// 返回缓冲区地址
ffi.Pointer<ffi.Char> luaLibPrepbuffsize(ffi.Pointer<ffi.Void> B, int sz) {
  return gen.flutter_lua_bridgeL_prepbuffsize(B, sz);
}

/// 推送结果
///
/// [B] - 缓冲区
void luaLibPushresult(ffi.Pointer<ffi.Void> B) {
  gen.flutter_lua_bridgeL_pushresult(B);
}

/// 推送结果（指定大小）
///
/// [B] - 缓冲区
/// [sz] - 大小
void luaLibPushresultsize(ffi.Pointer<ffi.Void> B, int sz) {
  gen.flutter_lua_bridgeL_pushresultsize(B, sz);
}
