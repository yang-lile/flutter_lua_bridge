/// Lua C API 调试
///
/// 此文件包含 Lua C API 中所有调试相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 获取钩子函数
///
/// [L] - Lua 状态
/// 返回钩子函数指针
LuaHook luaGethook(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_gethook(L);
}

/// 获取钩子计数
///
/// [L] - Lua 状态
/// 返回钩子计数
int luaGethookcount(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_gethookcount(L);
}

/// 获取钩子掩码
///
/// [L] - Lua 状态
/// 返回钩子掩码
int luaGethookmask(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_gethookmask(L);
}

/// 获取调试信息
///
/// [L] - Lua 状态
/// [what] - 要获取的信息
/// [ar] - 调试信息结构
/// 返回 1 表示成功，否则返回 0
int luaGetinfo(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> what,
  ffi.Pointer<ffi.Void> ar,
) {
  return gen.flutter_lua_bridge_getinfo(L, what, ar);
}

/// 获取局部变量
///
/// [L] - Lua 状态
/// [ar] - 调试信息结构
/// [n] - 变量索引
/// 返回变量名
ffi.Pointer<ffi.Char> luaGetlocal(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Void> ar,
  int n,
) {
  return gen.flutter_lua_bridge_getlocal(L, ar, n);
}

/// 获取栈信息
///
/// [L] - Lua 状态
/// [level] - 栈层级
/// [ar] - 调试信息结构
/// 返回 1 表示成功，否则返回 0
int luaGetstack(
  ffi.Pointer<gen.lua_State> L,
  int level,
  ffi.Pointer<ffi.Void> ar,
) {
  return gen.flutter_lua_bridge_getstack(L, level, ar);
}

/// 设置钩子
///
/// [L] - Lua 状态
/// [func] - 钩子函数
/// [mask] - 钩子掩码
/// [count] - 钩子计数
void luaSethook(
  ffi.Pointer<gen.lua_State> L,
  LuaHook func,
  int mask,
  int count,
) {
  gen.flutter_lua_bridge_sethook(L, func, mask, count);
}

/// 设置局部变量
///
/// [L] - Lua 状态
/// [ar] - 调试信息结构
/// [n] - 变量索引
/// 返回变量名
ffi.Pointer<ffi.Char> luaSetlocal(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Void> ar,
  int n,
) {
  return gen.flutter_lua_bridge_setlocal(L, ar, n);
}

/// 获取上值 ID
///
/// [L] - Lua 状态
/// [fidx] - 函数索引
/// [n] - 上值索引
/// 返回上值 ID 指针
ffi.Pointer<ffi.Void> luaUpvalueid(
  ffi.Pointer<gen.lua_State> L,
  int fidx,
  int n,
) {
  return gen.flutter_lua_bridge_upvalueid(L, fidx, n);
}

/// 获取上值索引
///
/// [i] - 上值索引
/// 返回上值索引
int luaUpvalueindex(int i) {
  return gen.flutter_lua_bridge_upvalueindex(i);
}

/// 连接上值
///
/// [L] - Lua 状态
/// [fidx1] - 第一个函数索引
/// [n1] - 第一个上值索引
/// [fidx2] - 第二个函数索引
/// [n2] - 第二个上值索引
void luaUpvaluejoin(
  ffi.Pointer<gen.lua_State> L,
  int fidx1,
  int n1,
  int fidx2,
  int n2,
) {
  gen.flutter_lua_bridge_upvaluejoin(L, fidx1, n1, fidx2, n2);
}

/// 设置 panic 函数
///
/// [L] - Lua 状态
/// [panicf] - panic 函数
/// 返回旧的 panic 函数
LuaHook luaAtpanic(ffi.Pointer<gen.lua_State> L, LuaHook panicf) {
  return gen.flutter_lua_bridge_atpanic(L, panicf);
}
