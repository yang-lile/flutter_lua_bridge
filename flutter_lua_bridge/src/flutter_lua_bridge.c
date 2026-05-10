#include "flutter_lua_bridge.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

const int kLuaVersionReleaseNum = LUA_VERSION_RELEASE_NUM;
const int kLuaRegistryIndex = LUA_REGISTRYINDEX;

/* ================================================================
 * C API 函数实现
 * ================================================================ */

int flutter_lua_bridge_absindex(lua_State* L, int idx) {
    return lua_absindex(L, idx);
}

void flutter_lua_bridge_arith(lua_State* L, int op) {
    lua_arith(L, (int)op);
}

void* flutter_lua_bridge_atpanic(lua_State* L, void* panicf) {
    return lua_atpanic(L, panicf);
}

void flutter_lua_bridge_call(lua_State* L, int nargs, int nresults) {
    lua_call(L, nargs, nresults);
}

void flutter_lua_bridge_callk(lua_State* L, int nargs, int nresults, int ctx, void* k) {
    lua_callk(L, nargs, nresults, (lua_KContext)ctx, (lua_KFunction)k);
}

int flutter_lua_bridge_checkstack(lua_State* L, int n) {
    return lua_checkstack(L, n);
}

void flutter_lua_bridge_close(lua_State* L) {
    lua_close(L);
}

int flutter_lua_bridge_closeslot(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 504
    lua_closeslot(L, idx);
    return 0;
#else
    return 0;
#endif
}

int flutter_lua_bridge_closethread(lua_State* L, lua_State* from) {
#if LUA_VERSION_NUM >= 505
    return lua_closethread(L, from);
#else
    return 0;
#endif
}

int flutter_lua_bridge_compare(lua_State* L, int idx1, int idx2, int op) {
    return lua_compare(L, idx1, idx2, (int)op);
}

void flutter_lua_bridge_concat(lua_State* L, int n) {
    lua_concat(L, n);
}

void flutter_lua_bridge_copy(lua_State* L, int fromidx, int toidx) {
    lua_copy(L, fromidx, toidx);
}

void flutter_lua_bridge_createtable(lua_State* L, int nseq, int nrec) {
    lua_createtable(L, nseq, nrec);
}

int flutter_lua_bridge_dump(lua_State* L, void* writer, void* data, int strip) {
    return lua_dump(L, writer, data, strip);
}

int flutter_lua_bridge_error(lua_State* L) {
    return (int)lua_error(L);
}

int flutter_lua_bridge_gc(lua_State* L, int what, int data) {
    return lua_gc(L, what, data);
}

void* flutter_lua_bridge_getallocf(lua_State* L, void** ud) {
    return lua_getallocf(L, ud);
}

void* flutter_lua_bridge_getextraspace(lua_State* L) {
    return lua_getextraspace(L);
}

int flutter_lua_bridge_getfield(lua_State* L, int idx, const char* k) {
    return lua_getfield(L, idx, k);
}

int flutter_lua_bridge_getglobal(lua_State* L, const char* name) {
    return lua_getglobal(L, name);
}

void* flutter_lua_bridge_gethook(lua_State* L) {
    return lua_gethook(L);
}

int flutter_lua_bridge_gethookcount(lua_State* L) {
    return lua_gethookcount(L);
}

int flutter_lua_bridge_gethookmask(lua_State* L) {
    return lua_gethookmask(L);
}

int flutter_lua_bridge_geti(lua_State* L, int idx, int64_t n) {
    return lua_geti(L, idx, (lua_Integer)n);
}

int flutter_lua_bridge_getinfo(lua_State* L, const char* what, void* ar) {
    return lua_getinfo(L, what, (lua_Debug*)ar);
}

void flutter_lua_bridge_getiuservalue(lua_State* L, int idx, int n) {
#if LUA_VERSION_NUM >= 504
    lua_getiuservalue(L, idx, n);
#else
    (void)idx;
    (void)n;
#endif
}

const char* flutter_lua_bridge_getlocal(lua_State* L, void* ar, int n) {
    return lua_getlocal(L, (lua_Debug*)ar, n);
}

int flutter_lua_bridge_getmetatable(lua_State* L, int objindex) {
    return lua_getmetatable(L, objindex);
}

int flutter_lua_bridge_getstack(lua_State* L, int level, void* ar) {
    return lua_getstack(L, level, (lua_Debug*)ar);
}

int flutter_lua_bridge_gettable(lua_State* L, int idx) {
    return lua_gettable(L, idx);
}

int flutter_lua_bridge_gettop(lua_State* L) {
    return lua_gettop(L);
}

const char* flutter_lua_bridge_getupvalue(lua_State* L, int funcindex, int n) {
    return lua_getupvalue(L, funcindex, n);
}

int flutter_lua_bridge_getuservalue(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 503
    return lua_getuservalue(L, idx);
#else
    (void)idx;
    return 0;
#endif
}

void flutter_lua_bridge_insert(lua_State* L, int idx) {
    lua_insert(L, idx);
}

int flutter_lua_bridge_isboolean(lua_State* L, int idx) {
    return lua_isboolean(L, idx);
}

int flutter_lua_bridge_iscfunction(lua_State* L, int idx) {
    return lua_iscfunction(L, idx);
}

int flutter_lua_bridge_isfunction(lua_State* L, int idx) {
    return lua_isfunction(L, idx);
}

int flutter_lua_bridge_isinteger(lua_State* L, int idx) {
    return lua_isinteger(L, idx);
}

int flutter_lua_bridge_islightuserdata(lua_State* L, int idx) {
    return lua_islightuserdata(L, idx);
}

int flutter_lua_bridge_isnil(lua_State* L, int idx) {
    return lua_isnil(L, idx);
}

int flutter_lua_bridge_isnone(lua_State* L, int idx) {
    return lua_isnone(L, idx);
}

int flutter_lua_bridge_isnoneornil(lua_State* L, int idx) {
    return lua_isnoneornil(L, idx);
}

int flutter_lua_bridge_isnumber(lua_State* L, int idx) {
    return lua_isnumber(L, idx);
}

int flutter_lua_bridge_isstring(lua_State* L, int idx) {
    return lua_isstring(L, idx);
}

int flutter_lua_bridge_istable(lua_State* L, int idx) {
    return lua_istable(L, idx);
}

int flutter_lua_bridge_isthread(lua_State* L, int idx) {
    return lua_isthread(L, idx);
}

int flutter_lua_bridge_isuserdata(lua_State* L, int idx) {
    return lua_isuserdata(L, idx);
}

int flutter_lua_bridge_isyieldable(lua_State* L) {
    return lua_isyieldable(L);
}

void flutter_lua_bridge_len(lua_State* L, int idx) {
    lua_len(L, idx);
}

int flutter_lua_bridge_load(lua_State* L, void* reader, void* dt, const char* chunkname, const char* mode) {
    return (int)lua_load(L, reader, dt, chunkname, mode);
}

lua_State* flutter_lua_bridge_newstate(void* f, void* ud) {
    return lua_newstate(f, ud);
}

void flutter_lua_bridge_newtable(lua_State* L) {
    lua_newtable(L);
}

lua_State* flutter_lua_bridge_newthread(lua_State* L) {
    return lua_newthread(L);
}

void* flutter_lua_bridge_newuserdata(lua_State* L, size_t sz) {
    return lua_newuserdata(L, sz);
}

void* flutter_lua_bridge_newuserdatauv(lua_State* L, size_t sz, int nuvalue) {
#if LUA_VERSION_NUM >= 504
    return lua_newuserdatauv(L, sz, nuvalue);
#else
    return lua_newuserdata(L, sz);
#endif
}

int flutter_lua_bridge_next(lua_State* L, int idx) {
    return lua_next(L, idx);
}

const char* flutter_lua_bridge_numbertocstring(lua_State* L, double n, size_t* len) {
#if LUA_VERSION_NUM >= 505
    return lua_numbertocstring(L, n, len);
#else
    (void)L;
    (void)n;
    (void)len;
    return NULL;
#endif
}

int flutter_lua_bridge_numbertointeger(double n, int64_t* p) {
    return lua_numbertointeger(n, (lua_Integer*)p);
}

int flutter_lua_bridge_pcall(lua_State* L, int nargs, int nresults, int errfunc) {
    return lua_pcall(L, nargs, nresults, errfunc);
}

int flutter_lua_bridge_pcallk(lua_State* L, int nargs, int nresults, int errfunc, int ctx, void* k) {
    return lua_pcallk(L, nargs, nresults, errfunc, (lua_KContext)ctx, (lua_KFunction)k);
}

void flutter_lua_bridge_pop(lua_State* L, int n) {
    lua_pop(L, n);
}

void flutter_lua_bridge_pushboolean(lua_State* L, int b) {
    lua_pushboolean(L, b);
}

void flutter_lua_bridge_pushcclosure(lua_State* L, void* fn, int n) {
    lua_pushcclosure(L, (lua_CFunction)fn, n);
}

void flutter_lua_bridge_pushcfunction(lua_State* L, void* f) {
    lua_pushcfunction(L, (lua_CFunction)f);
}

const char* flutter_lua_bridge_pushexternalstring(lua_State* L, const char* s, size_t len, void* falloc, void* ud) {
#if LUA_VERSION_NUM >= 505
    return lua_pushexternalstring(L, s, len, (lua_Alloc)falloc, ud);
#else
    (void)L;
    (void)s;
    (void)len;
    (void)falloc;
    (void)ud;
    return NULL;
#endif
}

const char* flutter_lua_bridge_pushfstring(lua_State* L, const char* fmt) {
    return lua_pushfstring(L, fmt);
}

void flutter_lua_bridge_pushglobaltable(lua_State* L) {
    lua_pushglobaltable(L);
}

void flutter_lua_bridge_pushinteger(lua_State* L, int64_t n) {
    lua_pushinteger(L, (lua_Integer)n);
}

void flutter_lua_bridge_pushlightuserdata(lua_State* L, void* p) {
    lua_pushlightuserdata(L, p);
}

const char* flutter_lua_bridge_pushliteral(lua_State* L, const char* s) {
    return lua_pushstring(L, s);
}

const char* flutter_lua_bridge_pushlstring(lua_State* L, const char* s, size_t len) {
    return lua_pushlstring(L, s, len);
}

void flutter_lua_bridge_pushnil(lua_State* L) {
    lua_pushnil(L);
}

void flutter_lua_bridge_pushnumber(lua_State* L, double n) {
    lua_pushnumber(L, n);
}

const char* flutter_lua_bridge_pushstring(lua_State* L, const char* s) {
    return lua_pushstring(L, s);
}

int flutter_lua_bridge_pushthread(lua_State* L) {
    return lua_pushthread(L);
}

void flutter_lua_bridge_pushvalue(lua_State* L, int idx) {
    lua_pushvalue(L, idx);
}

const char* flutter_lua_bridge_pushvfstring(lua_State* L, const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    const char* result = lua_pushvfstring(L, fmt, args);
    va_end(args);
    return result;
}

int flutter_lua_bridge_rawequal(lua_State* L, int idx1, int idx2) {
    return lua_rawequal(L, idx1, idx2);
}

int flutter_lua_bridge_rawget(lua_State* L, int idx) {
    return lua_rawget(L, idx);
}

int flutter_lua_bridge_rawgeti(lua_State* L, int idx, int64_t n) {
    return lua_rawgeti(L, idx, (lua_Integer)n);
}

int flutter_lua_bridge_rawgetp(lua_State* L, int idx, const void* p) {
    return lua_rawgetp(L, idx, p);
}

size_t flutter_lua_bridge_rawlen(lua_State* L, int idx) {
    return lua_rawlen(L, idx);
}

void flutter_lua_bridge_rawset(lua_State* L, int idx) {
    lua_rawset(L, idx);
}

void flutter_lua_bridge_rawseti(lua_State* L, int idx, int64_t n) {
    lua_rawseti(L, idx, (lua_Integer)n);
}

void flutter_lua_bridge_rawsetp(lua_State* L, int idx, const void* p) {
    lua_rawsetp(L, idx, p);
}

void flutter_lua_bridge_register(lua_State* L, const char* n, void* f) {
    lua_register(L, n, (lua_CFunction)f);
}

void flutter_lua_bridge_remove(lua_State* L, int idx) {
    lua_remove(L, idx);
}

void flutter_lua_bridge_replace(lua_State* L, int idx) {
    lua_replace(L, idx);
}

int flutter_lua_bridge_resetthread(lua_State* L) {
#if LUA_VERSION_NUM >= 504
    return lua_resetthread(L);
#else
    return 0;
#endif
}

int flutter_lua_bridge_resume(lua_State* L, lua_State* from, int narg, int* nres) {
#if LUA_VERSION_NUM >= 504
    return lua_resume(L, from, narg, nres);
#elif LUA_VERSION_NUM >= 503
    int ret = lua_resume(L, from, narg);
    if (nres) *nres = lua_gettop(L);
    return ret;
#else
    return 0;
#endif
}

void flutter_lua_bridge_rotate(lua_State* L, int idx, int n) {
    lua_rotate(L, idx, n);
}

void flutter_lua_bridge_setallocf(lua_State* L, void* f, void* ud) {
    lua_setallocf(L, f, ud);
}

void flutter_lua_bridge_setfield(lua_State* L, int idx, const char* k) {
    lua_setfield(L, idx, k);
}

void flutter_lua_bridge_setglobal(lua_State* L, const char* name) {
    lua_setglobal(L, name);
}

void flutter_lua_bridge_sethook(lua_State* L, void* func, int mask, int count) {
    lua_sethook(L, func, mask, count);
}

void flutter_lua_bridge_seti(lua_State* L, int idx, int64_t n) {
    lua_seti(L, idx, (lua_Integer)n);
}

void flutter_lua_bridge_setiuservalue(lua_State* L, int idx, int n) {
#if LUA_VERSION_NUM >= 504
    lua_setiuservalue(L, idx, n);
#else
    (void)idx;
#endif
}

const char* flutter_lua_bridge_setlocal(lua_State* L, void* ar, int n) {
    return lua_setlocal(L, (lua_Debug*)ar, n);
}

void flutter_lua_bridge_setmetatable(lua_State* L, int idx) {
    lua_setmetatable(L, idx);
}

void flutter_lua_bridge_settable(lua_State* L, int idx) {
    lua_settable(L, idx);
}

void flutter_lua_bridge_settop(lua_State* L, int idx) {
    lua_settop(L, idx);
}

const char* flutter_lua_bridge_setupvalue(lua_State* L, int funcindex, int n) {
    return lua_setupvalue(L, funcindex, n);
}

void flutter_lua_bridge_setuservalue(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 503
    lua_setuservalue(L, idx);
#else
    (void)idx;
#endif
}

void flutter_lua_bridge_setwarnf(lua_State* L, void* f, void* ud) {
#if LUA_VERSION_NUM >= 504
    lua_setwarnf(L, f, ud);
#else
    (void)L;
    (void)f;
    (void)ud;
#endif
}

int flutter_lua_bridge_status(lua_State* L) {
    return lua_status(L);
}

size_t flutter_lua_bridge_stringtonumber(lua_State* L, const char* s) {
    return lua_stringtonumber(L, s);
}

int flutter_lua_bridge_toboolean(lua_State* L, int idx) {
    return lua_toboolean(L, idx);
}

void* flutter_lua_bridge_tocfunction(lua_State* L, int idx) {
    return (void*)lua_tocfunction(L, idx);
}

void flutter_lua_bridge_toclose(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 504
    lua_toclose(L, idx);
#else
    (void)idx;
#endif
}

int64_t flutter_lua_bridge_tointeger(lua_State* L, int idx) {
    return (int64_t)lua_tointeger(L, idx);
}

int64_t flutter_lua_bridge_tointegerx(lua_State* L, int idx, int* isnum) {
    return (int64_t)lua_tointegerx(L, idx, isnum);
}

const char* flutter_lua_bridge_tolstring(lua_State* L, int idx, size_t* len) {
    return lua_tolstring(L, idx, len);
}

double flutter_lua_bridge_tonumber(lua_State* L, int idx) {
    return lua_tonumber(L, idx);
}

double flutter_lua_bridge_tonumberx(lua_State* L, int idx, int* isnum) {
    return lua_tonumberx(L, idx, isnum);
}

const void* flutter_lua_bridge_topointer(lua_State* L, int idx) {
    return lua_topointer(L, idx);
}

const char* flutter_lua_bridge_tostring(lua_State* L, int idx) {
    return lua_tostring(L, idx);
}

lua_State* flutter_lua_bridge_tothread(lua_State* L, int idx) {
    return lua_tothread(L, idx);
}

void* flutter_lua_bridge_touserdata(lua_State* L, int idx) {
    return lua_touserdata(L, idx);
}

int flutter_lua_bridge_type(lua_State* L, int idx) {
    return lua_type(L, idx);
}

const char* flutter_lua_bridge_typename(lua_State* L, int tp) {
    return lua_typename(L, tp);
}

void* flutter_lua_bridge_upvalueid(lua_State* L, int fidx, int n) {
    return lua_upvalueid(L, fidx, n);
}

int flutter_lua_bridge_upvalueindex(int i) {
    return lua_upvalueindex(i);
}

void flutter_lua_bridge_upvaluejoin(lua_State* L, int fidx1, int n1, int fidx2, int n2) {
    lua_upvaluejoin(L, fidx1, n1, fidx2, n2);
}

double flutter_lua_bridge_version(lua_State* L) {
    return (double)LUA_VERSION_NUM;
}

void flutter_lua_bridge_warning(lua_State* L, const char* msg, int tocont) {
#if LUA_VERSION_NUM >= 504
    lua_warning(L, msg, tocont);
#else
    (void)L;
    (void)msg;
    (void)tocont;
#endif
}

void flutter_lua_bridge_xmove(lua_State* from, lua_State* to, int n) {
    lua_xmove(from, to, n);
}

int flutter_lua_bridge_yield(lua_State* L, int nresults) {
    return lua_yield(L, nresults);
}

int flutter_lua_bridge_yieldk(lua_State* L, int nresults, int ctx, void* k) {
    return lua_yieldk(L, nresults, (lua_KContext)ctx, (lua_KFunction)k);
}

/* ================================================================
 * Auxlib API 函数实现
 * ================================================================ */

void flutter_lua_bridgeL_addchar(void* B, char c) {
    luaL_addchar((luaL_Buffer*)B, c);
}

void flutter_lua_bridgeL_addgsub(void* B, const char* s, const char* p, const char* r) {
#if LUA_VERSION_NUM >= 504
    luaL_addgsub((luaL_Buffer*)B, s, p, r);
#else
    (void)B;
    (void)s;
    (void)p;
    (void)r;
#endif
}

void flutter_lua_bridgeL_addlstring(void* B, const char* s, size_t l) {
    luaL_addlstring((luaL_Buffer*)B, s, l);
}

void flutter_lua_bridgeL_addsize(void* B, size_t n) {
    luaL_addsize((luaL_Buffer*)B, n);
}

void flutter_lua_bridgeL_addstring(void* B, const char* s) {
    luaL_addstring((luaL_Buffer*)B, s);
}

void flutter_lua_bridgeL_addvalue(void* B) {
    luaL_addvalue((luaL_Buffer*)B);
}

void* flutter_lua_bridgeL_alloc(void* ud, void* ptr, size_t osize, size_t nsize) {
#if LUA_VERSION_NUM >= 505
    return luaL_alloc(ud, ptr, osize, nsize);
#else
    (void)ud;
    (void)ptr;
    (void)osize;
    (void)nsize;
    return NULL;
#endif
}

void flutter_lua_bridgeL_argcheck(lua_State* L, int cond, int arg, const char* extramsg) {
    luaL_argcheck(L, cond, arg, extramsg);
}

int flutter_lua_bridgeL_argerror(lua_State* L, int arg, const char* extramsg) {
    return luaL_argerror(L, arg, extramsg);
}

void flutter_lua_bridgeL_argexpected(lua_State* L, int cond, int arg, const char* tname) {
#if LUA_VERSION_NUM >= 504
    luaL_argexpected(L, cond, arg, tname);
#else
    (void)L;
    (void)cond;
    (void)arg;
    (void)tname;
#endif
}

char* flutter_lua_bridgeL_buffaddr(void* B) {
#if LUA_VERSION_NUM >= 504
    return luaL_buffaddr((luaL_Buffer*)B);
#else
    (void)B;
    return NULL;
#endif
}

void flutter_lua_bridgeL_buffinit(lua_State* L, void* B) {
    luaL_buffinit(L, (luaL_Buffer*)B);
}

char* flutter_lua_bridgeL_buffinitsize(lua_State* L, void* B, size_t sz) {
    return luaL_buffinitsize(L, B, sz);
}

size_t flutter_lua_bridgeL_bufflen(void* B) {
#if LUA_VERSION_NUM >= 504
    return luaL_bufflen((luaL_Buffer*)B);
#else
    (void)B;
    return 0;
#endif
}

void flutter_lua_bridgeL_buffsub(void* B, int n) {
#if LUA_VERSION_NUM >= 504
    luaL_buffsub((luaL_Buffer*)B, n);
#else
    (void)B;
    (void)n;
#endif
}

int flutter_lua_bridgeL_callmeta(lua_State* L, int obj, const char* e) {
    return luaL_callmeta(L, obj, e);
}

void flutter_lua_bridgeL_checkany(lua_State* L, int arg) {
    luaL_checkany(L, arg);
}

int64_t flutter_lua_bridgeL_checkinteger(lua_State* L, int arg) {
    return (int64_t)luaL_checkinteger(L, arg);
}

const char* flutter_lua_bridgeL_checklstring(lua_State* L, int arg, size_t* l) {
    return luaL_checklstring(L, arg, l);
}

double flutter_lua_bridgeL_checknumber(lua_State* L, int arg) {
    return luaL_checknumber(L, arg);
}

int flutter_lua_bridgeL_checkoption(lua_State* L, int arg, const char* def, const char* const lst[]) {
    return luaL_checkoption(L, arg, def, (const char* const*)lst);
}

void flutter_lua_bridgeL_checkstack(lua_State* L, int sz, const char* msg) {
    luaL_checkstack(L, sz, msg);
}

const char* flutter_lua_bridgeL_checkstring(lua_State* L, int arg) {
    return luaL_checkstring(L, arg);
}

void flutter_lua_bridgeL_checktype(lua_State* L, int arg, int t) {
    luaL_checktype(L, arg, t);
}

void* flutter_lua_bridgeL_checkudata(lua_State* L, int ud, const char* tname) {
    return luaL_checkudata(L, ud, tname);
}

void flutter_lua_bridgeL_checkversion(lua_State* L) {
    luaL_checkversion(L);
}

int flutter_lua_bridgeL_dofile(lua_State* L, const char* fn) {
    return (luaL_loadfile(L, fn) || lua_pcall(L, 0, LUA_MULTRET, 0));
}

int flutter_lua_bridgeL_dostring(lua_State* L, const char* s) {
    return (luaL_loadstring(L, s) || lua_pcall(L, 0, LUA_MULTRET, 0));
}

int flutter_lua_bridgeL_error(lua_State* L, const char* fmt) {
    return luaL_error(L, fmt);
}

int flutter_lua_bridgeL_execresult(lua_State* L, int stat) {
    return luaL_execresult(L, stat);
}

int flutter_lua_bridgeL_fileresult(lua_State* L, int stat, const char* fname) {
    return luaL_fileresult(L, stat, fname);
}

int flutter_lua_bridgeL_getmetafield(lua_State* L, int obj, const char* e) {
    return luaL_getmetafield(L, obj, e);
}

int flutter_lua_bridgeL_getmetatable(lua_State* L, const char* tname) {
    return luaL_getmetatable(L, tname);
}

int flutter_lua_bridgeL_getsubtable(lua_State* L, int idx, const char* fname) {
    return luaL_getsubtable(L, idx, fname);
}

const char* flutter_lua_bridgeL_gsub(lua_State* L, const char* s, const char* p, const char* r) {
    return luaL_gsub(L, s, p, r);
}

int64_t flutter_lua_bridgeL_len(lua_State* L, int idx) {
    return (int64_t)luaL_len(L, idx);
}

int flutter_lua_bridgeL_loadbuffer(lua_State* L, const char* buff, size_t sz, const char* name) {
    return luaL_loadbufferx(L, buff, sz, name, NULL);
}

int flutter_lua_bridgeL_loadbufferx(lua_State* L, const char* buff, size_t sz, const char* name, const char* mode) {
    return luaL_loadbufferx(L, buff, sz, name, mode);
}

int flutter_lua_bridgeL_loadfile(lua_State* L, const char* filename) {
    return luaL_loadfilex(L, filename, NULL);
}

int flutter_lua_bridgeL_loadfilex(lua_State* L, const char* filename, const char* mode) {
    return luaL_loadfilex(L, filename, mode);
}

int flutter_lua_bridgeL_loadstring(lua_State* L, const char* s) {
    return luaL_loadstring(L, s);
}

uint64_t flutter_lua_bridgeL_makeseed(lua_State* L) {
#if LUA_VERSION_NUM >= 505
    return luaL_makeseed(L);
#else
    return 0;
#endif
}

void flutter_lua_bridgeL_newlib(lua_State* L, void* l, int nrec) {
    luaL_checkversion(L);
    lua_createtable(L, 0, nrec);
    luaL_setfuncs(L, (const luaL_Reg*)l, 0);
}

void flutter_lua_bridgeL_newlibtable(lua_State* L, int nrec) {
    lua_createtable(L, 0, nrec);
}

int flutter_lua_bridgeL_newmetatable(lua_State* L, const char* tname) {
    return luaL_newmetatable(L, tname);
}

lua_State* flutter_lua_bridgeL_newstate(void) {
    return luaL_newstate();
}

void flutter_lua_bridgeL_openlibs(lua_State* L) {
    luaL_openlibs(L);
}

void flutter_lua_bridgeL_openselectedlibs(lua_State* L, const char* libs) {
#if LUA_VERSION_NUM >= 505
    luaL_openselectedlibs(L, libs);
#else
    (void)L;
    (void)libs;
#endif
}

void* flutter_lua_bridgeL_opt(lua_State* L, void* f, int n, void* d) {
    if (lua_isnoneornil(L, n)) {
        return d;
    }
    // 这是一个通用的 wrapper，实际使用时应该用具体的类型版本
    // 这里返回 NULL 作为占位符
    return NULL;
}

int64_t flutter_lua_bridgeL_optinteger(lua_State* L, int arg, int64_t d) {
    return (int64_t)luaL_optinteger(L, arg, d);
}

const char* flutter_lua_bridgeL_optlstring(lua_State* L, int arg, const char* d, size_t* l) {
    return luaL_optlstring(L, arg, d, l);
}

double flutter_lua_bridgeL_optnumber(lua_State* L, int arg, double d) {
    if (lua_isnoneornil(L, arg)) {
        return d;
    }
    return luaL_checknumber(L, arg);
}

const char* flutter_lua_bridgeL_optstring(lua_State* L, int arg, const char* d) {
    return flutter_lua_bridgeL_optlstring(L, arg, d, NULL);
}

char* flutter_lua_bridgeL_prepbuffer(void* B) {
    return luaL_prepbuffer((luaL_Buffer*)B);
}

char* flutter_lua_bridgeL_prepbuffsize(void* B, size_t sz) {
    return luaL_prepbuffsize((luaL_Buffer*)B, sz);
}

void flutter_lua_bridgeL_pushfail(lua_State* L) {
    luaL_pushfail(L);
}

void flutter_lua_bridgeL_pushresult(void* B) {
    luaL_pushresult((luaL_Buffer*)B);
}

void flutter_lua_bridgeL_pushresultsize(void* B, size_t sz) {
    luaL_pushresultsize((luaL_Buffer*)B, sz);
}

int flutter_lua_bridgeL_ref(lua_State* L, int t) {
    return luaL_ref(L, t);
}

void flutter_lua_bridgeL_requiref(lua_State* L, const char* modname, void* openf, int glb) {
    luaL_requiref(L, modname, (lua_CFunction)openf, glb);
}

void flutter_lua_bridgeL_setfuncs(lua_State* L, void* l, int nup) {
    luaL_setfuncs(L, (const luaL_Reg*)l, nup);
}

void flutter_lua_bridgeL_setmetatable(lua_State* L, const char* tname) {
    luaL_setmetatable(L, tname);
}

void* flutter_lua_bridgeL_testudata(lua_State* L, int ud, const char* tname) {
    return luaL_testudata(L, ud, tname);
}

const char* flutter_lua_bridgeL_tolstring(lua_State* L, int idx, size_t* len) {
    return luaL_tolstring(L, idx, len);
}

void flutter_lua_bridgeL_traceback(lua_State* L, lua_State* L1, const char* msg, int level) {
    luaL_traceback(L, L1, msg, level);
}

int flutter_lua_bridgeL_typeerror(lua_State* L, int arg, const char* tname) {
#if LUA_VERSION_NUM >= 504
    return luaL_typeerror(L, arg, tname);
#else
    (void)L;
    return 0;
#endif
}

const char* flutter_lua_bridgeL_typename(lua_State* L, int idx) {
    return lua_typename(L, idx);
}

void flutter_lua_bridgeL_unref(lua_State* L, int t, int ref) {
    luaL_unref(L, t, ref);
}

void flutter_lua_bridgeL_where(lua_State* L, int lvl) {
    luaL_where(L, lvl);
}
