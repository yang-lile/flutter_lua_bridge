import 'dart:ffi';

import 'package:ffi/src/utf8.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

class LuaAuxApiImpl implements LuaAuxApi {
  @override
  void luaL_addchar(Pointer<Void> B, Int8 c) {
    // TODO: implement luaL_addchar
  }

  @override
  IntPtr luaL_addgsub(Pointer<Void> B, Pointer<Void> s, Pointer<Void> p, Pointer<Void> r) {
    // TODO: implement luaL_addgsub
    throw UnimplementedError();
  }

  @override
  void luaL_addlstring(Pointer<Void> B, Pointer<Void> s, IntPtr l) {
    // TODO: implement luaL_addlstring
  }

  @override
  void luaL_addsize(Pointer<Void> B, IntPtr n) {
    // TODO: implement luaL_addsize
  }

  @override
  void luaL_addstring(Pointer<Void> B, Pointer<Void> s) {
    // TODO: implement luaL_addstring
  }

  @override
  void luaL_addvalue(Pointer<Void> B) {
    // TODO: implement luaL_addvalue
  }

  @override
  IntPtr luaL_alloc(Pointer<Void> ud, Pointer<Void> ptr, IntPtr osize, IntPtr nsize) {
    // TODO: implement luaL_alloc
    throw UnimplementedError();
  }

  @override
  void luaL_argcheck(Pointer<Void> L, Int32 cond, Int32 arg, Pointer<Void> extramsg) {
    // TODO: implement luaL_argcheck
  }

  @override
  Int32 luaL_argerror(Pointer<Void> L, Int32 arg, Pointer<Void> extramsg) {
    // TODO: implement luaL_argerror
    throw UnimplementedError();
  }

  @override
  void luaL_argexpected(Pointer<Void> L, Int32 cond, Int32 arg, Pointer<Void> tname) {
    // TODO: implement luaL_argexpected
  }

  @override
  IntPtr luaL_buffaddr(Pointer<Void> B) {
    // TODO: implement luaL_buffaddr
    throw UnimplementedError();
  }

  @override
  void luaL_buffinit(Pointer<Void> L, Pointer<Void> B) {
    // TODO: implement luaL_buffinit
  }

  @override
  IntPtr luaL_buffinitsize(Pointer<Void> L, Pointer<Void> B, IntPtr sz) {
    // TODO: implement luaL_buffinitsize
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_bufflen(Pointer<Void> B) {
    // TODO: implement luaL_bufflen
    throw UnimplementedError();
  }

  @override
  void luaL_buffsub(Pointer<Void> B, Int32 n) {
    // TODO: implement luaL_buffsub
  }

  @override
  Int32 luaL_callmeta(Pointer<Void> L, Int32 obj, Pointer<Void> e) {
    // TODO: implement luaL_callmeta
    throw UnimplementedError();
  }

  @override
  void luaL_checkany(Pointer<Void> L, Int32 arg) {
    // TODO: implement luaL_checkany
  }

  @override
  Int64 luaL_checkinteger(Pointer<Void> L, Int32 arg) {
    // TODO: implement luaL_checkinteger
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_checklstring(Pointer<Void> L, Int32 arg, Pointer<Void> l) {
    // TODO: implement luaL_checklstring
    throw UnimplementedError();
  }

  @override
  Double luaL_checknumber(Pointer<Void> L, Int32 arg) {
    // TODO: implement luaL_checknumber
    throw UnimplementedError();
  }

  @override
  Int32 luaL_checkoption(Pointer<Void> L, Int32 arg, Pointer<Void> def, Pointer<Pointer<Utf8>> lst) {
    // TODO: implement luaL_checkoption
    throw UnimplementedError();
  }

  @override
  void luaL_checkstack(Pointer<Void> L, Int32 sz, Pointer<Void> msg) {
    // TODO: implement luaL_checkstack
  }

  @override
  IntPtr luaL_checkstring(Pointer<Void> L, Int32 arg) {
    // TODO: implement luaL_checkstring
    throw UnimplementedError();
  }

  @override
  void luaL_checktype(Pointer<Void> L, Int32 arg, Int32 t) {
    // TODO: implement luaL_checktype
  }

  @override
  IntPtr luaL_checkudata(Pointer<Void> L, Int32 arg, Pointer<Void> tname) {
    // TODO: implement luaL_checkudata
    throw UnimplementedError();
  }

  @override
  void luaL_checkversion(Pointer<Void> L) {
    // TODO: implement luaL_checkversion
  }

  @override
  Int32 luaL_dofile(Pointer<Void> L, Pointer<Void> filename) {
    // TODO: implement luaL_dofile
    throw UnimplementedError();
  }

  @override
  Int32 luaL_dostring(Pointer<Void> L, Pointer<Void> str) {
    // TODO: implement luaL_dostring
    throw UnimplementedError();
  }

  @override
  Int32 luaL_error(Pointer<Void> L, Pointer<Void> fmt) {
    // TODO: implement luaL_error
    throw UnimplementedError();
  }

  @override
  Int32 luaL_execresult(Pointer<Void> L, Int32 stat) {
    // TODO: implement luaL_execresult
    throw UnimplementedError();
  }

  @override
  Int32 luaL_fileresult(Pointer<Void> L, Int32 stat, Pointer<Void> fname) {
    // TODO: implement luaL_fileresult
    throw UnimplementedError();
  }

  @override
  Int32 luaL_getmetafield(Pointer<Void> L, Int32 obj, Pointer<Void> e) {
    // TODO: implement luaL_getmetafield
    throw UnimplementedError();
  }

  @override
  Int32 luaL_getmetatable(Pointer<Void> L, Pointer<Void> tname) {
    // TODO: implement luaL_getmetatable
    throw UnimplementedError();
  }

  @override
  Int32 luaL_getsubtable(Pointer<Void> L, Int32 idx, Pointer<Void> fname) {
    // TODO: implement luaL_getsubtable
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_gsub(Pointer<Void> L, Pointer<Void> s, Pointer<Void> p, Pointer<Void> r) {
    // TODO: implement luaL_gsub
    throw UnimplementedError();
  }

  @override
  Int64 luaL_len(Pointer<Void> L, Int32 index) {
    // TODO: implement luaL_len
    throw UnimplementedError();
  }

  @override
  Int32 luaL_loadbuffer(Pointer<Void> L, Pointer<Void> buff, IntPtr sz, Pointer<Void> name) {
    // TODO: implement luaL_loadbuffer
    throw UnimplementedError();
  }

  @override
  Int32 luaL_loadbufferx(Pointer<Void> L, Pointer<Void> buff, IntPtr sz, Pointer<Void> name, Pointer<Void> mode) {
    // TODO: implement luaL_loadbufferx
    throw UnimplementedError();
  }

  @override
  Int32 luaL_loadfile(Pointer<Void> L, Pointer<Void> filename) {
    // TODO: implement luaL_loadfile
    throw UnimplementedError();
  }

  @override
  Int32 luaL_loadfilex(Pointer<Void> L, Pointer<Void> filename, Pointer<Void> mode) {
    // TODO: implement luaL_loadfilex
    throw UnimplementedError();
  }

  @override
  Int32 luaL_loadstring(Pointer<Void> L, Pointer<Void> s) {
    // TODO: implement luaL_loadstring
    throw UnimplementedError();
  }

  @override
  Uint32 luaL_makeseed(Pointer<Void> L) {
    // TODO: implement luaL_makeseed
    throw UnimplementedError();
  }

  @override
  void luaL_newlib(Pointer<Void> L, Pointer<Void> l) {
    // TODO: implement luaL_newlib
  }

  @override
  void luaL_newlibtable(Pointer<Void> L, Pointer<Void> l) {
    // TODO: implement luaL_newlibtable
  }

  @override
  Int32 luaL_newmetatable(Pointer<Void> L, Pointer<Void> tname) {
    // TODO: implement luaL_newmetatable
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_newstate() {
    // TODO: implement luaL_newstate
    throw UnimplementedError();
  }

  @override
  void luaL_openlibs(Pointer<Void> L) {
    // TODO: implement luaL_openlibs
  }

  @override
  void luaL_openselectedlibs(Pointer<Void> L, Int32 load, Int32 preload) {
    // TODO: implement luaL_openselectedlibs
  }

  @override
  IntPtr luaL_opt(IntPtr L, IntPtr func, IntPtr arg, IntPtr dflt) {
    // TODO: implement luaL_opt
    throw UnimplementedError();
  }

  @override
  Int64 luaL_optinteger(Pointer<Void> L, Int32 arg, Int64 d) {
    // TODO: implement luaL_optinteger
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_optlstring(Pointer<Void> L, Int32 arg, Pointer<Void> d, Pointer<Void> l) {
    // TODO: implement luaL_optlstring
    throw UnimplementedError();
  }

  @override
  Double luaL_optnumber(Pointer<Void> L, Int32 arg, Double d) {
    // TODO: implement luaL_optnumber
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_optstring(Pointer<Void> L, Int32 arg, Pointer<Void> d) {
    // TODO: implement luaL_optstring
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_prepbuffer(Pointer<Void> B) {
    // TODO: implement luaL_prepbuffer
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_prepbuffsize(Pointer<Void> B, IntPtr sz) {
    // TODO: implement luaL_prepbuffsize
    throw UnimplementedError();
  }

  @override
  void luaL_pushfail(Pointer<Void> L) {
    // TODO: implement luaL_pushfail
  }

  @override
  void luaL_pushresult(Pointer<Void> B) {
    // TODO: implement luaL_pushresult
  }

  @override
  void luaL_pushresultsize(Pointer<Void> B, IntPtr sz) {
    // TODO: implement luaL_pushresultsize
  }

  @override
  Int32 luaL_ref(Pointer<Void> L, Int32 t) {
    // TODO: implement luaL_ref
    throw UnimplementedError();
  }

  @override
  void luaL_requiref(
    Pointer<Void> L,
    Pointer<Void> modname,
    Pointer<NativeFunction<lua_CFunction_Func>> openf,
    Int32 glb,
  ) {
    // TODO: implement luaL_requiref
  }

  @override
  void luaL_setfuncs(Pointer<Void> L, Pointer<Void> l, Int32 nup) {
    // TODO: implement luaL_setfuncs
  }

  @override
  void luaL_setmetatable(Pointer<Void> L, Pointer<Void> tname) {
    // TODO: implement luaL_setmetatable
  }

  @override
  IntPtr luaL_testudata(Pointer<Void> L, Int32 arg, Pointer<Void> tname) {
    // TODO: implement luaL_testudata
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_tolstring(Pointer<Void> L, Int32 idx, Pointer<Void> len) {
    // TODO: implement luaL_tolstring
    throw UnimplementedError();
  }

  @override
  void luaL_traceback(Pointer<Void> L, Pointer<Void> L1, Pointer<Void> msg, Int32 level) {
    // TODO: implement luaL_traceback
  }

  @override
  Int32 luaL_typeerror(Pointer<Void> L, Int32 arg, Pointer<Void> tname) {
    // TODO: implement luaL_typeerror
    throw UnimplementedError();
  }

  @override
  IntPtr luaL_typename(Pointer<Void> L, Int32 index) {
    // TODO: implement luaL_typename
    throw UnimplementedError();
  }

  @override
  void luaL_unref(Pointer<Void> L, Int32 t, Int32 ref) {
    // TODO: implement luaL_unref
  }

  @override
  void luaL_where(Pointer<Void> L, Int32 lvl) {
    // TODO: implement luaL_where
  }
}
