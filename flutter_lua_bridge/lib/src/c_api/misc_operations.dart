/// Lua C API 其他操作
///
/// 此文件包含 Lua C API 中所有其他操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 算术运算
///
/// [L] - Lua 状态
/// [op] - 操作类型
void luaArith(ffi.Pointer<gen.lua_State> L, LuaArith op) {
  gen.flutter_lua_bridge_arith(L, op.value);
}

/// 比较
///
/// [L] - Lua 状态
/// [idx1] - 第一个索引
/// [idx2] - 第二个索引
/// [op] - 比较操作
/// 返回 1 表示结果为 true，否则返回 0
int luaCompare(
  ffi.Pointer<gen.lua_State> L,
  int idx1,
  int idx2,
  LuaCompare op,
) {
  return gen.flutter_lua_bridge_compare(L, idx1, idx2, op.value);
}

/// 连接
///
/// [L] - Lua 状态
/// [n] - 要连接的元素数量
void luaConcat(ffi.Pointer<gen.lua_State> L, int n) {
  gen.flutter_lua_bridge_concat(L, n);
}

/// 复制
///
/// [L] - Lua 状态
/// [fromidx] - 源索引
/// [toidx] - 目标索引
void luaCopy(ffi.Pointer<gen.lua_State> L, int fromidx, int toidx) {
  gen.flutter_lua_bridge_copy(L, fromidx, toidx);
}

/// 创建表
///
/// [L] - Lua 状态
/// [nseq] - 数组元素数量
/// [nrec] - 哈希元素数量
void luaCreatetable(ffi.Pointer<gen.lua_State> L, int nseq, int nrec) {
  gen.flutter_lua_bridge_createtable(L, nseq, nrec);
}

/// 创建新表
///
/// [L] - Lua 状态
void luaNewtable(ffi.Pointer<gen.lua_State> L) {
  gen.flutter_lua_bridge_newtable(L);
}

/// 转储函数
///
/// [L] - Lua 状态
/// [writer] - 写入器函数
/// [data] - 用户数据
/// [strip] - 是否去除调试信息
/// 返回 0 表示成功，否则返回错误码
int luaDump(
  ffi.Pointer<gen.lua_State> L,
  LuaWriter writer,
  ffi.Pointer<ffi.Void> data,
  int strip,
) {
  return gen.flutter_lua_bridge_dump(L, writer, data, strip);
}

/// 获取长度
///
/// [L] - Lua 状态
/// [idx] - 索引
void luaLen(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_len(L, idx);
}

/// 加载代码
///
/// [L] - Lua 状态
/// [reader] - 读取器函数
/// [dt] - 用户数据
/// [chunkname] - 代码块名称
/// [mode] - 加载模式
/// 返回状态码
int luaLoad(
  ffi.Pointer<gen.lua_State> L,
  LuaReader reader,
  ffi.Pointer<ffi.Void> dt,
  ffi.Pointer<ffi.Char> chunkname,
  ffi.Pointer<ffi.Char> mode,
) {
  return gen.flutter_lua_bridge_load(L, reader, dt, chunkname, mode);
}

/// 数字转 C 字符串
///
/// [L] - Lua 状态
/// [n] - 数字
/// [len] - 输出参数，字符串长度
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaNumbertocstring(
  ffi.Pointer<gen.lua_State> L,
  LuaNumber n,
  ffi.Pointer<ffi.Size> len,
) {
  return gen.flutter_lua_bridge_numbertocstring(L, n, len);
}

/// 数字转整数
///
/// [n] - 数字
/// [p] - 输出参数，整数值
/// 返回 1 表示成功，否则返回 0
int luaNumbertointeger(LuaNumber n, ffi.Pointer<ffi.Int64> p) {
  return gen.flutter_lua_bridge_numbertointeger(n, p);
}

/// 原始相等比较
///
/// [L] - Lua 状态
/// [idx1] - 第一个索引
/// [idx2] - 第二个索引
/// 返回 1 表示相等，否则返回 0
int luaRawequal(ffi.Pointer<gen.lua_State> L, int idx1, int idx2) {
  return gen.flutter_lua_bridge_rawequal(L, idx1, idx2);
}

/// 注册函数
///
/// [L] - Lua 状态
/// [n] - 函数名
/// [f] - C 函数
void luaRegister(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> n,
  LuaCFunction f,
) {
  gen.flutter_lua_bridge_register(L, n, f);
}

/// 重置线程
///
/// [L] - Lua 状态
/// 返回状态码
int luaResetthread(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_resetthread(L);
}

/// 设置警告函数
///
/// [L] - Lua 状态
/// [f] - 警告函数
/// [ud] - 用户数据
void luaSetwarnf(
  ffi.Pointer<gen.lua_State> L,
  LuaWarnFunction f,
  ffi.Pointer<ffi.Void> ud,
) {
  gen.flutter_lua_bridge_setwarnf(L, f, ud);
}

/// 字符串转数字
///
/// [L] - Lua 状态
/// [s] - 字符串
/// 返回字符串长度
int luaStringtonumber(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> s,
) {
  return gen.flutter_lua_bridge_stringtonumber(L, s);
}

/// 标记为 to-be-closed
///
/// [L] - Lua 状态
/// [idx] - 索引
void luaToclose(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_toclose(L, idx);
}

/// 发出警告
///
/// [L] - Lua 状态
/// [msg] - 警告消息
/// [tocont] - 是否继续
void luaWarning(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> msg, int tocont) {
  gen.flutter_lua_bridge_warning(L, msg, tocont);
}
