/// Lua 辅助库错误处理
///
/// 此文件包含 Lua 辅助库中所有错误处理相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 抛出错误
///
/// [L] - Lua 状态
/// [fmt] - 格式化字符串
/// 返回状态码
int luaLibError(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> fmt) {
  return gen.flutter_lua_bridgeL_error(L, fmt);
}

/// 执行结果
///
/// [L] - Lua 状态
/// [stat] - 执行状态
/// 返回状态码
int luaLibExecresult(ffi.Pointer<gen.lua_State> L, int stat) {
  return gen.flutter_lua_bridgeL_execresult(L, stat);
}

/// 文件操作结果
///
/// [L] - Lua 状态
/// [stat] - 文件操作状态
/// [fname] - 文件名
/// 返回状态码
int luaLibFileresult(
  ffi.Pointer<gen.lua_State> L,
  int stat,
  ffi.Pointer<ffi.Char> fname,
) {
  return gen.flutter_lua_bridgeL_fileresult(L, stat, fname);
}

/// 追踪栈
///
/// [l1] - Lua 状态
/// [l2] - 另一个 Lua 状态
/// [msg] - 错误消息
/// [level] - 起始层级
void luaLibTraceback(
  ffi.Pointer<gen.lua_State> l1,
  ffi.Pointer<gen.lua_State> l2,
  ffi.Pointer<ffi.Char> msg,
  int level,
) {
  gen.flutter_lua_bridgeL_traceback(l1, l2, msg, level);
}

/// 错误位置
///
/// [L] - Lua 状态
/// [lvl] - 层级
void luaLibWhere(ffi.Pointer<gen.lua_State> L, int lvl) {
  gen.flutter_lua_bridgeL_where(L, lvl);
}

/// 类型错误
///
/// [L] - Lua 状态
/// [arg] - 参数索引
/// [tname] - 类型名称
/// 返回状态码
int luaLibTypeerror(
  ffi.Pointer<gen.lua_State> L,
  int arg,
  ffi.Pointer<ffi.Char> tname,
) {
  return gen.flutter_lua_bridgeL_typeerror(L, arg, tname);
}
