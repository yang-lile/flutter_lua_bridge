/// Lua C API 函数调用
///
/// 此文件包含 Lua C API 中所有函数调用和协程相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 调用函数
///
/// [L] - Lua 状态
/// [nargs] - 参数数量
/// [nresults] - 结果数量
void luaCall(ffi.Pointer<gen.lua_State> L, int nargs, int nresults) {
  gen.flutter_lua_bridge_call(L, nargs, nresults);
}

/// 调用函数（带 yield 支持）
///
/// [L] - Lua 状态
/// [nargs] - 参数数量
/// [nresults] - 结果数量
/// [ctx] - 上下文
/// [k] - continuation 函数
void luaCallk(
  ffi.Pointer<gen.lua_State> L,
  int nargs,
  int nresults,
  int ctx,
  LuaKFunction k,
) {
  gen.flutter_lua_bridge_callk(L, nargs, nresults, ctx, k);
}

/// 保护调用
///
/// [L] - Lua 状态
/// [nargs] - 参数数量
/// [nresults] - 结果数量
/// [errfunc] - 错误处理函数索引
/// 返回状态码
int luaPcall(
  ffi.Pointer<gen.lua_State> L,
  int nargs,
  int nresults,
  int errfunc,
) {
  return gen.flutter_lua_bridge_pcall(L, nargs, nresults, errfunc);
}

/// 保护调用（带 yield 支持）
///
/// [L] - Lua 状态
/// [nargs] - 参数数量
/// [nresults] - 结果数量
/// [errfunc] - 错误处理函数索引
/// [ctx] - 上下文
/// [k] - continuation 函数
/// 返回状态码
int luaPcallk(
  ffi.Pointer<gen.lua_State> L,
  int nargs,
  int nresults,
  int errfunc,
  int ctx,
  LuaKFunction k,
) {
  return gen.flutter_lua_bridge_pcallk(L, nargs, nresults, errfunc, ctx, k);
}

/// 恢复协程
///
/// [L] - Lua 状态
/// [from] - 恢复的线程
/// [narg] - 参数数量
/// [nres] - 输出参数，结果数量
/// 返回状态码
int luaResume(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<gen.lua_State> from,
  int narg,
  ffi.Pointer<ffi.Int> nres,
) {
  return gen.flutter_lua_bridge_resume(L, from, narg, nres);
}

/// 让出协程
///
/// [L] - Lua 状态
/// [nresults] - 结果数量
/// 返回状态码
int luaYield(ffi.Pointer<gen.lua_State> L, int nresults) {
  return gen.flutter_lua_bridge_yield(L, nresults);
}

/// 让出协程（带 continuation）
///
/// [L] - Lua 状态
/// [nresults] - 结果数量
/// [ctx] - 上下文
/// [k] - continuation 函数
/// 返回状态码
int luaYieldk(
  ffi.Pointer<gen.lua_State> L,
  int nresults,
  int ctx,
  LuaKFunction k,
) {
  return gen.flutter_lua_bridge_yieldk(L, nresults, ctx, k);
}
