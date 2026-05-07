#include "lua_api_shim.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#if LUA_VERSION_NUM == 504
  #define SHIM_LUA_54 1
#elif LUA_VERSION_NUM == 503
  #define SHIM_LUA_53 1
#else
  #error "Only Lua 5.3/5.4 supported"
#endif

/* ================================================================
 * 状态管理
 * ================================================================ */
lua_State*       lua_shim_newstate(void) { return luaL_newstate(); }
void             lua_shim_close(lua_State* L) { lua_close(L); }
lua_shim_status_t lua_shim_status(lua_State* L) { return (lua_shim_status_t)lua_status(L); }

/* ================================================================
 * 栈操作
 * ================================================================ */
int  lua_shim_gettop(lua_State* L) { return lua_gettop(L); }
void lua_shim_settop(lua_State* L, int idx) { lua_settop(L, idx); }
void lua_shim_pushvalue(lua_State* L, int idx) { lua_pushvalue(L, idx); }
void lua_shim_copy(lua_State* L, int fromidx, int toidx) { lua_copy(L, fromidx, toidx); }
int  lua_shim_checkstack(lua_State* L, int n) { return lua_checkstack(L, n); }
void lua_shim_xmove(lua_State* L, lua_State* to, int n) { lua_xmove(L, to, n); }

/* ---------- 宏函数显式化 ---------- */
void lua_shim_pop(lua_State* L, int n) { lua_pop(L, n); }
void lua_shim_remove(lua_State* L, int idx) { lua_remove(L, idx); }
void lua_shim_insert(lua_State* L, int idx) { lua_insert(L, idx); }
void lua_shim_replace(lua_State* L, int idx) { lua_replace(L, idx); }

/* ================================================================
 * 类型检查
 * ================================================================ */
bool lua_shim_isnil(lua_State* L, int idx) { return lua_isnil(L, idx); }
bool lua_shim_isboolean(lua_State* L, int idx) { return lua_isboolean(L, idx); }
bool lua_shim_isnumber(lua_State* L, int idx) { return lua_isnumber(L, idx); }
bool lua_shim_isstring(lua_State* L, int idx) { return lua_isstring(L, idx); }
bool lua_shim_istable(lua_State* L, int idx) { return lua_istable(L, idx); }
bool lua_shim_isfunction(lua_State* L, int idx) { return lua_isfunction(L, idx); }
bool lua_shim_iscfunction(lua_State* L, int idx) { return lua_iscfunction(L, idx); }
bool lua_shim_isuserdata(lua_State* L, int idx) { return lua_isuserdata(L, idx); }
bool lua_shim_islightuserdata(lua_State* L, int idx) { return lua_islightuserdata(L, idx); }
bool lua_shim_isthread(lua_State* L, int idx) { return lua_isthread(L, idx); }

lua_shim_type_t lua_shim_type(lua_State* L, int idx) { return (lua_shim_type_t)lua_type(L, idx); }
const char*    lua_shim_typename(lua_State* L, lua_shim_type_t tp) { return lua_typename(L, (int)tp); }

/* ================================================================
 * 转换
 * ================================================================ */
double lua_shim_tonumberx(lua_State* L, int idx, bool* isnum) {
    int ok; double v = lua_tonumberx(L, idx, &ok);
    if (isnum) *isnum = ok; return v;
}

int64_t lua_shim_tointegerx(lua_State* L, int idx, bool* isnum) {
    int ok; lua_Integer v = lua_tointegerx(L, idx, &ok);
    if (isnum) *isnum = ok; return (int64_t)v;
}

bool lua_shim_toboolean(lua_State* L, int idx) { return lua_toboolean(L, idx); }
const char* lua_shim_tolstring(lua_State* L, int idx, size_t* len) { return lua_tolstring(L, idx, len); }

size_t lua_shim_rawlen(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 502
    return lua_rawlen(L, idx);
#else
    return lua_objlen(L, idx);
#endif
}

void* lua_shim_touserdata(lua_State* L, int idx) { return lua_touserdata(L, idx); }
lua_State* lua_shim_tothread(lua_State* L, int idx) { return lua_tothread(L, idx); }

/* ================================================================
 * 压栈
 * ================================================================ */
void lua_shim_pushnil(lua_State* L) { lua_pushnil(L); }
void lua_shim_pushnumber(lua_State* L, double n) { lua_pushnumber(L, n); }
void lua_shim_pushinteger(lua_State* L, int64_t n) { lua_pushinteger(L, (lua_Integer)n); }
void lua_shim_pushlstring(lua_State* L, const char* s, size_t len) { lua_pushlstring(L, s, len); }
void lua_shim_pushstring(lua_State* L, const char* s) { lua_pushstring(L, s); }
void lua_shim_pushboolean(lua_State* L, bool b) { lua_pushboolean(L, b); }
void lua_shim_pushlightuserdata(lua_State* L, void* p) { lua_pushlightuserdata(L, p); }
void lua_shim_pushcclosure(lua_State* L, void* fn, int n) { lua_pushcclosure(L, (lua_CFunction)fn, n); }

/* ================================================================
 * 获取操作
 * ================================================================ */
void lua_shim_gettable(lua_State* L, int idx) { lua_gettable(L, idx); }
lua_shim_type_t lua_shim_getfield(lua_State* L, int idx, const char* k) { return (lua_shim_type_t)lua_getfield(L, idx, k); }
void lua_shim_rawget(lua_State* L, int idx) { lua_rawget(L, idx); }
void lua_shim_rawgeti(lua_State* L, int idx, int64_t n) { lua_rawgeti(L, idx, (lua_Integer)n); }
void lua_shim_rawgetp(lua_State* L, int idx, const void* p) { lua_rawgetp(L, idx, p); }
void lua_shim_newtable(lua_State* L) { lua_createtable(L, 0, 0); }
void lua_shim_createtable(lua_State* L, int narr, int nrec) { lua_createtable(L, narr, nrec); }
void* lua_shim_newuserdatauv(lua_State* L, size_t sz, int nuvalue) {
#if SHIM_LUA_54
    return lua_newuserdatauv(L, sz, nuvalue);
#else
    (void)nuvalue; return lua_newuserdata(L, sz);
#endif
}
int  lua_shim_getmetatable(lua_State* L, int objindex) { return lua_getmetatable(L, objindex); }
void lua_shim_getiuservalue(lua_State* L, int idx, int n) {
#if SHIM_LUA_54
    lua_getiuservalue(L, idx, n);
#else
    (void)n; lua_getuservalue(L, idx);
#endif
}

/* ================================================================
 * 设置操作
 * ================================================================ */
void lua_shim_settable(lua_State* L, int idx) { lua_settable(L, idx); }
void lua_shim_setfield(lua_State* L, int idx, const char* k) { lua_setfield(L, idx, k); }
void lua_shim_rawset(lua_State* L, int idx) { lua_rawset(L, idx); }
void lua_shim_rawseti(lua_State* L, int idx, int64_t n) { lua_rawseti(L, idx, (lua_Integer)n); }
void lua_shim_rawsetp(lua_State* L, int idx, const void* p) { lua_rawsetp(L, idx, p); }
void lua_shim_setmetatable(lua_State* L, int objindex) { lua_setmetatable(L, objindex); }
void lua_shim_setiuservalue(lua_State* L, int idx, int n) {
#if SHIM_LUA_54
    lua_setiuservalue(L, idx, n);
#else
    (void)n; lua_setuservalue(L, idx);
#endif
}

/* ================================================================
 * 全局环境
 * ================================================================ */
lua_shim_type_t lua_shim_getglobal(lua_State* L, const char* name) { return (lua_shim_type_t)lua_getglobal(L, name); }
void lua_shim_setglobal(lua_State* L, const char* name) { lua_setglobal(L, name); }

/* ================================================================
 * 调用（签名抹平）
 * ================================================================ */
lua_shim_status_t lua_shim_pcallk(lua_State* L, int nargs, int nresults, int errfunc, int64_t ctx, void* k) {
    return (lua_shim_status_t)lua_pcallk(L, nargs, nresults, errfunc, (lua_KContext)ctx, (lua_KFunction)k);
}

lua_shim_status_t lua_shim_resume(lua_State* L, lua_State* from, int narg, int* nres) {
#if SHIM_LUA_54
    return (lua_shim_status_t)lua_resume(L, from, narg, nres);
#elif SHIM_LUA_53
    int ret = lua_resume(L, from, narg);
    if (nres) *nres = lua_gettop(L);
    return (lua_shim_status_t)ret;
#else
    return (lua_shim_status_t)lua_resume(L, narg);
#endif
}

lua_shim_status_t lua_shim_yieldk(lua_State* L, int nresults, int64_t ctx, void* k) {
    return (lua_shim_status_t)lua_yieldk(L, nresults, (lua_KContext)ctx, (lua_KFunction)k);
}

lua_shim_status_t lua_shim_loadstring(lua_State* L, const char* s) { return (lua_shim_status_t)luaL_loadstring(L, s); }

/* ================================================================
 * 算术与比较
 * ================================================================ */
void lua_shim_arith(lua_State* L, lua_shim_arith_t op) { lua_arith(L, (int)op); }
int  lua_shim_compare(lua_State* L, int idx1, int idx2, lua_shim_compare_t op) { return lua_compare(L, idx1, idx2, (int)op); }
void lua_shim_len(lua_State* L, int idx) { lua_len(L, idx); }
void lua_shim_concat(lua_State* L, int n) { lua_concat(L, n); }

/* ================================================================
 * GC
 * ================================================================ */
int lua_shim_gc(lua_State* L, lua_shim_gc_t what, int data) { return lua_gc(L, (int)what, data); }

/* ================================================================
 * 错误
 * ================================================================ */
lua_shim_status_t lua_shim_error(lua_State* L) { return (lua_shim_status_t)lua_error(L); }
lua_shim_status_t lua_shim_throwstring(lua_State* L, const char* s) { return (lua_shim_status_t)luaL_error(L, "%s", s); }

/* ================================================================
 * 标准库
 * ================================================================ */
void lua_shim_openlibs(lua_State* L) { luaL_openlibs(L); }
void lua_shim_open_base(lua_State* L) { luaopen_base(L); }
void lua_shim_open_table(lua_State* L) { luaopen_table(L); }
void lua_shim_open_io(lua_State* L) { luaopen_io(L); }
void lua_shim_open_os(lua_State* L) { luaopen_os(L); }
void lua_shim_open_string(lua_State* L) { luaopen_string(L); }
void lua_shim_open_math(lua_State* L) { luaopen_math(L); }
void lua_shim_open_utf8(lua_State* L) { luaopen_utf8(L); }
void lua_shim_open_debug(lua_State* L) { luaopen_debug(L); }
void lua_shim_open_package(lua_State* L) { luaopen_package(L); }

/* ================================================================
 * 协程
 * ================================================================ */
lua_State* lua_shim_newthread(lua_State* L) { return lua_newthread(L); }
int lua_shim_closethread(lua_State* L, lua_State* from) {
#if SHIM_LUA_54
    return lua_closethread(L, from);
#else
    (void)from; return 0;
#endif
}

/* ================================================================
 * 辅助
 * ================================================================ */
int  lua_shim_ref(lua_State* L, int t) { return luaL_ref(L, t); }
void lua_shim_unref(lua_State* L, int t, int ref) { luaL_unref(L, t, ref); }

/* ================================================================
 * 内存
 * ================================================================ */
void lua_shim_setallocf(lua_State* L, void* f, void* ud) { lua_setallocf(L, f, ud); }

/* ================================================================
 * 版本
 * ================================================================ */
double lua_shim_version(lua_State* L) { (void)L; return (double)LUA_VERSION_NUM; }

/* ================================================================
 * Dart 回调
 * ================================================================ */
void lua_shim_pushdartfunction(lua_State* L, DartCFunction f) {
    lua_pushcfunction(L, (lua_CFunction)f);
}
