/// Lua C API 元表操作
///
/// 此文件包含 Lua C API 中所有元表操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 获取元表
///
/// [L] - Lua 状态
/// [objindex] - 对象索引
/// 返回 1 表示有元表，否则返回 0
int luaGetmetatable(ffi.Pointer<gen.lua_State> L, int objindex) {
  return gen.flutter_lua_bridge_getmetatable(L, objindex);
}

/// 设置元表
///
/// [L] - Lua 状态
/// [idx] - 对象索引
void luaSetmetatable(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_setmetatable(L, idx);
}
