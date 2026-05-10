/// Lua 辅助库参数检查
///
/// 此文件包含 Lua 辅助库中所有参数检查相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 检查参数
///
/// [L] - Lua 状态
/// [cond] - 条件
/// [arg] - 参数索引
/// [extramsg] - 额外消息
void luaLibArgcheck(
  ffi.Pointer<gen.lua_State> L,
  int cond,
  int arg,
  ffi.Pointer<ffi.Char> extramsg,
) {
  gen.flutter_lua_bridgeL_argcheck(L, cond, arg, extramsg);
}

/// 参数错误
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [extramsg] - 额外消息
/// 返回状态码
int luaLibArgerror(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  ffi.Pointer<ffi.Char> extramsg,
) {
  return gen.flutter_lua_bridgeL_argerror(L, arg, extramsg);
}

/// 期望参数类型
///
/// [L] - Lua 状态
/// [cond] - 条件
/// [arg] - 参数索引
/// [tname] - 类型名称
void luaLibArgexpected(
  ffi.Pointer<gen.lua_State> L,
  int cond,
  int arg,
  ffi.Pointer<ffi.Char> tname,
) {
  gen.flutter_lua_bridgeL_argexpected(L, cond, arg, tname);
}

/// 检查任意类型
///
/// [L] - Lua 状态
/// [arg] - 参数索引
void luaLibCheckany(ffi.Pointer<gen.lua_State> L, int arg) {
  gen.flutter_lua_bridgeL_checkany(L, arg);
}

/// 检查整数
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// 返回整数值
int luaLibCheckinteger(ffi.Pointer<gen.lua_State> L, int arg) {
  return gen.flutter_lua_bridgeL_checkinteger(L, arg);
}

/// 检查字符串
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [l] - 输出参数，字符串长度
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaLibChecklstring(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  ffi.Pointer<ffi.Size> l,
) {
  return gen.flutter_lua_bridgeL_checklstring(L, arg, l);
}

/// 检查数字
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// 返回数字值
double luaLibChecknumber(ffi.Pointer<gen.lua_State> L, int arg) {
  return gen.flutter_lua_bridgeL_checknumber(L, arg);
}

/// 检查选项
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [def] - 默认值
/// [lst] - 选项列表
/// 返回选项索引
int luaLibCheckoption(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  ffi.Pointer<ffi.Char> def,
  ffi.Pointer<ffi.Pointer<ffi.Char>> lst,
) {
  return gen.flutter_lua_bridgeL_checkoption(L, arg, def, lst);
}

/// 检查栈空间
///
/// [L] - Lua 状态
/// [sz] - 需要的额外栈空间
/// [msg] - 错误消息
void luaLibCheckstack(
  ffi.Pointer<gen.lua_State> L,
  int sz,
  ffi.Pointer<ffi.Char> msg,
) {
  gen.flutter_lua_bridgeL_checkstack(L, sz, msg);
}

/// 检查字符串
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaLibCheckstring(
  ffi.Pointer<gen.lua_State> L,
  int arg,
) {
  return gen.flutter_lua_bridgeL_checkstring(L, arg);
}

/// 检查类型
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [t] - 类型
void luaLibChecktype(ffi.Pointer<gen.lua_State> L, int arg, int t) {
  gen.flutter_lua_bridgeL_checktype(L, arg, t);
}

/// 检查用户数据
///
/// [L] - Lua 状态
/// [ud] - 参数索引
/// [tname] - 类型名称
/// 返回用户数据指针
ffi.Pointer<ffi.Void> luaLibCheckudata(
  ffi.Pointer<gen.lua_State> L,
  int ud,
  ffi.Pointer<ffi.Char> tname,
) {
  return gen.flutter_lua_bridgeL_checkudata(L, ud, tname);
}

/// 检查版本
///
/// [L] - Lua 状态
void luaLibCheckversion(ffi.Pointer<gen.lua_State> L) {
  gen.flutter_lua_bridgeL_checkversion(L);
}

/// 可选整数
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [d] - 默认值
/// 返回整数值
int luaLibOptinteger(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  int d,
) {
  return gen.flutter_lua_bridgeL_optinteger(L, arg, d);
}

/// 可选字符串
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [d] - 默认值
/// [l] - 输出参数，字符串长度
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaLibOptlstring(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  ffi.Pointer<ffi.Char> d,
  ffi.Pointer<ffi.Size> l,
) {
  return gen.flutter_lua_bridgeL_optlstring(L, arg, d, l);
}

/// 可选数字
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [d] - 默认值
/// 返回数字值
double luaLibOptnumber(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  double d,
) {
  return gen.flutter_lua_bridgeL_optnumber(L, arg, d);
}

/// 可选字符串
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [d] - 默认值
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaLibOptstring(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  ffi.Pointer<ffi.Char> d,
) {
  return gen.flutter_lua_bridgeL_optstring(L, arg, d);
}
