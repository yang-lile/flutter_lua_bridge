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
lua_State*       dart_lua_shim_newstate(void) { return luaL_newstate(); }
void             dart_lua_shim_close(lua_State* L) { lua_close(L); }
lua_shim_status_t dart_lua_shim_status(lua_State* L) { return (lua_shim_status_t)lua_status(L); }

/* ================================================================
 * 栈操作
 * ================================================================ */
int  dart_lua_shim_gettop(lua_State* L) { return lua_gettop(L); }
void dart_lua_shim_settop(lua_State* L, int idx) { lua_settop(L, idx); }
void dart_lua_shim_pushvalue(lua_State* L, int idx) { lua_pushvalue(L, idx); }
void dart_lua_shim_copy(lua_State* L, int fromidx, int toidx) { lua_copy(L, fromidx, toidx); }
int  dart_lua_shim_checkstack(lua_State* L, int n) { return lua_checkstack(L, n); }
void dart_lua_shim_xmove(lua_State* L, lua_State* to, int n) { lua_xmove(L, to, n); }

/* ---------- 宏函数显式化 ---------- */
void dart_lua_shim_pop(lua_State* L, int n) { lua_pop(L, n); }
void dart_lua_shim_remove(lua_State* L, int idx) { lua_remove(L, idx); }
void dart_lua_shim_insert(lua_State* L, int idx) { lua_insert(L, idx); }
void dart_lua_shim_replace(lua_State* L, int idx) { lua_replace(L, idx); }

/* ================================================================
 * 类型检查
 * ================================================================ */
bool dart_lua_shim_isnil(lua_State* L, int idx) { return lua_isnil(L, idx); }
bool dart_lua_shim_isboolean(lua_State* L, int idx) { return lua_isboolean(L, idx); }
bool dart_lua_shim_isnumber(lua_State* L, int idx) { return lua_isnumber(L, idx); }
bool dart_lua_shim_isstring(lua_State* L, int idx) { return lua_isstring(L, idx); }
bool dart_lua_shim_istable(lua_State* L, int idx) { return lua_istable(L, idx); }
bool dart_lua_shim_isfunction(lua_State* L, int idx) { return lua_isfunction(L, idx); }
bool dart_lua_shim_iscfunction(lua_State* L, int idx) { return lua_iscfunction(L, idx); }
bool dart_lua_shim_isuserdata(lua_State* L, int idx) { return lua_isuserdata(L, idx); }
bool dart_lua_shim_islightuserdata(lua_State* L, int idx) { return lua_islightuserdata(L, idx); }
bool dart_lua_shim_isthread(lua_State* L, int idx) { return lua_isthread(L, idx); }

lua_shim_type_t dart_lua_shim_type(lua_State* L, int idx) { return (lua_shim_type_t)lua_type(L, idx); }
const char*    dart_lua_shim_typename(lua_State* L, lua_shim_type_t tp) { return lua_typename(L, (int)tp); }

/* ================================================================
 * 转换
 * ================================================================ */
double dart_lua_shim_tonumberx(lua_State* L, int idx, bool* isnum) {
    int ok; double v = lua_tonumberx(L, idx, &ok);
    if (isnum) *isnum = ok; return v;
}

int64_t dart_lua_shim_tointegerx(lua_State* L, int idx, bool* isnum) {
    int ok; lua_Integer v = lua_tointegerx(L, idx, &ok);
    if (isnum) *isnum = ok; return (int64_t)v;
}

bool dart_lua_shim_toboolean(lua_State* L, int idx) { return lua_toboolean(L, idx); }
const char* dart_lua_shim_tolstring(lua_State* L, int idx, size_t* len) { return lua_tolstring(L, idx, len); }

size_t dart_lua_shim_rawlen(lua_State* L, int idx) {
#if LUA_VERSION_NUM >= 502
    return lua_rawlen(L, idx);
#else
    return lua_objlen(L, idx);
#endif
}

void* dart_lua_shim_touserdata(lua_State* L, int idx) { return lua_touserdata(L, idx); }
lua_State* dart_lua_shim_tothread(lua_State* L, int idx) { return lua_tothread(L, idx); }

/* ================================================================
 * 压栈
 * ================================================================ */
void dart_lua_shim_pushnil(lua_State* L) { lua_pushnil(L); }
void dart_lua_shim_pushnumber(lua_State* L, double n) { lua_pushnumber(L, n); }
void dart_lua_shim_pushinteger(lua_State* L, int64_t n) { lua_pushinteger(L, (lua_Integer)n); }
void dart_lua_shim_pushlstring(lua_State* L, const char* s, size_t len) { lua_pushlstring(L, s, len); }
void dart_lua_shim_pushstring(lua_State* L, const char* s) { lua_pushstring(L, s); }
void dart_lua_shim_pushboolean(lua_State* L, bool b) { lua_pushboolean(L, b); }
void dart_lua_shim_pushlightuserdata(lua_State* L, void* p) { lua_pushlightuserdata(L, p); }
void dart_lua_shim_pushcclosure(lua_State* L, void* fn, int n) { lua_pushcclosure(L, (lua_CFunction)fn, n); }

/* ================================================================
 * 获取操作
 * ================================================================ */
void dart_lua_shim_gettable(lua_State* L, int idx) { lua_gettable(L, idx); }
lua_shim_type_t dart_lua_shim_getfield(lua_State* L, int idx, const char* k) { return (lua_shim_type_t)lua_getfield(L, idx, k); }
void dart_lua_shim_rawget(lua_State* L, int idx) { lua_rawget(L, idx); }
void dart_lua_shim_rawgeti(lua_State* L, int idx, int64_t n) { lua_rawgeti(L, idx, (lua_Integer)n); }
void dart_lua_shim_rawgetp(lua_State* L, int idx, const void* p) { lua_rawgetp(L, idx, p); }
void dart_lua_shim_newtable(lua_State* L) { lua_createtable(L, 0, 0); }
void dart_lua_shim_createtable(lua_State* L, int narr, int nrec) { lua_createtable(L, narr, nrec); }
void* dart_lua_shim_newuserdatauv(lua_State* L, size_t sz, int nuvalue) {
#if SHIM_LUA_54
    return lua_newuserdatauv(L, sz, nuvalue);
#else
    (void)nuvalue; return lua_newuserdata(L, sz);
#endif
}
int  dart_lua_shim_getmetatable(lua_State* L, int objindex) { return lua_getmetatable(L, objindex); }
void dart_lua_shim_getiuservalue(lua_State* L, int idx, int n) {
#if SHIM_LUA_54
    lua_getiuservalue(L, idx, n);
#else
    (void)n; lua_getuservalue(L, idx);
#endif
}

/* ================================================================
 * 设置操作
 * ================================================================ */
void dart_lua_shim_settable(lua_State* L, int idx) { lua_settable(L, idx); }
void dart_lua_shim_setfield(lua_State* L, int idx, const char* k) { lua_setfield(L, idx, k); }
void dart_lua_shim_rawset(lua_State* L, int idx) { lua_rawset(L, idx); }
void dart_lua_shim_rawseti(lua_State* L, int idx, int64_t n) { lua_rawseti(L, idx, (lua_Integer)n); }
void dart_lua_shim_rawsetp(lua_State* L, int idx, const void* p) { lua_rawsetp(L, idx, p); }
void dart_lua_shim_setmetatable(lua_State* L, int objindex) { lua_setmetatable(L, objindex); }
void dart_lua_shim_setiuservalue(lua_State* L, int idx, int n) {
#if SHIM_LUA_54
    lua_setiuservalue(L, idx, n);
#else
    (void)n; lua_setuservalue(L, idx);
#endif
}

/* ================================================================
 * 全局环境
 * ================================================================ */
lua_shim_type_t dart_lua_shim_getglobal(lua_State* L, const char* name) { return (lua_shim_type_t)lua_getglobal(L, name); }
void dart_lua_shim_setglobal(lua_State* L, const char* name) { lua_setglobal(L, name); }

/* ================================================================
 * 调用（签名抹平）
 * ================================================================ */
lua_shim_status_t dart_lua_shim_pcallk(lua_State* L, int nargs, int nresults, int errfunc, int64_t ctx, void* k) {
    return (lua_shim_status_t)lua_pcallk(L, nargs, nresults, errfunc, (lua_KContext)ctx, (lua_KFunction)k);
}

lua_shim_status_t dart_lua_shim_resume(lua_State* L, lua_State* from, int narg, int* nres) {
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

lua_shim_status_t dart_lua_shim_yieldk(lua_State* L, int nresults, int64_t ctx, void* k) {
    return (lua_shim_status_t)lua_yieldk(L, nresults, (lua_KContext)ctx, (lua_KFunction)k);
}

lua_shim_status_t dart_lua_shim_loadstring(lua_State* L, const char* s) { return (lua_shim_status_t)luaL_loadstring(L, s); }

/* ================================================================
 * 算术与比较
 * ================================================================ */
void dart_lua_shim_arith(lua_State* L, lua_shim_arith_t op) { lua_arith(L, (int)op); }
int  dart_lua_shim_compare(lua_State* L, int idx1, int idx2, lua_shim_compare_t op) { return lua_compare(L, idx1, idx2, (int)op); }
void dart_lua_shim_len(lua_State* L, int idx) { lua_len(L, idx); }
void dart_lua_shim_concat(lua_State* L, int n) { lua_concat(L, n); }

/* ================================================================
 * GC
 * ================================================================ */
int dart_lua_shim_gc(lua_State* L, lua_shim_gc_t what, int data) { return lua_gc(L, (int)what, data); }

/* ================================================================
 * 错误
 * ================================================================ */
lua_shim_status_t dart_lua_shim_error(lua_State* L) { return (lua_shim_status_t)lua_error(L); }
lua_shim_status_t dart_lua_shim_throwstring(lua_State* L, const char* s) { return (lua_shim_status_t)luaL_error(L, "%s", s); }

/* ================================================================
 * 标准库
 * ================================================================ */
void dart_lua_shim_openlibs(lua_State* L) { luaL_openlibs(L); }
void dart_lua_shim_open_base(lua_State* L) { luaopen_base(L); }
void dart_lua_shim_open_table(lua_State* L) { luaopen_table(L); }
void dart_lua_shim_open_io(lua_State* L) { luaopen_io(L); }
void dart_lua_shim_open_os(lua_State* L) { luaopen_os(L); }
void dart_lua_shim_open_string(lua_State* L) { luaopen_string(L); }
void dart_lua_shim_open_math(lua_State* L) { luaopen_math(L); }
void dart_lua_shim_open_utf8(lua_State* L) { luaopen_utf8(L); }
void dart_lua_shim_open_debug(lua_State* L) { luaopen_debug(L); }
void dart_lua_shim_open_package(lua_State* L) { luaopen_package(L); }

/* ================================================================
 * 协程
 * ================================================================ */
lua_State* dart_lua_shim_newthread(lua_State* L) { return lua_newthread(L); }
int dart_lua_shim_closethread(lua_State* L, lua_State* from) {
#if SHIM_LUA_54
    return lua_closethread(L, from);
#else
    (void)from; return 0;
#endif
}

/* ================================================================
 * 辅助
 * ================================================================ */
int  dart_lua_shim_ref(lua_State* L, int t) { return luaL_ref(L, t); }
void dart_lua_shim_unref(lua_State* L, int t, int ref) { luaL_unref(L, t, ref); }

/* ================================================================
 * 内存
 * ================================================================ */
void dart_lua_shim_setallocf(lua_State* L, void* f, void* ud) { lua_setallocf(L, f, ud); }

/* ================================================================
 * 版本
 * ================================================================ */
double dart_lua_shim_version(lua_State* L) { (void)L; return (double)LUA_VERSION_NUM; }

/* ================================================================
 * Dart 回调
 * ================================================================ */
void dart_lua_shim_pushdartfunction(lua_State* L, DartCFunction f) {
    lua_pushcfunction(L, (lua_CFunction)f);
}

/* ================================================================
 * 错误信息存储
 * ================================================================ */

static _Thread_local const char* _shim_lasterror = NULL;

static void _shim_seterror(const char* msg) {
    _shim_lasterror = msg;
}

const char* dart_lua_shim_lasterror(void) {
    return _shim_lasterror ? _shim_lasterror : "";
}

/* ================================================================
 * C API 补全实现
 * ================================================================ */

int dart_lua_shim_absindex(lua_State* L, int idx) { return lua_absindex(L, idx); }

void* dart_lua_shim_atpanic(lua_State* L, void* panicf) { (void)L; (void)panicf; _shim_seterror("dart_lua_shim_atpanic: C callback not supported in shim layer"); return NULL; }

void dart_lua_shim_call(lua_State* L, int nargs, int nresults) { lua_callk(L, nargs, nresults, 0, NULL); }

void dart_lua_shim_callk(lua_State* L, int nargs, int nresults, int64_t ctx, void* k) { lua_callk(L, nargs, nresults, (lua_KContext)ctx, (lua_KFunction)k); }

dart_lua_shim_void_result_t dart_lua_shim_closeslot(lua_State* L, int idx) {
#if SHIM_LUA_54
    lua_closeslot(L, idx);
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, NULL);
#else
    (void)L; (void)idx;
    _shim_seterror("lua_closeslot: not supported in Lua 5.3");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

int dart_lua_shim_dump(lua_State* L, void* writer, void* data, int strip) { (void)L; (void)writer; (void)data; (void)strip; _shim_seterror("dart_lua_shim_dump: lua_Writer callback not supported"); return (int)LUA_SHIM_ERRERR; }

void* dart_lua_shim_getallocf(lua_State* L, void** ud) { return (void*)lua_getallocf(L, ud); }

void* dart_lua_shim_getextraspace(lua_State* L) { return lua_getextraspace(L); }

void* dart_lua_shim_gethook(lua_State* L) { (void)L; _shim_seterror("dart_lua_shim_gethook: lua_Hook not supported"); return NULL; }

int dart_lua_shim_gethookcount(lua_State* L) { (void)L; _shim_seterror("dart_lua_shim_gethookcount: hook system not supported"); return (int)LUA_SHIM_ERRERR; }

int dart_lua_shim_gethookmask(lua_State* L) { (void)L; _shim_seterror("dart_lua_shim_gethookmask: hook system not supported"); return (int)LUA_SHIM_ERRERR; }

int dart_lua_shim_geti(lua_State* L, int idx, int64_t n) { return lua_geti(L, idx, (lua_Integer)n); }

int dart_lua_shim_getinfo(lua_State* L, const char* what, void* ar) { (void)L; (void)what; (void)ar; _shim_seterror("dart_lua_shim_getinfo: lua_Debug not supported"); return (int)LUA_SHIM_ERRERR; }

const char* dart_lua_shim_getlocal(lua_State* L, void* ar, int n) { (void)L; (void)ar; (void)n; _shim_seterror("dart_lua_shim_getlocal: lua_Debug not supported"); return ""; }

int dart_lua_shim_getstack(lua_State* L, int level, void* ar) { (void)L; (void)level; (void)ar; _shim_seterror("dart_lua_shim_getstack: lua_Debug not supported"); return (int)LUA_SHIM_ERRERR; }

const char* dart_lua_shim_getupvalue(lua_State* L, int funcindex, int n) { return lua_getupvalue(L, funcindex, n); }

int dart_lua_shim_getuservalue(lua_State* L, int idx) {
#if SHIM_LUA_53
    return lua_getuservalue(L, idx);
#else
    return lua_getiuservalue(L, idx, 0);
#endif
}

int dart_lua_shim_isinteger(lua_State* L, int idx) { return lua_isinteger(L, idx); }

int dart_lua_shim_isnone(lua_State* L, int idx) { return lua_type(L, idx) == LUA_TNONE; }

int dart_lua_shim_isnoneornil(lua_State* L, int idx) { return lua_type(L, idx) <= 0; }

int dart_lua_shim_isyieldable(lua_State* L) { return lua_isyieldable(L); }

int dart_lua_shim_load(lua_State* L, void* reader, void* dt, const char* chunkname, const char* mode) { (void)L; (void)reader; (void)dt; (void)chunkname; (void)mode; _shim_seterror("dart_lua_shim_load: lua_Reader callback not supported"); return (int)LUA_SHIM_ERRERR; }

void* dart_lua_shim_newuserdata(lua_State* L, size_t sz) {
#if SHIM_LUA_54
    return lua_newuserdatauv(L, sz, 1);
#else
    return lua_newuserdata(L, sz);
#endif
}

int dart_lua_shim_next(lua_State* L, int idx) { return lua_next(L, idx); }

int dart_lua_shim_numbertointeger(double n, int64_t* p) { return lua_numbertointeger((lua_Number)n, (lua_Integer*)p); }

lua_shim_status_t dart_lua_shim_pcall(lua_State* L, int nargs, int nresults, int errfunc) { return (lua_shim_status_t)lua_pcallk(L, nargs, nresults, errfunc, 0, NULL); }

void dart_lua_shim_pushcfunction(lua_State* L, void* f) { lua_pushcclosure(L, (lua_CFunction)f, 0); }

const char* dart_lua_shim_pushfstring(lua_State* L, const char* fmt, ...) { (void)L; (void)fmt; _shim_seterror("dart_lua_shim_pushfstring: varargs not supported"); return ""; }

void dart_lua_shim_pushglobaltable(lua_State* L) { lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS); }

const char* dart_lua_shim_pushliteral(lua_State* L, const char* s) { return lua_pushstring(L, s); }

int dart_lua_shim_pushthread(lua_State* L) { return lua_pushthread(L); }

const char* dart_lua_shim_pushvfstring(lua_State* L, const char* fmt, void* argp) { (void)L; (void)fmt; (void)argp; _shim_seterror("dart_lua_shim_pushvfstring: varargs not supported"); return ""; }

int dart_lua_shim_rawequal(lua_State* L, int idx1, int idx2) { return lua_rawequal(L, idx1, idx2); }

void dart_lua_shim_register(lua_State* L, const char* n, void* f) { lua_pushcclosure(L, (lua_CFunction)f, 0); lua_setglobal(L, n); }

dart_lua_shim_int_result_t dart_lua_shim_resetthread(lua_State* L) {
#if SHIM_LUA_54
    return RESULT_RET(int, const_char_ptr, lua_resetthread(L), NULL);
#else
    (void)L;
    _shim_seterror("lua_resetthread: not supported in Lua 5.3");
    return RESULT_RET(int, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

void dart_lua_shim_rotate(lua_State* L, int idx, int n) { lua_rotate(L, idx, n); }

int dart_lua_shim_sethook(lua_State* L, void* func, int mask, int count) { (void)L; (void)func; (void)mask; (void)count; _shim_seterror("dart_lua_shim_sethook: lua_Hook not supported"); return (int)LUA_SHIM_ERRERR; }

void dart_lua_shim_seti(lua_State* L, int idx, int64_t n) { lua_seti(L, idx, (lua_Integer)n); }

const char* dart_lua_shim_setlocal(lua_State* L, void* ar, int n) { (void)L; (void)ar; (void)n; _shim_seterror("dart_lua_shim_setlocal: lua_Debug not supported"); return ""; }

const char* dart_lua_shim_setupvalue(lua_State* L, int funcindex, int n) { return lua_setupvalue(L, funcindex, n); }

void dart_lua_shim_setuservalue(lua_State* L, int idx) {
#if SHIM_LUA_53
    lua_setuservalue(L, idx);
#else
    lua_setiuservalue(L, idx, 0);
#endif
}

dart_lua_shim_void_result_t dart_lua_shim_setwarnf(lua_State* L, void* f, void* ud) {
#if SHIM_LUA_54
    lua_setwarnf(L, (lua_WarnFunction)f, ud);
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, NULL);
#else
    (void)L; (void)f; (void)ud;
    _shim_seterror("lua_setwarnf: not supported in Lua 5.3");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

size_t dart_lua_shim_stringtonumber(lua_State* L, const char* s) { return lua_stringtonumber(L, s); }

void* dart_lua_shim_tocfunction(lua_State* L, int idx) { return (void*)lua_tocfunction(L, idx); }

dart_lua_shim_void_result_t dart_lua_shim_toclose(lua_State* L, int idx) {
#if SHIM_LUA_54
    lua_toclose(L, idx);
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, NULL);
#else
    (void)L; (void)idx;
    _shim_seterror("lua_toclose: not supported in Lua 5.3");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

int64_t dart_lua_shim_tointeger(lua_State* L, int idx) { return (int64_t)lua_tointegerx(L, idx, NULL); }

double dart_lua_shim_tonumber(lua_State* L, int idx) { return lua_tonumberx(L, idx, NULL); }

const void* dart_lua_shim_topointer(lua_State* L, int idx) { return lua_topointer(L, idx); }

const char* dart_lua_shim_tostring(lua_State* L, int idx) { return lua_tolstring(L, idx, NULL); }

void* dart_lua_shim_upvalueid(lua_State* L, int fidx, int n) { return lua_upvalueid(L, fidx, n); }

int dart_lua_shim_upvalueindex(int i) { return LUA_REGISTRYINDEX - (i); }

void dart_lua_shim_upvaluejoin(lua_State* L, int fidx1, int n1, int fidx2, int n2) { lua_upvaluejoin(L, fidx1, n1, fidx2, n2); }

dart_lua_shim_void_result_t dart_lua_shim_warning(lua_State* L, const char* msg, int tocont) {
#if SHIM_LUA_54
    lua_warning(L, msg, tocont);
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, NULL);
#else
    (void)L; (void)msg; (void)tocont;
    _shim_seterror("lua_warning: not supported in Lua 5.3");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

int dart_lua_shim_yield(lua_State* L, int nresults) { return lua_yieldk(L, nresults, 0, NULL); }

/* ================================================================
 * auxlib 补全实现
 * ================================================================ */

void dart_lua_shimL_addchar(void* B, char c) { luaL_addchar((luaL_Buffer*)B, c); }

dart_lua_shim_void_result_t dart_lua_shimL_addgsub(void* B, const char* s, const char* p, const char* r) {
#if SHIM_LUA_54
    luaL_addgsub((luaL_Buffer*)B, s, p, r);
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, NULL);
#else
    (void)B; (void)s; (void)p; (void)r;
    _shim_seterror("luaL_addgsub: not supported in Lua 5.3");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

void dart_lua_shimL_addlstring(void* B, const char* s, size_t l) { luaL_addlstring((luaL_Buffer*)B, s, l); }

void dart_lua_shimL_addsize(void* B, size_t n) { luaL_addsize((luaL_Buffer*)B, n); }

void dart_lua_shimL_addstring(void* B, const char* s) { luaL_addstring((luaL_Buffer*)B, s); }

void dart_lua_shimL_addvalue(void* B) { luaL_addvalue((luaL_Buffer*)B); }

void dart_lua_shimL_argcheck(lua_State* L, int cond, int arg, const char* extramsg) { luaL_argcheck(L, cond, arg, extramsg); }

int dart_lua_shimL_argerror(lua_State* L, int arg, const char* extramsg) { return luaL_argerror(L, arg, extramsg); }

dart_lua_shim_void_result_t dart_lua_shimL_argexpected(lua_State* L, int cond, int arg, const char* tname) {
#if SHIM_LUA_54
    luaL_argexpected(L, cond, arg, tname);
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, NULL);
#else
    (void)L; (void)cond; (void)arg; (void)tname;
    _shim_seterror("luaL_argexpected: not supported in Lua 5.3");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

char* dart_lua_shimL_buffaddr(void* B) {
#if SHIM_LUA_54
    return luaL_buffaddr((luaL_Buffer*)B);
#else
    (void)B;
    _shim_seterror("luaL_buffaddr: not supported in Lua 5.3");
    return NULL;
#endif
}

void dart_lua_shimL_buffinit(lua_State* L, void* B) { luaL_buffinit(L, (luaL_Buffer*)B); }

char* dart_lua_shimL_buffinitsize(lua_State* L, void* B, size_t sz) { return luaL_buffinitsize(L, (luaL_Buffer*)B, sz); }

size_t dart_lua_shimL_bufflen(void* B) {
#if SHIM_LUA_54
    return luaL_bufflen((luaL_Buffer*)B);
#else
    (void)B;
    _shim_seterror("luaL_bufflen: not supported in Lua 5.3");
    return 0;
#endif
}

dart_lua_shim_void_result_t dart_lua_shimL_buffsub(void* B, int n) {
#if SHIM_LUA_54
    luaL_buffsub((luaL_Buffer*)B, n);
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, NULL);
#else
    (void)B; (void)n;
    _shim_seterror("luaL_buffsub: not supported in Lua 5.3");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

int dart_lua_shimL_callmeta(lua_State* L, int obj, const char* e) { return luaL_callmeta(L, obj, e); }

void dart_lua_shimL_checkany(lua_State* L, int arg) { luaL_checkany(L, arg); }

int64_t dart_lua_shimL_checkinteger(lua_State* L, int arg) { return (int64_t)luaL_checkinteger(L, arg); }

const char* dart_lua_shimL_checklstring(lua_State* L, int arg, size_t* l) { return luaL_checklstring(L, arg, l); }

double dart_lua_shimL_checknumber(lua_State* L, int arg) { return luaL_checknumber(L, arg); }

int dart_lua_shimL_checkoption(lua_State* L, int arg, const char* def, const char* const lst[]) { return luaL_checkoption(L, arg, def, lst); }

void dart_lua_shimL_checkstack(lua_State* L, int sz, const char* msg) { luaL_checkstack(L, sz, msg); }

const char* dart_lua_shimL_checkstring(lua_State* L, int arg) { return luaL_checkstring(L, arg); }

void dart_lua_shimL_checktype(lua_State* L, int arg, int t) { luaL_checktype(L, arg, t); }

void* dart_lua_shimL_checkudata(lua_State* L, int ud, const char* tname) { return luaL_checkudata(L, ud, tname); }

void dart_lua_shimL_checkversion(lua_State* L) { luaL_checkversion_(L, LUA_VERSION_NUM, LUAL_NUMSIZES); }

int dart_lua_shimL_dofile(lua_State* L, const char* fn) { return (luaL_loadfile(L, fn) || lua_pcall(L, 0, LUA_MULTRET, 0)); }

int dart_lua_shimL_dostring(lua_State* L, const char* s) { return (luaL_loadstring(L, s) || lua_pcall(L, 0, LUA_MULTRET, 0)); }

int dart_lua_shimL_error(lua_State* L, const char* fmt, ...) { (void)L; (void)fmt; _shim_seterror("dart_lua_shimL_error: varargs not supported"); return (int)LUA_SHIM_ERRERR; }

int dart_lua_shimL_execresult(lua_State* L, int stat) { return luaL_execresult(L, stat); }

int dart_lua_shimL_fileresult(lua_State* L, int stat, const char* fname) { return luaL_fileresult(L, stat, fname); }

int dart_lua_shimL_getmetafield(lua_State* L, int obj, const char* e) { return luaL_getmetafield(L, obj, e); }

int dart_lua_shimL_getmetatable(lua_State* L, const char* tname) { return luaL_getmetatable(L, tname); }

int dart_lua_shimL_getsubtable(lua_State* L, int idx, const char* fname) { return luaL_getsubtable(L, idx, fname); }

const char* dart_lua_shimL_gsub(lua_State* L, const char* s, const char* p, const char* r) { return luaL_gsub(L, s, p, r); }

int64_t dart_lua_shimL_len(lua_State* L, int idx) { return (int64_t)luaL_len(L, idx); }

int dart_lua_shimL_loadbuffer(lua_State* L, const char* buff, size_t sz, const char* name) { return luaL_loadbufferx(L, buff, sz, name, NULL); }

int dart_lua_shimL_loadbufferx(lua_State* L, const char* buff, size_t sz, const char* name, const char* mode) { return luaL_loadbufferx(L, buff, sz, name, mode); }

int dart_lua_shimL_loadfile(lua_State* L, const char* filename) { return luaL_loadfilex(L, filename, NULL); }

int dart_lua_shimL_loadfilex(lua_State* L, const char* filename, const char* mode) { return luaL_loadfilex(L, filename, mode); }

int dart_lua_shimL_loadstring(lua_State* L, const char* s) { return luaL_loadstring(L, s); }

void dart_lua_shimL_newlib(lua_State* L, void* l, int nrec) { luaL_checkversion_(L, LUA_VERSION_NUM, LUAL_NUMSIZES); lua_createtable(L, 0, nrec); luaL_setfuncs(L, (const luaL_Reg*)l, 0); }

void dart_lua_shimL_newlibtable(lua_State* L, int nrec) { lua_createtable(L, 0, nrec); }

int dart_lua_shimL_newmetatable(lua_State* L, const char* tname) { return luaL_newmetatable(L, tname); }

lua_State* dart_lua_shimL_newstate(void) { return luaL_newstate(); }

void dart_lua_shimL_openlibs(lua_State* L) { luaL_openlibs(L); }

void* dart_lua_shimL_opt(lua_State* L, void* f, int n, void* d) { (void)L; (void)f; (void)n; (void)d; _shim_seterror("dart_lua_shimL_opt: generic macro not supported"); return NULL; }

int64_t dart_lua_shimL_optinteger(lua_State* L, int arg, int64_t def) { return (int64_t)luaL_optinteger(L, arg, (lua_Integer)def); }

const char* dart_lua_shimL_optlstring(lua_State* L, int arg, const char* def, size_t* l) { return luaL_optlstring(L, arg, def, l); }

double dart_lua_shimL_optnumber(lua_State* L, int arg, double def) { return luaL_optnumber(L, arg, def); }

const char* dart_lua_shimL_optstring(lua_State* L, int arg, const char* def) { return luaL_optstring(L, arg, def); }

char* dart_lua_shimL_prepbuffer(void* B) { return luaL_prepbuffsize((luaL_Buffer*)B, LUAL_BUFFERSIZE); }

char* dart_lua_shimL_prepbuffsize(void* B, size_t sz) { return luaL_prepbuffsize((luaL_Buffer*)B, sz); }

void dart_lua_shimL_pushfail(lua_State* L) {
#if SHIM_LUA_54
    luaL_pushfail(L);
#else
    lua_pushnil(L);
#endif
}

void dart_lua_shimL_pushresult(void* B) { luaL_pushresult((luaL_Buffer*)B); }

void dart_lua_shimL_pushresultsize(void* B, size_t sz) { luaL_pushresultsize((luaL_Buffer*)B, sz); }

int dart_lua_shimL_ref(lua_State* L, int t) { return luaL_ref(L, t); }

void dart_lua_shimL_requiref(lua_State* L, const char* modname, void* openf, int glb) { luaL_requiref(L, modname, (lua_CFunction)openf, glb); }

void dart_lua_shimL_setfuncs(lua_State* L, void* l, int nup) { luaL_setfuncs(L, (const luaL_Reg*)l, nup); }

void dart_lua_shimL_setmetatable(lua_State* L, const char* tname) { luaL_setmetatable(L, tname); }

void* dart_lua_shimL_testudata(lua_State* L, int ud, const char* tname) { return luaL_testudata(L, ud, tname); }

const char* dart_lua_shimL_tolstring(lua_State* L, int idx, size_t* len) { return luaL_tolstring(L, idx, len); }

void dart_lua_shimL_traceback(lua_State* L, lua_State* L1, const char* msg, int level) { luaL_traceback(L, L1, msg, level); }

dart_lua_shim_int_result_t dart_lua_shimL_typeerror(lua_State* L, int arg, const char* tname) {
#if SHIM_LUA_54
    return RESULT_RET(int, const_char_ptr, luaL_typeerror(L, arg, tname), NULL);
#else
    (void)L; (void)arg; (void)tname;
    _shim_seterror("luaL_typeerror: not supported in Lua 5.3");
    return RESULT_RET(int, const_char_ptr, 0, "not supported in current Lua version");
#endif
}

const char* dart_lua_shimL_typename(lua_State* L, int idx) { return lua_typename(L, lua_type(L, idx)); }

void dart_lua_shimL_unref(lua_State* L, int t, int ref) { luaL_unref(L, t, ref); }

void dart_lua_shimL_where(lua_State* L, int lvl) { luaL_where(L, lvl); }

/* ================================================================
 * Lua 5.5 新增 API 占位实现
 * ================================================================ */

const char* dart_lua_shim_numbertocstring(lua_State* L, double n, size_t* len) {
    (void)L; (void)n; (void)len;
    _shim_seterror("lua_numbertocstring: Lua 5.5 API not available in current build");
    return NULL;
}

const char* dart_lua_shim_pushexternalstring(lua_State* L, const char* s, size_t len, void* ud) {
    (void)L; (void)s; (void)len; (void)ud;
    _shim_seterror("lua_pushexternalstring: Lua 5.5 API not available in current build");
    return NULL;
}

void* dart_lua_shimL_alloc(lua_State* L, void* ptr, size_t osize, size_t nsize) {
    (void)L; (void)ptr; (void)osize; (void)nsize;
    _shim_seterror("luaL_alloc: Lua 5.5 API not available in current build");
    return NULL;
}

uint64_t dart_lua_shimL_makeseed(lua_State* L) {
    (void)L;
    _shim_seterror("luaL_makeseed: Lua 5.5 API not available in current build");
    return 0;
}

dart_lua_shim_void_result_t dart_lua_shimL_openselectedlibs(lua_State* L, const char* libs) {
    (void)L; (void)libs;
    _shim_seterror("luaL_openselectedlibs: Lua 5.5 API not available in current build");
    return RESULT_RET(dart_lua_shim_never, const_char_ptr, 0, "not supported in current Lua version");
}
