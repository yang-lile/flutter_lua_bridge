/// Lua C API 垃圾回收
///
/// 此文件包含 Lua C API 中所有垃圾回收相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;
import 'types.dart';

/// 垃圾回收控制
///
/// [L] - Lua 状态
/// [what] - 操作类型
/// [data] - 操作数据
/// 返回结果
int luaGc(ffi.Pointer<gen.lua_State> L, LuaGC what, int data) {
  return gen.flutter_lua_bridge_gc(L, what.value, data);
}

/// 关闭 to-be-closed 槽
///
/// [L] - Lua 状态
/// [idx] - 索引
/// 返回 1 表示成功，否则返回 0
int luaCloseslot(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_closeslot(L, idx);
}
