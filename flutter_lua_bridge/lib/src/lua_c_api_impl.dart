import 'dart:ffi' as ffi;
import 'gen/flutter_lua_bridge.g.dart' as flb;
import 'gen/lua_c_api.dart';

// 从 FFI 绑定中导入类型
typedef lua_State = flb.lua_State;
typedef lua_Debug = flb.lua_Debug;
typedef lua_CFunction = flb.lua_CFunction;
typedef lua_KFunction = flb.lua_KFunction;
typedef lua_Alloc = flb.lua_Alloc;
typedef lua_Hook = flb.lua_Hook;
typedef lua_Reader = flb.lua_Reader;
typedef lua_Writer = flb.lua_Writer;
typedef lua_WarnFunction = flb.lua_WarnFunction;

class LuaCApiImpl implements LuaCApi {
  @override
  int lua_absindex(ffi.Pointer<lua_State> L, int idx) {
    return flb.lua_absindex(L, idx);
  }

  @override
  void lua_arith(ffi.Pointer<lua_State> L, int op) {
    flb.lua_arith(L, op);
  }

  @override
  lua_CFunction lua_atpanic(ffi.Pointer<lua_State> L, lua_CFunction panicf) {
    return flb.lua_atpanic(L, panicf);
  }

  @override
  void lua_call(ffi.Pointer<lua_State> L, int nargs, int nresults) {
    flb.lua_callk(L, nargs, nresults, 0, ffi.nullptr.cast<ffi.NativeFunction<flb.lua_KFunctionFunction>>());
  }

  @override
  void lua_callk(ffi.Pointer<lua_State> L, int nargs, int nresults, int ctx, lua_KFunction k) {
    flb.lua_callk(L, nargs, nresults, ctx, k);
  }

  @override
  int lua_checkstack(ffi.Pointer<lua_State> L, int n) {
    return flb.lua_checkstack(L, n);
  }

  @override
  void lua_close(ffi.Pointer<lua_State> L) {
    flb.lua_close(L);
  }

  @override
  void lua_closeslot(ffi.Pointer<lua_State> L, int index) {
    flb.lua_closeslot(L, index);
  }

  @override
  int lua_closethread(ffi.Pointer<lua_State> L, ffi.Pointer<lua_State> from) {
    return flb.lua_closethread(L, from);
  }

  @override
  int lua_compare(ffi.Pointer<lua_State> L, int index1, int index2, int op) {
    return flb.lua_compare(L, index1, index2, op);
  }

  @override
  void lua_concat(ffi.Pointer<lua_State> L, int n) {
    flb.lua_concat(L, n);
  }

  @override
  void lua_copy(ffi.Pointer<lua_State> L, int fromidx, int toidx) {
    flb.lua_copy(L, fromidx, toidx);
  }

  @override
  void lua_createtable(ffi.Pointer<lua_State> L, int nseq, int nrec) {
    flb.lua_createtable(L, nseq, nrec);
  }

  @override
  int lua_dump(ffi.Pointer<lua_State> L, lua_Writer writer, ffi.Pointer<ffi.Void> data, int strip) {
    return flb.lua_dump(L, writer, data, strip);
  }

  @override
  int lua_error(ffi.Pointer<lua_State> L) {
    return flb.lua_error(L);
  }

  @override
  int lua_gc(ffi.Pointer<lua_State> L, int what) {
    return flb.lua_gc(L, what);
  }

  @override
  lua_Alloc lua_getallocf(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Pointer<ffi.Void>> ud) {
    return flb.lua_getallocf(L, ud);
  }

  @override
  int lua_getextraspace(ffi.Pointer<lua_State> L) {
    return L.address;
  }

  @override
  int lua_getfield(ffi.Pointer<lua_State> L, int index, ffi.Pointer<ffi.Char> k) {
    return flb.lua_getfield(L, index, k);
  }

  @override
  int lua_getglobal(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> name) {
    return flb.lua_getglobal(L, name);
  }

  @override
  lua_Hook lua_gethook(ffi.Pointer<lua_State> L) {
    return flb.lua_gethook(L);
  }

  @override
  int lua_gethookcount(ffi.Pointer<lua_State> L) {
    return flb.lua_gethookcount(L);
  }

  @override
  int lua_gethookmask(ffi.Pointer<lua_State> L) {
    return flb.lua_gethookmask(L);
  }

  @override
  int lua_geti(ffi.Pointer<lua_State> L, int index, int i) {
    return flb.lua_geti(L, index, i);
  }

  @override
  int lua_getinfo(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> what, ffi.Pointer<lua_Debug> ar) {
    return flb.lua_getinfo(L, what, ar);
  }

  @override
  int lua_getiuservalue(ffi.Pointer<lua_State> L, int index, int n) {
    return flb.lua_getiuservalue(L, index, n);
  }

  @override
  int lua_getlocal(ffi.Pointer<lua_State> L, ffi.Pointer<lua_Debug> ar, int n) {
    return flb.lua_getlocal(L, ar, n).address;
  }

  @override
  int lua_getmetatable(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_getmetatable(L, index);
  }

  @override
  int lua_getstack(ffi.Pointer<lua_State> L, int level, ffi.Pointer<lua_Debug> ar) {
    return flb.lua_getstack(L, level, ar);
  }

  @override
  int lua_gettable(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_gettable(L, index);
  }

  @override
  int lua_gettop(ffi.Pointer<lua_State> L) {
    return flb.lua_gettop(L);
  }

  @override
  int lua_getupvalue(ffi.Pointer<lua_State> L, int funcindex, int n) {
    return flb.lua_getupvalue(L, funcindex, n).address;
  }

  @override
  void lua_insert(ffi.Pointer<lua_State> L, int index) {
    flb.lua_rotate(L, index, 1);
  }

  @override
  int lua_isboolean(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return t == 1 ? 1 : 0;
  }

  @override
  int lua_iscfunction(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_iscfunction(L, index);
  }

  @override
  int lua_isfunction(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return (t == 6) ? 1 : 0;
  }

  @override
  int lua_isinteger(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_isinteger(L, index);
  }

  @override
  int lua_islightuserdata(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return (t == 2) ? 1 : 0;
  }

  @override
  int lua_isnil(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return (t == 0) ? 1 : 0;
  }

  @override
  int lua_isnone(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return (t == (-1)) ? 1 : 0;
  }

  @override
  int lua_isnoneornil(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return (t <= 0) ? 1 : 0;
  }

  @override
  int lua_isnumber(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_isnumber(L, index);
  }

  @override
  int lua_isstring(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_isstring(L, index);
  }

  @override
  int lua_istable(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return (t == 7) ? 1 : 0;
  }

  @override
  int lua_isthread(ffi.Pointer<lua_State> L, int index) {
    final t = flb.lua_type(L, index);
    return (t == 8) ? 1 : 0;
  }

  @override
  int lua_isuserdata(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_isuserdata(L, index);
  }

  @override
  int lua_isyieldable(ffi.Pointer<lua_State> L) {
    return flb.lua_isyieldable(L);
  }

  @override
  void lua_len(ffi.Pointer<lua_State> L, int index) {
    flb.lua_len(L, index);
  }

  @override
  int lua_load(ffi.Pointer<lua_State> L, lua_Reader reader, ffi.Pointer<ffi.Void> data, ffi.Pointer<ffi.Char> chunkname, ffi.Pointer<ffi.Char> mode) {
    return flb.lua_load(L, reader, data, chunkname, mode);
  }

  @override
  int lua_newstate(lua_Alloc f, ffi.Pointer<ffi.Void> ud, int seed) {
    return flb.lua_newstate(f, ud, seed).address;
  }

  @override
  void lua_newtable(ffi.Pointer<lua_State> L) {
    flb.lua_createtable(L, 0, 0);
  }

  @override
  int lua_newthread(ffi.Pointer<lua_State> L) {
    return flb.lua_newthread(L).address;
  }

  @override
  int lua_newuserdatauv(ffi.Pointer<lua_State> L, int size, int nuvalue) {
    return flb.lua_newuserdatauv(L, size, nuvalue).address;
  }

  @override
  int lua_next(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_next(L, index);
  }

  @override
  int lua_numbertocstring(ffi.Pointer<lua_State> L, int idx, ffi.Pointer<ffi.Char> buff) {
    return flb.lua_numbertocstring(L, idx, buff);
  }

  @override
  int lua_numbertointeger(double n, ffi.Pointer<lua_Integer> p) {
    final i = n.toInt();
    if (p != ffi.nullptr) {
      p.value = i;
    }
    return 1;
  }

  @override
  int lua_pcall(ffi.Pointer<lua_State> L, int nargs, int nresults, int msgh) {
    return flb.lua_pcallk(L, nargs, nresults, msgh, 0, ffi.nullptr.cast<ffi.NativeFunction<flb.lua_KFunctionFunction>>());
  }

  @override
  int lua_pcallk(ffi.Pointer<lua_State> L, int nargs, int nresults, int msgh, int ctx, lua_KFunction k) {
    return flb.lua_pcallk(L, nargs, nresults, msgh, ctx, k);
  }

  @override
  void lua_pop(ffi.Pointer<lua_State> L, int n) {
    final top = flb.lua_gettop(L);
    flb.lua_settop(L, top - n);
  }

  @override
  void lua_pushboolean(ffi.Pointer<lua_State> L, int b) {
    flb.lua_pushboolean(L, b);
  }

  @override
  void lua_pushcclosure(ffi.Pointer<lua_State> L, lua_CFunction fn, int n) {
    flb.lua_pushcclosure(L, fn, n);
  }

  @override
  void lua_pushcfunction(ffi.Pointer<lua_State> L, lua_CFunction f) {
    flb.lua_pushcclosure(L, f, 0);
  }

  @override
  int lua_pushexternalstring(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> s, int len, lua_Alloc falloc, ffi.Pointer<ffi.Void> ud) {
    return flb.lua_pushexternalstring(L, s, len, falloc, ud).address;
  }

  @override
  int lua_pushfstring(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> fmt) {
    return flb.lua_pushfstring(L, fmt).address;
  }

  @override
  void lua_pushglobaltable(ffi.Pointer<lua_State> L) {
    flb.lua_rawgeti(L, 2, 2);
  }

  @override
  void lua_pushinteger(ffi.Pointer<lua_State> L, int n) {
    flb.lua_pushinteger(L, n);
  }

  @override
  void lua_pushlightuserdata(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Void> p) {
    flb.lua_pushlightuserdata(L, p);
  }

  @override
  int lua_pushliteral(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> s) {
    return flb.lua_pushstring(L, s).address;
  }

  @override
  int lua_pushlstring(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> s, int len) {
    return flb.lua_pushlstring(L, s, len).address;
  }

  @override
  void lua_pushnil(ffi.Pointer<lua_State> L) {
    flb.lua_pushnil(L);
  }

  @override
  void lua_pushnumber(ffi.Pointer<lua_State> L, double n) {
    flb.lua_pushnumber(L, n);
  }

  @override
  int lua_pushstring(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> s) {
    return flb.lua_pushstring(L, s).address;
  }

  @override
  int lua_pushthread(ffi.Pointer<lua_State> L) {
    return flb.lua_pushthread(L);
  }

  @override
  void lua_pushvalue(ffi.Pointer<lua_State> L, int index) {
    flb.lua_pushvalue(L, index);
  }

  @override
  int lua_pushvfstring(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> fmt, ffi.Pointer<va_list$1> argp) {
    return flb.lua_pushfstring(L, fmt).address;
  }

  @override
  int lua_rawequal(ffi.Pointer<lua_State> L, int index1, int index2) {
    return flb.lua_rawequal(L, index1, index2);
  }

  @override
  int lua_rawget(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_rawget(L, index);
  }

  @override
  int lua_rawgeti(ffi.Pointer<lua_State> L, int index, int n) {
    return flb.lua_rawgeti(L, index, n);
  }

  @override
  int lua_rawgetp(ffi.Pointer<lua_State> L, int index, ffi.Pointer<ffi.Void> p) {
    return flb.lua_rawgetp(L, index, p);
  }

  @override
  int lua_rawlen(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_rawlen(L, index);
  }

  @override
  void lua_rawset(ffi.Pointer<lua_State> L, int index) {
    flb.lua_rawset(L, index);
  }

  @override
  void lua_rawseti(ffi.Pointer<lua_State> L, int index, int i) {
    flb.lua_rawseti(L, index, i);
  }

  @override
  void lua_rawsetp(ffi.Pointer<lua_State> L, int index, ffi.Pointer<ffi.Void> p) {
    flb.lua_rawsetp(L, index, p);
  }

  @override
  void lua_register(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> name, lua_CFunction f) {
    flb.lua_pushcclosure(L, f, 0);
    flb.lua_setglobal(L, name);
  }

  @override
  void lua_remove(ffi.Pointer<lua_State> L, int index) {
    flb.lua_rotate(L, index, -1);
    final top = flb.lua_gettop(L);
    flb.lua_settop(L, top - 1);
  }

  @override
  void lua_replace(ffi.Pointer<lua_State> L, int index) {
    flb.lua_copy(L, -1, index);
    final top = flb.lua_gettop(L);
    flb.lua_settop(L, top - 1);
  }

  @override
  int lua_resume(ffi.Pointer<lua_State> L, ffi.Pointer<lua_State> from, int nargs, ffi.Pointer<ffi.Int> nresults) {
    return flb.lua_resume(L, from, nargs, nresults);
  }

  @override
  void lua_rotate(ffi.Pointer<lua_State> L, int idx, int n) {
    flb.lua_rotate(L, idx, n);
  }

  @override
  void lua_setallocf(ffi.Pointer<lua_State> L, lua_Alloc f, ffi.Pointer<ffi.Void> ud) {
    flb.lua_setallocf(L, f, ud);
  }

  @override
  void lua_setfield(ffi.Pointer<lua_State> L, int index, ffi.Pointer<ffi.Char> k) {
    flb.lua_setfield(L, index, k);
  }

  @override
  void lua_setglobal(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> name) {
    flb.lua_setglobal(L, name);
  }

  @override
  void lua_sethook(ffi.Pointer<lua_State> L, lua_Hook f, int mask, int count) {
    flb.lua_sethook(L, f, mask, count);
  }

  @override
  void lua_seti(ffi.Pointer<lua_State> L, int index, int n) {
    flb.lua_seti(L, index, n);
  }

  @override
  int lua_setiuservalue(ffi.Pointer<lua_State> L, int index, int n) {
    return flb.lua_setiuservalue(L, index, n);
  }

  @override
  int lua_setlocal(ffi.Pointer<lua_State> L, ffi.Pointer<lua_Debug> ar, int n) {
    return flb.lua_setlocal(L, ar, n).address;
  }

  @override
  int lua_setmetatable(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_setmetatable(L, index);
  }

  @override
  void lua_settable(ffi.Pointer<lua_State> L, int index) {
    flb.lua_settable(L, index);
  }

  @override
  void lua_settop(ffi.Pointer<lua_State> L, int index) {
    flb.lua_settop(L, index);
  }

  @override
  int lua_setupvalue(ffi.Pointer<lua_State> L, int funcindex, int n) {
    return flb.lua_setupvalue(L, funcindex, n).address;
  }

  @override
  void lua_setwarnf(ffi.Pointer<lua_State> L, lua_WarnFunction f, ffi.Pointer<ffi.Void> ud) {
    flb.lua_setwarnf(L, f, ud);
  }

  @override
  int lua_status(ffi.Pointer<lua_State> L) {
    return flb.lua_status(L);
  }

  @override
  int lua_stringtonumber(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> s) {
    return flb.lua_stringtonumber(L, s);
  }

  @override
  int lua_toboolean(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_toboolean(L, index);
  }

  @override
  lua_CFunction lua_tocfunction(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_tocfunction(L, index);
  }

  @override
  void lua_toclose(ffi.Pointer<lua_State> L, int index) {
    flb.lua_toclose(L, index);
  }

  @override
  int lua_tointeger(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_tointegerx(L, index, ffi.nullptr);
  }

  @override
  int lua_tointegerx(ffi.Pointer<lua_State> L, int index, ffi.Pointer<ffi.Int> isnum) {
    return flb.lua_tointegerx(L, index, isnum);
  }

  @override
  int lua_tolstring(ffi.Pointer<lua_State> L, int index, ffi.Pointer<ffi.Size> len) {
    return flb.lua_tolstring(L, index, len).address;
  }

  @override
  double lua_tonumber(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_tonumberx(L, index, ffi.nullptr);
  }

  @override
  double lua_tonumberx(ffi.Pointer<lua_State> L, int index, ffi.Pointer<ffi.Int> isnum) {
    return flb.lua_tonumberx(L, index, isnum);
  }

  @override
  int lua_topointer(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_topointer(L, index).address;
  }

  @override
  int lua_tostring(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_tolstring(L, index, ffi.nullptr).address;
  }

  @override
  int lua_tothread(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_tothread(L, index).address;
  }

  @override
  int lua_touserdata(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_touserdata(L, index).address;
  }

  @override
  int lua_type(ffi.Pointer<lua_State> L, int index) {
    return flb.lua_type(L, index);
  }

  @override
  int lua_typename(ffi.Pointer<lua_State> L, int tp) {
    return flb.lua_typename(L, tp).address;
  }

  @override
  int lua_upvalueid(ffi.Pointer<lua_State> L, int funcindex, int n) {
    return flb.lua_upvalueid(L, funcindex, n).address;
  }

  @override
  int lua_upvalueindex(int i) {
    return -10002 - i;
  }

  @override
  void lua_upvaluejoin(ffi.Pointer<lua_State> L, int funcindex1, int n1, int funcindex2, int n2) {
    flb.lua_upvaluejoin(L, funcindex1, n1, funcindex2, n2);
  }

  @override
  double lua_version(ffi.Pointer<lua_State> L) {
    return flb.lua_version(L);
  }

  @override
  void lua_warning(ffi.Pointer<lua_State> L, ffi.Pointer<ffi.Char> msg, int tocont) {
    flb.lua_warning(L, msg, tocont);
  }

  @override
  void lua_xmove(ffi.Pointer<lua_State> from, ffi.Pointer<lua_State> to, int n) {
    flb.lua_xmove(from, to, n);
  }

  @override
  int lua_yield(ffi.Pointer<lua_State> L, int nresults) {
    return flb.lua_yieldk(L, nresults, 0, ffi.nullptr.cast<ffi.NativeFunction<flb.lua_KFunctionFunction>>());
  }

  @override
  int lua_yieldk(ffi.Pointer<lua_State> L, int nresults, int ctx, lua_KFunction k) {
    return flb.lua_yieldk(L, nresults, ctx, k);
  }
}
