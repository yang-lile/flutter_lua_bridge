/// Lua 辅助库类型转换
///
/// 此文件包含 Lua 辅助库中所有类型转换相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 获取长度
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回长度
int luaLibLen(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridgeL_len(L, idx);
}

/// 转换为字符串
///
/// [L] - Lua 状态
/// [idx] - 索引
/// [len] - 输出参数，字符串长度
/// 返回字符串指针
ffi.Pointer<ffi.Char> luaLibTolstring(
  ffi.Pointer<gen.lua_State> L,
  int idx,
  ffi.Pointer<ffi.Size> len,
) {
  return gen.flutter_lua_bridgeL_tolstring(L, idx, len);
}

/// 获取类型名称
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回类型名称
ffi.Pointer<ffi.Char> luaLibTypename(
  ffi.Pointer<gen.lua_State> L,
  int idx,
) {
  return gen.flutter_lua_bridgeL_typename(L, idx);
}
