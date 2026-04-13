import 'dart:ffi' as ffi;
import 'gen/flutter_lua_bridge.g.dart' as flb;
import 'gen/lua_aux_api.dart';
import 'gen/lua_c_api.dart';

/// Lua 辅助库 API 实现
/// 
/// 注意：一些函数在 C 中是宏定义，不在 FFI 绑定中，这里提供 Dart 实现
class LuaAuxApiImpl implements LuaAuxApi {
  const LuaAuxApiImpl({required LuaCApi luaCApi}) : _luaCApi = luaCApi;
  
  final LuaCApi _luaCApi;

  // ========== 缓冲区操作函数 ==========
  
  @override
  void luaL_addchar(ffi.Pointer<flb.luaL_Buffer> B, int c) {
    // luaL_addchar 是 C 宏，实现为: ((void)((B)->b[(B)->n++] = (char)(c)))
    // 需要直接操作缓冲区结构
    final buffer = B.ref;
    final n = buffer.n;
    buffer.b[n] = c;
    buffer.n = n + 1;
  }

  @override
  void luaL_addgsub(ffi.Pointer<flb.luaL_Buffer> B, ffi.Pointer<ffi.Char> s, ffi.Pointer<ffi.Char> p, ffi.Pointer<ffi.Char> r) {
    flb.luaL_addgsub(B, s, p, r);
  }

  @override
  void luaL_addlstring(ffi.Pointer<flb.luaL_Buffer> B, ffi.Pointer<ffi.Char> s, int l) {
    flb.luaL_addlstring(B, s, l);
  }

  @override
  void luaL_addsize(ffi.Pointer<flb.luaL_Buffer> B, int n) {
    // luaL_addsize 是 C 宏，实现为: ((B)->n += (n))
    final buffer = B.ref;
    buffer.n = buffer.n + n;
  }

  @override
  void luaL_addstring(ffi.Pointer<flb.luaL_Buffer> B, ffi.Pointer<ffi.Char> s) {
    flb.luaL_addstring(B, s);
  }

  @override
  void luaL_addvalue(ffi.Pointer<flb.luaL_Buffer> B) {
    flb.luaL_addvalue(B);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_buffaddr(ffi.Pointer<flb.luaL_Buffer> B) {
    // luaL_buffaddr 是 C 宏，实现为: ((B)->b)
    return B.ref.b;
  }

  @override
  void luaL_buffinit(ffi.Pointer<lua_State> L, ffi.Pointer<flb.luaL_Buffer> B) {
    flb.luaL_buffinit(L, B);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_buffinitsize(ffi.Pointer<lua_State> L, ffi.Pointer<flb.luaL_Buffer> B, int sz) {
    return flb.luaL_buffinitsize(L, B, sz);
  }

  @override
  int luaL_bufflen(ffi.Pointer<flb.luaL_Buffer> B) {
    // luaL_bufflen 是 C 宏，实现为: ((B)->n)
    return B.ref.n;
  }

  @override
  void luaL_buffsub(ffi.Pointer<flb.luaL_Buffer> B, int n) {
    // luaL_buffsub 是 C 宏，实现为: ((B)->n -= (n))
    final buffer = B.ref;
    buffer.n = buffer.n - n;
  }

  @override
  void luaL_pushresult(ffi.Pointer<flb.luaL_Buffer> B) {
    flb.luaL_pushresult(B);
  }

  @override
  void luaL_pushresultsize(ffi.Pointer<flb.luaL_Buffer> B, int sz) {
    flb.luaL_pushresultsize(B, sz);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_prepbuffer(ffi.Pointer<flb.luaL_Buffer> B) {
    // luaL_prepbuffer 是 C 宏，实现为: luaL_prepbuffsize(B, LUAL_BUFFERSIZE)
    // LUAL_BUFFERSIZE 通常是 8192
    const lualBuffersize = 8192;
    return luaL_prepbuffsize(B, lualBuffersize);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_prepbuffsize(ffi.Pointer<flb.luaL_Buffer> B, int sz) {
    return flb.luaL_prepbuffsize(B, sz);
  }

  // ========== 参数检查函数 ==========

  @override
  void luaL_argcheck(ffi.Pointer<lua_State> L, int cond, int arg, ffi.Pointer<ffi.Char> extramsg) {
    // luaL_argcheck 是 C 宏，实现为: ((void)((cond) || luaL_argerror(L, (arg), (extramsg))))
    if (cond == 0) {
      luaL_argerror(L, arg, extramsg);
    }
  }

  @override
  int luaL_argerror(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Char> extramsg) {
    return flb.luaL_argerror(L, arg, extramsg);
  }

  @override
  void luaL_argexpected(ffi.Pointer<lua_State> L, int cond, int arg, ffi.Pointer<ffi.Char> tname) {
    // luaL_argexpected 是 C 宏，实现为: ((void)((cond) || luaL_typeerror(L, (arg), (tname))))
    if (cond == 0) {
      luaL_typeerror(L, arg, tname);
    }
  }

  @override
  void luaL_checkany(ffi.Pointer<lua_State> L, int arg) {
    flb.luaL_checkany(L, arg);
  }

  @override
  int luaL_checkinteger(ffi.Pointer<lua_State> L, int arg) {
    return flb.luaL_checkinteger(L, arg);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_checklstring(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Size> l) {
    return flb.luaL_checklstring(L, arg, l);
  }

  @override
  double luaL_checknumber(ffi.Pointer<lua_State> L, int arg) {
    return flb.luaL_checknumber(L, arg);
  }

  @override
  int luaL_checkoption(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Char> def, ffi.Pointer<ffi.Pointer<ffi.Char>> lst) {
    return flb.luaL_checkoption(L, arg, def, lst);
  }

  @override
  void luaL_checkstack(ffi.Pointer<lua_State> L, int sz, ffi.Pointer<ffi.Char> msg) {
    flb.luaL_checkstack(L, sz, msg);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_checkstring(ffi.Pointer<lua_State> L, int arg) {
    // luaL_checkstring 是 C 宏，实现为: (luaL_checklstring(L, (narg), NULL))
    return luaL_checklstring(L, arg, ffi.nullptr.cast<ffi.Size>());
  }

  @override
  void luaL_checktype(ffi.Pointer<lua_State> L, int arg, int t) {
    flb.luaL_checktype(L, arg, t);
  }

  @override
  ffi.Pointer<ffi.Void> luaL_checkudata(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Char> tname) {
    return flb.luaL_checkudata(L, arg, tname);
  }

  @override
  void luaL_checkversion(ffi.Pointer<lua_State> L) {
    flb.luaL_checkversion_(L, 504.0, ffi.sizeOf<ffi.Pointer<lua_State>>());
  }

  // ========== 类型转换和工具函数 ==========

  @override
  int luaL_callmeta(ffi.Pointer<lua_State> L, int obj, ffi.Pointer<ffi.Char> e) {
    return flb.luaL_callmeta(L, obj, e);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_tolstring(ffi.Pointer<lua_State> L, int idx, ffi.Pointer<ffi.Size> len) {
    return flb.luaL_tolstring(L, idx, len);
  }

  @override
  int luaL_len(ffi.Pointer<lua_State> L, int index) {
    return flb.luaL_len(L, index);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_gsub(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> s, ffi.Pointer<ffi.Char> p, ffi.Pointer<ffi.Char> r) {
    return flb.luaL_gsub(L, s, p, r);
  }

  // ========== 文件和字符串加载函数 ==========

  @override
  int luaL_dofile(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> filename) {
    // luaL_dofile 是 C 宏，实现为: (luaL_loadfile(L, filename) || lua_pcall(L, 0, LUA_MULTRET, 0))
    final res = luaL_loadfile(L, filename);
    if (res != 0) return res;
    return flb.lua_pcallk(L, 0, -1, 0, 0, ffi.nullptr.cast<ffi.NativeFunction<flb.lua_KFunctionFunction>>());
  }

  @override
  int luaL_dostring(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> str) {
    // luaL_dostring 是 C 宏，实现为: (luaL_loadstring(L, str) || lua_pcall(L, 0, LUA_MULTRET, 0))
    final res = luaL_loadstring(L, str);
    if (res != 0) return res;
    return flb.lua_pcallk(L, 0, -1, 0, 0, ffi.nullptr.cast<ffi.NativeFunction<flb.lua_KFunctionFunction>>());
  }

  @override
  int luaL_loadbuffer(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> buff, int sz, ffi.Pointer<ffi.Char> name) {
    // luaL_loadbuffer 是 C 宏，实现为: luaL_loadbufferx(L, buff, sz, name, NULL)
    return luaL_loadbufferx(L, buff, sz, name, ffi.nullptr);
  }

  @override
  int luaL_loadbufferx(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> buff, int sz, ffi.Pointer<ffi.Char> name, ffi.Pointer<ffi.Char> mode) {
    return flb.luaL_loadbufferx(L, buff, sz, name, mode);
  }

  @override
  int luaL_loadfile(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> filename) {
    // luaL_loadfile 是 C 宏，实现为: luaL_loadfilex(L, filename, NULL)
    return luaL_loadfilex(L, filename, ffi.nullptr);
  }

  @override
  int luaL_loadfilex(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> filename, ffi.Pointer<ffi.Char> mode) {
    return flb.luaL_loadfilex(L, filename, mode);
  }

  @override
  int luaL_loadstring(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> s) {
    return flb.luaL_loadstring(L, s);
  }

  // ========== 元表函数 ==========

  @override
  int luaL_getmetafield(ffi.Pointer<lua_State> L, int obj, ffi.Pointer<ffi.Char> e) {
    return flb.luaL_getmetafield(L, obj, e);
  }

  @override
  int luaL_getmetatable(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> tname) {
    // luaL_getmetatable 是 C 宏，实现为: (lua_getfield(L, LUA_REGISTRYINDEX, (n)))
    return flb.lua_getfield(L, -1001000, tname);  // LUA_REGISTRYINDEX = -1001000
  }

  @override
  int luaL_getsubtable(ffi.Pointer<lua_State> L, int idx, ffi.Pointer<ffi.Char> fname) {
    return flb.luaL_getsubtable(L, idx, fname);
  }

  @override
  int luaL_newmetatable(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> tname) {
    return flb.luaL_newmetatable(L, tname);
  }

  @override
  void luaL_setmetatable(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> tname) {
    flb.luaL_setmetatable(L, tname);
  }

  // ========== 库函数 ==========

  @override
  void luaL_newlib(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Void> l) {
    // luaL_newlib 是 C 宏，实现为: (luaL_newlibtable(L, l), luaL_setfuncs(L, l, 0))
    luaL_newlibtable(L, l);
    luaL_setfuncs(L, l.cast<flb.luaL_Reg>(), 0);
  }

  @override
  void luaL_newlibtable(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Void> l) {
    // luaL_newlibtable 是 C 宏，实现为: lua_createtable(L, 0, sizeof(l)/sizeof((l)[0]) - 1)
    // 由于无法直接计算数组大小，使用估计值
    flb.lua_createtable(L, 0, 16);
  }

  @override
  void luaL_setfuncs(ffi.Pointer<lua_State> L, ffi.Pointer<flb.luaL_Reg> l, int nup) {
    flb.luaL_setfuncs(L, l, nup);
  }

  @override
  void luaL_openlibs(ffi.Pointer<lua_State> L) {
    // luaL_openlibs 是 C 函数，但 FFI 中可能没有
    // 手动打开所有标准库
    flb.luaL_openselectedlibs(L, ~0, ~0);  // 加载所有库
  }

  @override
  void luaL_openselectedlibs(ffi.Pointer<lua_State> L, int load, int preload) {
    flb.luaL_openselectedlibs(L, load, preload);
  }

  @override
  void luaL_requiref(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> modname, lua_CFunction openf, int glb) {
    flb.luaL_requiref(L, modname, openf, glb);
  }

  // ========== 状态和内存函数 ==========

  @override
  ffi.Pointer<lua_State> luaL_newstate() {
    return flb.luaL_newstate();
  }

  @override
  int luaL_makeseed(ffi.Pointer<lua_State> L) {
    return flb.luaL_makeseed(L);
  }

  @override
  int luaL_alloc(ffi.Pointer<ffi.Void> ud, ffi.Pointer<ffi.Void> ptr, int osize, int nsize) {
    return flb.luaL_alloc(ud, ptr, osize, nsize).address;
  }

  // ========== 错误处理函数 ==========

  @override
  int luaL_error(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> fmt) {
    return flb.luaL_error(L, fmt);
  }

  @override
  int luaL_typeerror(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Char> tname) {
    return flb.luaL_typeerror(L, arg, tname);
  }

  @override
  int luaL_fileresult(ffi.Pointer<lua_State> L, int stat, ffi.Pointer<ffi.Char> fname) {
    return flb.luaL_fileresult(L, stat, fname);
  }

  @override
  int luaL_execresult(ffi.Pointer<lua_State> L, int stat) {
    return flb.luaL_execresult(L, stat);
  }

  @override
  void luaL_where(ffi.Pointer<lua_State> L, int lvl) {
    flb.luaL_where(L, lvl);
  }

  @override
  void luaL_traceback(ffi.Pointer<lua_State> L, ffi.Pointer<lua_State> L1, ffi.Pointer<ffi.Char> msg, int level) {
    flb.luaL_traceback(L, L1, msg, level);
  }

  // ========== 可选参数函数 ==========

//   @override
//   int luaL_opt(ffi.Pointer<lua_State> L, int func, int arg, int dflt) {
//     // luaL_opt 是 C 宏，实现为: (lua_isnoneornil(L,(arg)) ? (dflt) : func(L,(arg)))
//     // 这是一个泛型宏，在 Dart 中需要调用者传入已经获取的值
//     // 简化实现：如果 func 不为 0 则返回 func，否则返回 dflt
//     // return func != 0 ? func : dflt;
// flb.luaL_opt
// return _luaCApi.lua_isnoneornil(L,arg);
//   }

  @override
  int luaL_optinteger(ffi.Pointer<lua_State> L, int arg, int d) {
    return flb.luaL_optinteger(L, arg, d);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_optlstring(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Char> d, ffi.Pointer<ffi.Size> l) {
    return flb.luaL_optlstring(L, arg, d, l);
  }

  @override
  double luaL_optnumber(ffi.Pointer<lua_State> L, int arg, double d) {
    return flb.luaL_optnumber(L, arg, d);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_optstring(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Char> d) {
    // luaL_optstring 是 C 宏，实现为: luaL_optlstring(L, (narg), (d), NULL)
    return luaL_optlstring(L, arg, d, ffi.nullptr.cast<ffi.Size>());
  }

  // ========== 引用函数 ==========

  @override
  int luaL_ref(ffi.Pointer<lua_State> L, int t) {
    return flb.luaL_ref(L, t);
  }

  @override
  void luaL_unref(ffi.Pointer<lua_State> L, int t, int ref) {
    flb.luaL_unref(L, t, ref);
  }

  // ========== Userdata 函数 ==========

  @override
  ffi.Pointer<ffi.Void> luaL_testudata(ffi.Pointer<lua_State> L, int arg, ffi.Pointer<ffi.Char> tname) {
    return flb.luaL_testudata(L, arg, tname);
  }

  // ========== 其他函数 ==========

  @override
  void luaL_pushfail(ffi.Pointer<lua_State> L) {
    // luaL_pushfail 是 C 宏，在 Lua 5.4 中实现为: lua_pushnil(L)
    // 在较新版本中可能不同
    flb.lua_pushnil(L);
  }

  @override
  ffi.Pointer<ffi.Char> luaL_typename(ffi.Pointer<lua_State> L, int index) {
    // luaL_typename 是 C 宏，实现为: (lua_typename(L, lua_type(L, (i))))
    final t = flb.lua_type(L, index);
    return flb.lua_typename(L, t);
  }
}
