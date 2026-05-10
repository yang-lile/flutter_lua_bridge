/// Lua 辅助库加载执行
///
/// 此文件包含 Lua 辅助库中所有加载和执行相关的函数。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

/// 执行文件
///
/// [L] - Lua 状态
/// [fn] - 文件名
/// 返回状态码
int luaLibDofile(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> fn) {
  return gen.flutter_lua_bridgeL_dofile(L, fn);
}

/// 执行字符串
///
/// [L] - Lua 状态
/// [s] - Lua 代码字符串
/// 返回状态码
int luaLibDostring(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> s) {
  return gen.flutter_lua_bridgeL_dostring(L, s);
}

/// 加载缓冲区
///
/// [L] - Lua 状态
/// [buff] - 缓冲区
/// [sz] - 缓冲区大小
/// [name] - 代码块名称
/// 返回状态码
int luaLibLoadbuffer(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> buff,
  int sz,
  ffi.Pointer<ffi.Char> name,
) {
  return gen.flutter_lua_bridgeL_loadbuffer(L, buff, sz, name);
}

/// 加载缓冲区（指定模式）
///
/// [L] - Lua 状态
/// [buff] - 缓冲区
/// [sz] - 缓冲区大小
/// [name] - 代码块名称
/// [mode] - 加载模式
/// 返回状态码
int luaLibLoadbufferx(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> buff,
  int sz,
  ffi.Pointer<ffi.Char> name,
  ffi.Pointer<ffi.Char> mode,
) {
  return gen.flutter_lua_bridgeL_loadbufferx(L, buff, sz, name, mode);
}

/// 加载文件
///
/// [L] - Lua 状态
/// [filename] - 文件名
/// 返回状态码
int luaLibLoadfile(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> filename) {
  return gen.flutter_lua_bridgeL_loadfile(L, filename);
}

/// 加载文件（指定模式）
///
/// [L] - Lua 状态
/// [filename] - 文件名
/// [mode] - 加载模式
/// 返回状态码
int luaLibLoadfilex(
  ffi.Pointer<gen.lua_State> L,
  ffi.Pointer<ffi.Char> filename,
  ffi.Pointer<ffi.Char> mode,
) {
  return gen.flutter_lua_bridgeL_loadfilex(L, filename, mode);
}

/// 加载字符串
///
/// [L] - Lua 状态
/// [s] - Lua 代码字符串
/// 返回状态码
int luaLibLoadstring(ffi.Pointer<gen.lua_State> L, ffi.Pointer<ffi.Char> s) {
  return gen.flutter_lua_bridgeL_loadstring(L, s);
}
