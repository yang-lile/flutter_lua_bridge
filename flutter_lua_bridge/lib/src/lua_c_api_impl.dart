import 'dart:ffi';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

class LuaCApiImpl implements LuaCApi {
  @override
  Int32 lua_absindex(Pointer<Void> L, Int32 idx) {
    // TODO: implement lua_absindex
    throw UnimplementedError();
  }

  @override
  void lua_arith(Pointer<Void> L, Int32 op) {
    // TODO: implement lua_arith
  }

  @override
  Pointer<NativeFunction<lua_CFunction_Func>> lua_atpanic(
    Pointer<Void> L,
    Pointer<NativeFunction<lua_CFunction_Func>> panicf,
  ) {
    // TODO: implement lua_atpanic
    throw UnimplementedError();
  }

  @override
  void lua_call(Pointer<Void> L, Int32 nargs, Int32 nresults) {
    // TODO: implement lua_call
  }

  @override
  void lua_callk(
    Pointer<Void> L,
    Int32 nargs,
    Int32 nresults,
    IntPtr ctx,
    Pointer<NativeFunction<lua_KFunction_Func>> k,
  ) {
    // TODO: implement lua_callk
  }

  @override
  Int32 lua_checkstack(Pointer<Void> L, Int32 n) {
    // TODO: implement lua_checkstack
    throw UnimplementedError();
  }

  @override
  void lua_close(Pointer<Void> L) {
    // TODO: implement lua_close
  }

  @override
  void lua_closeslot(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_closeslot
  }

  @override
  Int32 lua_closethread(Pointer<Void> L, Pointer<Void> from) {
    // TODO: implement lua_closethread
    throw UnimplementedError();
  }

  @override
  Int32 lua_compare(Pointer<Void> L, Int32 index1, Int32 index2, Int32 op) {
    // TODO: implement lua_compare
    throw UnimplementedError();
  }

  @override
  void lua_concat(Pointer<Void> L, Int32 n) {
    // TODO: implement lua_concat
  }

  @override
  void lua_copy(Pointer<Void> L, Int32 fromidx, Int32 toidx) {
    // TODO: implement lua_copy
  }

  @override
  void lua_createtable(Pointer<Void> L, Int32 nseq, Int32 nrec) {
    // TODO: implement lua_createtable
  }

  @override
  Int32 lua_dump(Pointer<Void> L, Pointer<NativeFunction<lua_Writer_Func>> writer, Pointer<Void> data, Int32 strip) {
    // TODO: implement lua_dump
    throw UnimplementedError();
  }

  @override
  Int32 lua_error(Pointer<Void> L) {
    // TODO: implement lua_error
    throw UnimplementedError();
  }

  @override
  Int32 lua_gc(Pointer<Void> L, Int32 what) {
    // TODO: implement lua_gc
    throw UnimplementedError();
  }

  @override
  Pointer<NativeFunction<lua_Alloc_Func>> lua_getallocf(Pointer<Void> L, Pointer<Void> ud) {
    // TODO: implement lua_getallocf
    throw UnimplementedError();
  }

  @override
  IntPtr lua_getextraspace(Pointer<Void> L) {
    // TODO: implement lua_getextraspace
    throw UnimplementedError();
  }

  @override
  Int32 lua_getfield(Pointer<Void> L, Int32 index, Pointer<Void> k) {
    // TODO: implement lua_getfield
    throw UnimplementedError();
  }

  @override
  Int32 lua_getglobal(Pointer<Void> L, Pointer<Void> name) {
    // TODO: implement lua_getglobal
    throw UnimplementedError();
  }

  @override
  Pointer<NativeFunction<lua_Hook_Func>> lua_gethook(Pointer<Void> L) {
    // TODO: implement lua_gethook
    throw UnimplementedError();
  }

  @override
  Int32 lua_gethookcount(Pointer<Void> L) {
    // TODO: implement lua_gethookcount
    throw UnimplementedError();
  }

  @override
  Int32 lua_gethookmask(Pointer<Void> L) {
    // TODO: implement lua_gethookmask
    throw UnimplementedError();
  }

  @override
  Int32 lua_geti(Pointer<Void> L, Int32 index, Int64 i) {
    // TODO: implement lua_geti
    throw UnimplementedError();
  }

  @override
  Int32 lua_getinfo(Pointer<Void> L, Pointer<Void> what, Pointer<Void> ar) {
    // TODO: implement lua_getinfo
    throw UnimplementedError();
  }

  @override
  Int32 lua_getiuservalue(Pointer<Void> L, Int32 index, Int32 n) {
    // TODO: implement lua_getiuservalue
    throw UnimplementedError();
  }

  @override
  IntPtr lua_getlocal(Pointer<Void> L, Pointer<Void> ar, Int32 n) {
    // TODO: implement lua_getlocal
    throw UnimplementedError();
  }

  @override
  Int32 lua_getmetatable(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_getmetatable
    throw UnimplementedError();
  }

  @override
  Int32 lua_getstack(Pointer<Void> L, Int32 level, Pointer<Void> ar) {
    // TODO: implement lua_getstack
    throw UnimplementedError();
  }

  @override
  Int32 lua_gettable(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_gettable
    throw UnimplementedError();
  }

  @override
  Int32 lua_gettop(Pointer<Void> L) {
    // TODO: implement lua_gettop
    throw UnimplementedError();
  }

  @override
  IntPtr lua_getupvalue(Pointer<Void> L, Int32 funcindex, Int32 n) {
    // TODO: implement lua_getupvalue
    throw UnimplementedError();
  }

  @override
  void lua_insert(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_insert
  }

  @override
  Int32 lua_isboolean(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isboolean
    throw UnimplementedError();
  }

  @override
  Int32 lua_iscfunction(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_iscfunction
    throw UnimplementedError();
  }

  @override
  Int32 lua_isfunction(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isfunction
    throw UnimplementedError();
  }

  @override
  Int32 lua_isinteger(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isinteger
    throw UnimplementedError();
  }

  @override
  Int32 lua_islightuserdata(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_islightuserdata
    throw UnimplementedError();
  }

  @override
  Int32 lua_isnil(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isnil
    throw UnimplementedError();
  }

  @override
  Int32 lua_isnone(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isnone
    throw UnimplementedError();
  }

  @override
  Int32 lua_isnoneornil(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isnoneornil
    throw UnimplementedError();
  }

  @override
  Int32 lua_isnumber(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isnumber
    throw UnimplementedError();
  }

  @override
  Int32 lua_isstring(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isstring
    throw UnimplementedError();
  }

  @override
  Int32 lua_istable(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_istable
    throw UnimplementedError();
  }

  @override
  Int32 lua_isthread(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isthread
    throw UnimplementedError();
  }

  @override
  Int32 lua_isuserdata(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_isuserdata
    throw UnimplementedError();
  }

  @override
  Int32 lua_isyieldable(Pointer<Void> L) {
    // TODO: implement lua_isyieldable
    throw UnimplementedError();
  }

  @override
  void lua_len(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_len
  }

  @override
  Int32 lua_load(
    Pointer<Void> L,
    Pointer<NativeFunction<lua_Reader_Func>> reader,
    Pointer<Void> data,
    Pointer<Void> chunkname,
    Pointer<Void> mode,
  ) {
    // TODO: implement lua_load
    throw UnimplementedError();
  }

  @override
  IntPtr lua_newstate(Pointer<NativeFunction<lua_Alloc_Func>> f, Pointer<Void> ud, Uint32 seed) {
    // TODO: implement lua_newstate
    throw UnimplementedError();
  }

  @override
  void lua_newtable(Pointer<Void> L) {
    // TODO: implement lua_newtable
  }

  @override
  IntPtr lua_newthread(Pointer<Void> L) {
    // TODO: implement lua_newthread
    throw UnimplementedError();
  }

  @override
  IntPtr lua_newuserdatauv(Pointer<Void> L, IntPtr size, Int32 nuvalue) {
    // TODO: implement lua_newuserdatauv
    throw UnimplementedError();
  }

  @override
  Int32 lua_next(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_next
    throw UnimplementedError();
  }

  @override
  IntPtr lua_numbertocstring(Pointer<Void> L, Int32 idx, Pointer<Void> buff) {
    // TODO: implement lua_numbertocstring
    throw UnimplementedError();
  }

  @override
  Int32 lua_numbertointeger(Double n, Pointer<Void> p) {
    // TODO: implement lua_numbertointeger
    throw UnimplementedError();
  }

  @override
  Int32 lua_pcall(Pointer<Void> L, Int32 nargs, Int32 nresults, Int32 msgh) {
    // TODO: implement lua_pcall
    throw UnimplementedError();
  }

  @override
  Int32 lua_pcallk(
    Pointer<Void> L,
    Int32 nargs,
    Int32 nresults,
    Int32 msgh,
    IntPtr ctx,
    Pointer<NativeFunction<lua_KFunction_Func>> k,
  ) {
    // TODO: implement lua_pcallk
    throw UnimplementedError();
  }

  @override
  void lua_pop(Pointer<Void> L, Int32 n) {
    // TODO: implement lua_pop
  }

  @override
  void lua_pushboolean(Pointer<Void> L, Int32 b) {
    // TODO: implement lua_pushboolean
  }

  @override
  void lua_pushcclosure(Pointer<Void> L, Pointer<NativeFunction<lua_CFunction_Func>> fn, Int32 n) {
    // TODO: implement lua_pushcclosure
  }

  @override
  void lua_pushcfunction(Pointer<Void> L, Pointer<NativeFunction<lua_CFunction_Func>> f) {
    // TODO: implement lua_pushcfunction
  }

  @override
  IntPtr lua_pushexternalstring(
    Pointer<Void> L,
    Pointer<Void> s,
    IntPtr len,
    Pointer<NativeFunction<lua_Alloc_Func>> falloc,
    Pointer<Void> ud,
  ) {
    // TODO: implement lua_pushexternalstring
    throw UnimplementedError();
  }

  @override
  IntPtr lua_pushfstring(Pointer<Void> L, Pointer<Void> fmt) {
    // TODO: implement lua_pushfstring
    throw UnimplementedError();
  }

  @override
  void lua_pushglobaltable(Pointer<Void> L) {
    // TODO: implement lua_pushglobaltable
  }

  @override
  void lua_pushinteger(Pointer<Void> L, Int64 n) {
    // TODO: implement lua_pushinteger
  }

  @override
  void lua_pushlightuserdata(Pointer<Void> L, Pointer<Void> p) {
    // TODO: implement lua_pushlightuserdata
  }

  @override
  IntPtr lua_pushliteral(Pointer<Void> L, Pointer<Void> s) {
    // TODO: implement lua_pushliteral
    throw UnimplementedError();
  }

  @override
  IntPtr lua_pushlstring(Pointer<Void> L, Pointer<Void> s, IntPtr len) {
    // TODO: implement lua_pushlstring
    throw UnimplementedError();
  }

  @override
  void lua_pushnil(Pointer<Void> L) {
    // TODO: implement lua_pushnil
  }

  @override
  void lua_pushnumber(Pointer<Void> L, Double n) {
    // TODO: implement lua_pushnumber
  }

  @override
  IntPtr lua_pushstring(Pointer<Void> L, Pointer<Void> s) {
    // TODO: implement lua_pushstring
    throw UnimplementedError();
  }

  @override
  Int32 lua_pushthread(Pointer<Void> L) {
    // TODO: implement lua_pushthread
    throw UnimplementedError();
  }

  @override
  void lua_pushvalue(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_pushvalue
  }

  @override
  IntPtr lua_pushvfstring(Pointer<Void> L, Pointer<Void> fmt, Pointer<VarArgs<Record>> argp) {
    // TODO: implement lua_pushvfstring
    throw UnimplementedError();
  }

  @override
  Int32 lua_rawequal(Pointer<Void> L, Int32 index1, Int32 index2) {
    // TODO: implement lua_rawequal
    throw UnimplementedError();
  }

  @override
  Int32 lua_rawget(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_rawget
    throw UnimplementedError();
  }

  @override
  Int32 lua_rawgeti(Pointer<Void> L, Int32 index, Int64 n) {
    // TODO: implement lua_rawgeti
    throw UnimplementedError();
  }

  @override
  Int32 lua_rawgetp(Pointer<Void> L, Int32 index, Pointer<Void> p) {
    // TODO: implement lua_rawgetp
    throw UnimplementedError();
  }

  @override
  Uint64 lua_rawlen(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_rawlen
    throw UnimplementedError();
  }

  @override
  void lua_rawset(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_rawset
  }

  @override
  void lua_rawseti(Pointer<Void> L, Int32 index, Int64 i) {
    // TODO: implement lua_rawseti
  }

  @override
  void lua_rawsetp(Pointer<Void> L, Int32 index, Pointer<Void> p) {
    // TODO: implement lua_rawsetp
  }

  @override
  void lua_register(Pointer<Void> L, Pointer<Void> name, Pointer<NativeFunction<lua_CFunction_Func>> f) {
    // TODO: implement lua_register
  }

  @override
  void lua_remove(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_remove
  }

  @override
  void lua_replace(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_replace
  }

  @override
  Int32 lua_resume(Pointer<Void> L, Pointer<Void> from, Int32 nargs, Pointer<Void> nresults) {
    // TODO: implement lua_resume
    throw UnimplementedError();
  }

  @override
  void lua_rotate(Pointer<Void> L, Int32 idx, Int32 n) {
    // TODO: implement lua_rotate
  }

  @override
  void lua_setallocf(Pointer<Void> L, Pointer<NativeFunction<lua_Alloc_Func>> f, Pointer<Void> ud) {
    // TODO: implement lua_setallocf
  }

  @override
  void lua_setfield(Pointer<Void> L, Int32 index, Pointer<Void> k) {
    // TODO: implement lua_setfield
  }

  @override
  void lua_setglobal(Pointer<Void> L, Pointer<Void> name) {
    // TODO: implement lua_setglobal
  }

  @override
  void lua_sethook(Pointer<Void> L, Pointer<NativeFunction<lua_Hook_Func>> f, Int32 mask, Int32 count) {
    // TODO: implement lua_sethook
  }

  @override
  void lua_seti(Pointer<Void> L, Int32 index, Int64 n) {
    // TODO: implement lua_seti
  }

  @override
  Int32 lua_setiuservalue(Pointer<Void> L, Int32 index, Int32 n) {
    // TODO: implement lua_setiuservalue
    throw UnimplementedError();
  }

  @override
  IntPtr lua_setlocal(Pointer<Void> L, Pointer<Void> ar, Int32 n) {
    // TODO: implement lua_setlocal
    throw UnimplementedError();
  }

  @override
  Int32 lua_setmetatable(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_setmetatable
    throw UnimplementedError();
  }

  @override
  void lua_settable(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_settable
  }

  @override
  void lua_settop(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_settop
  }

  @override
  IntPtr lua_setupvalue(Pointer<Void> L, Int32 funcindex, Int32 n) {
    // TODO: implement lua_setupvalue
    throw UnimplementedError();
  }

  @override
  void lua_setwarnf(Pointer<Void> L, Pointer<NativeFunction<lua_WarnFunction_Func>> f, Pointer<Void> ud) {
    // TODO: implement lua_setwarnf
  }

  @override
  Int32 lua_status(Pointer<Void> L) {
    // TODO: implement lua_status
    throw UnimplementedError();
  }

  @override
  IntPtr lua_stringtonumber(Pointer<Void> L, Pointer<Void> s) {
    // TODO: implement lua_stringtonumber
    throw UnimplementedError();
  }

  @override
  Int32 lua_toboolean(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_toboolean
    throw UnimplementedError();
  }

  @override
  Pointer<NativeFunction<lua_CFunction_Func>> lua_tocfunction(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_tocfunction
    throw UnimplementedError();
  }

  @override
  void lua_toclose(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_toclose
  }

  @override
  Int64 lua_tointeger(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_tointeger
    throw UnimplementedError();
  }

  @override
  Int64 lua_tointegerx(Pointer<Void> L, Int32 index, Pointer<Void> isnum) {
    // TODO: implement lua_tointegerx
    throw UnimplementedError();
  }

  @override
  IntPtr lua_tolstring(Pointer<Void> L, Int32 index, Pointer<Void> len) {
    // TODO: implement lua_tolstring
    throw UnimplementedError();
  }

  @override
  Double lua_tonumber(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_tonumber
    throw UnimplementedError();
  }

  @override
  Double lua_tonumberx(Pointer<Void> L, Int32 index, Pointer<Void> isnum) {
    // TODO: implement lua_tonumberx
    throw UnimplementedError();
  }

  @override
  IntPtr lua_topointer(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_topointer
    throw UnimplementedError();
  }

  @override
  IntPtr lua_tostring(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_tostring
    throw UnimplementedError();
  }

  @override
  IntPtr lua_tothread(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_tothread
    throw UnimplementedError();
  }

  @override
  IntPtr lua_touserdata(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_touserdata
    throw UnimplementedError();
  }

  @override
  Int32 lua_type(Pointer<Void> L, Int32 index) {
    // TODO: implement lua_type
    throw UnimplementedError();
  }

  @override
  IntPtr lua_typename(Pointer<Void> L, Int32 tp) {
    // TODO: implement lua_typename
    throw UnimplementedError();
  }

  @override
  IntPtr lua_upvalueid(Pointer<Void> L, Int32 funcindex, Int32 n) {
    // TODO: implement lua_upvalueid
    throw UnimplementedError();
  }

  @override
  Int32 lua_upvalueindex(Int32 i) {
    // TODO: implement lua_upvalueindex
    throw UnimplementedError();
  }

  @override
  void lua_upvaluejoin(Pointer<Void> L, Int32 funcindex1, Int32 n1, Int32 funcindex2, Int32 n2) {
    // TODO: implement lua_upvaluejoin
  }

  @override
  Double lua_version(Pointer<Void> L) {
    // TODO: implement lua_version
    throw UnimplementedError();
  }

  @override
  void lua_warning(Pointer<Void> L, Pointer<Void> msg, Int32 tocont) {
    // TODO: implement lua_warning
  }

  @override
  void lua_xmove(Pointer<Void> from, Pointer<Void> to, Int32 n) {
    // TODO: implement lua_xmove
  }

  @override
  Int32 lua_yield(Pointer<Void> L, Int32 nresults) {
    // TODO: implement lua_yield
    throw UnimplementedError();
  }

  @override
  Int32 lua_yieldk(Pointer<Void> L, Int32 nresults, IntPtr ctx, Pointer<NativeFunction<lua_KFunction_Func>> k) {
    // TODO: implement lua_yieldk
    throw UnimplementedError();
  }
}
