/// Lua C API 栈操作
///
/// 此文件包含 Lua C API 中所有与栈操作相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 将可接受索引转换为绝对索引
///
/// [L] - Lua 状态
/// [idx] - 可接受索引
/// 返回绝对索引
int luaAbsindex(ffi.Pointer<gen.lua_State> L, int idx) {
  return gen.flutter_lua_bridge_absindex(L, idx);
}

/// 获取栈顶索引
///
/// [L] - Lua 状态
/// 返回栈顶索引（0 表示空栈）
int luaGettop(ffi.Pointer<gen.lua_State> L) {
  return gen.flutter_lua_bridge_gettop(L);
}

/// 设置栈顶
///
/// [L] - Lua 状态
/// [idx] - 新的栈顶索引
void luaSettop(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_settop(L, idx);
}

/// 将指定索引的值压栈
///
/// [L] - Lua 状态
/// [idx] - 索引
void luaPushvalue(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_pushvalue(L, idx);
}

/// 移除指定位置的元素
///
/// [L] - Lua 状态
/// [idx] - 要移除的索引
void luaRemove(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_remove(L, idx);
}

/// 插入元素到指定位置
///
/// [L] - Lua 状态
/// [idx] - 插入位置
void luaInsert(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_insert(L, idx);
}

/// 替换指定位置的元素
///
/// [L] - Lua 状态
/// [idx] - 要替换的索引
void luaReplace(ffi.Pointer<gen.lua_State> L, int idx) {
  gen.flutter_lua_bridge_replace(L, idx);
}

/// 旋转栈元素
///
/// [L] - Lua 状态
/// [idx] - 旋转的起始索引
/// [n] - 旋转的元素数量
void luaRotate(ffi.Pointer<gen.lua_State> L, int idx, int n) {
  gen.flutter_lua_bridge_rotate(L, idx, n);
}

/// 弹出 n 个元素
///
/// [L] - Lua 状态
/// [n] - 要弹出的元素数量
void luaPop(ffi.Pointer<gen.lua_State> L, int n) {
  gen.flutter_lua_bridge_pop(L, n);
}

/// 在不同状态间移动值
///
/// [from] - 源状态
/// [to] - 目标状态
/// [n] - 要移动的元素数量
void luaXmove(ffi.Pointer<gen.lua_State> from, ffi.Pointer<gen.lua_State> to, int n) {
  gen.flutter_lua_bridge_xmove(from, to, n);
}
