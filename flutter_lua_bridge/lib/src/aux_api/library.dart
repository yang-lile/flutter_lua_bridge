/// Lua 辅助库库管理
///
/// 此文件包含 Lua 辅助库中所有库管理相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 创建新库
///
/// [L] - Lua 状态
/// [l] - 注册表
/// [nrec] - 哈希元素数量
void luaLibNewlib(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Void> l, int nrec) {
  gen.flutter_lua_bridgeL_newlib(L, l, nrec);
}

/// 创建库表
///
/// [L] - Lua 状态
/// [nrec] - 哈希元素数量
void luaLibNewlibtable(ffi.Pointer<gen.lua_State> L, int nrec) {
  gen.flutter_lua_bridgeL_newlibtable(L, nrec);
}

/// 创建新状态
///
/// 返回新状态指针
ffi.Pointer<gen.lua_State> luaLibNewstate() {
  return gen.flutter_lua_bridgeL_newstate();
}

/// 打开标准库
///
/// [L] - Lua 状态
void luaLibOpenlibs(ffi.Pointer<gen.lua_State> L) {
  gen.flutter_lua_bridgeL_openlibs(L);
}

/// 打开指定库
///
/// [L] - Lua 状态
/// [libs] - 库列表（字符串）
void luaLibOpenselectedlibs(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> libs) {
  gen.flutter_lua_bridgeL_openselectedlibs(L, libs);
}

/// 需求模块
///
/// [L] - Lua 状态
/// [modname] - 模块名
/// [openf] - 打开函数
/// [glb] - 是否注册到全局表
void luaLibRequiref(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> modname,
  ffi.Pointer<ffi.Void> openf,
  int glb,
) {
  gen.flutter_lua_bridgeL_requiref(L, modname, openf, glb);
}

/// 设置函数
///
/// [L] - Lua 状态
/// [l] - 注册表
/// [nup] - 上值数量
void luaLibSetfuncs(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Void> l, int nup) {
  gen.flutter_lua_bridgeL_setfuncs(L, l, nup);
}
