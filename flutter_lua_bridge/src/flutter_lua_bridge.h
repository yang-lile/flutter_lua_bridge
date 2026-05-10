#ifndef FLUTTER_LUA_BRIDGE_H
#define FLUTTER_LUA_BRIDGE_H

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ================================================================
 * 版本号
 * ================================================================ */

extern const int kLuaVersionReleaseNum;
extern const int kLuaRegistryIndex;

/* ================================================================
 * 类型枚举（使用 Lua 原始定义值）
 * ================================================================ */

/* Lua 值类型枚举 */
typedef enum FlbType {
    FLB_TNONE          = -1,
    FLB_TNIL           = 0,
    FLB_TBOOLEAN       = 1,
    FLB_TLIGHTUSERDATA = 2,
    FLB_TNUMBER        = 3,
    FLB_TSTRING        = 4,
    FLB_TTABLE         = 5,
    FLB_TFUNCTION      = 6,
    FLB_TUSERDATA      = 7,
    FLB_TTHREAD        = 8,
} FlbType;

/* Lua 线程/调用状态枚举 */
typedef enum FlbStatus {
    FLB_OK        = 0,
    FLB_YIELD     = 1,
    FLB_ERRRUN    = 2,
    FLB_ERRSYNTAX = 3,
    FLB_ERRMEM    = 4,
    FLB_ERRGCMM   = 5,
    FLB_ERRERR    = 6,
} FlbStatus;

/* GC 操作枚举 */
typedef enum FlbGC {
    FLB_GC_STOP       = 0,
    FLB_GC_RESTART    = 1,
    FLB_GC_COLLECT    = 2,
    FLB_GC_COUNT      = 3,
    FLB_GC_COUNTB     = 4,
    FLB_GC_STEP       = 5,
    FLB_GC_SETPAUSE   = 6,
    FLB_GC_SETSTEPMUL = 7,
    FLB_GC_ISRUNNING  = 9,
} FlbGC;

/* 算术操作枚举 */
typedef enum FlbArith {
    FLB_OPADD  = 0,
    FLB_OPSUB  = 1,
    FLB_OPMUL  = 2,
    FLB_OPDIV  = 4,
    FLB_OPMOD  = 5,
    FLB_OPPOW  = 6,
    FLB_OPUNM  = 7,
    FLB_OPBAND = 8,
    FLB_OPBOR  = 9,
    FLB_OPBXOR = 10,
    FLB_OPSHL  = 11,
    FLB_OPSHR  = 12,
    FLB_OPBNOT = 13,
} FlbArith;

/* 比较操作枚举 */
typedef enum FlbCompare {
    FLB_OPEQ = 0,
    FLB_OPLT = 1,
    FLB_OPLE = 2,
} FlbCompare;

/* ================================================================
 * C API 函数声明
 * ================================================================ */

typedef struct lua_State lua_State;

/* lua_absindex */
int flutter_lua_bridge_absindex(lua_State* L, int idx);

/* lua_arith */
void flutter_lua_bridge_arith(lua_State* L, int op);

/* lua_atpanic */
void* flutter_lua_bridge_atpanic(lua_State* L, void* panicf);

/* lua_call */
void flutter_lua_bridge_call(lua_State* L, int nargs, int nresults);

/* lua_callk */
void flutter_lua_bridge_callk(lua_State* L, int nargs, int nresults, int ctx, void* k);

/* lua_checkstack */
int flutter_lua_bridge_checkstack(lua_State* L, int n);

/* lua_close */
void flutter_lua_bridge_close(lua_State* L);

/* lua_closeslot */
int flutter_lua_bridge_closeslot(lua_State* L, int idx);

/* lua_closethread */
int flutter_lua_bridge_closethread(lua_State* L, lua_State* from);

/* lua_compare */
int flutter_lua_bridge_compare(lua_State* L, int idx1, int idx2, int op);

/* lua_concat */
void flutter_lua_bridge_concat(lua_State* L, int n);

/* lua_copy */
void flutter_lua_bridge_copy(lua_State* L, int fromidx, int toidx);

/* lua_createtable */
void flutter_lua_bridge_createtable(lua_State* L, int nseq, int nrec);

/* lua_dump */
int flutter_lua_bridge_dump(lua_State* L, void* writer, void* data, int strip);

/* lua_error */
int flutter_lua_bridge_error(lua_State* L);

/* lua_gc */
int flutter_lua_bridge_gc(lua_State* L, int what, int data);

/* lua_getallocf */
void* flutter_lua_bridge_getallocf(lua_State* L, void** ud);

/* lua_getextraspace */
void* flutter_lua_bridge_getextraspace(lua_State* L);

/* lua_getfield */
int flutter_lua_bridge_getfield(lua_State* L, int idx, const char* k);

/* lua_getglobal */
int flutter_lua_bridge_getglobal(lua_State* L, const char* name);

/* lua_gethook */
void* flutter_lua_bridge_gethook(lua_State* L);

/* lua_gethookcount */
int flutter_lua_bridge_gethookcount(lua_State* L);

/* lua_gethookmask */
int flutter_lua_bridge_gethookmask(lua_State* L);

/* lua_geti */
int flutter_lua_bridge_geti(lua_State* L, int idx, int64_t n);

/* lua_getinfo */
int flutter_lua_bridge_getinfo(lua_State* L, const char* what, void* ar);

/* lua_getiuservalue */
void flutter_lua_bridge_getiuservalue(lua_State* L, int idx, int n);

/* lua_getlocal */
const char* flutter_lua_bridge_getlocal(lua_State* L, void* ar, int n);

/* lua_getmetatable */
int flutter_lua_bridge_getmetatable(lua_State* L, int objindex);

/* lua_getstack */
int flutter_lua_bridge_getstack(lua_State* L, int level, void* ar);

/* lua_gettable */
int flutter_lua_bridge_gettable(lua_State* L, int idx);

/* lua_gettop */
int flutter_lua_bridge_gettop(lua_State* L);

/* lua_getupvalue */
const char* flutter_lua_bridge_getupvalue(lua_State* L, int funcindex, int n);

/* lua_getuservalue */
int flutter_lua_bridge_getuservalue(lua_State* L, int idx);

/* lua_insert */
void flutter_lua_bridge_insert(lua_State* L, int idx);

/* lua_isboolean */
int flutter_lua_bridge_isboolean(lua_State* L, int idx);

/* lua_iscfunction */
int flutter_lua_bridge_iscfunction(lua_State* L, int idx);

/* lua_isfunction */
int flutter_lua_bridge_isfunction(lua_State* L, int idx);

/* lua_isinteger */
int flutter_lua_bridge_isinteger(lua_State* L, int idx);

/* lua_islightuserdata */
int flutter_lua_bridge_islightuserdata(lua_State* L, int idx);

/* lua_isnil */
int flutter_lua_bridge_isnil(lua_State* L, int idx);

/* lua_isnone */
int flutter_lua_bridge_isnone(lua_State* L, int idx);

/* lua_isnoneornil */
int flutter_lua_bridge_isnoneornil(lua_State* L, int idx);

/* lua_isnumber */
int flutter_lua_bridge_isnumber(lua_State* L, int idx);

/* lua_isstring */
int flutter_lua_bridge_isstring(lua_State* L, int idx);

/* lua_istable */
int flutter_lua_bridge_istable(lua_State* L, int idx);

/* lua_isthread */
int flutter_lua_bridge_isthread(lua_State* L, int idx);

/* lua_isuserdata */
int flutter_lua_bridge_isuserdata(lua_State* L, int idx);

/* lua_isyieldable */
int flutter_lua_bridge_isyieldable(lua_State* L);

/* lua_len */
void flutter_lua_bridge_len(lua_State* L, int idx);

/* lua_load */
int flutter_lua_bridge_load(lua_State* L, void* reader, void* dt, const char* chunkname, const char* mode);

/* lua_newstate */
lua_State* flutter_lua_bridge_newstate(void* f, void* ud);

/* lua_newtable */
void flutter_lua_bridge_newtable(lua_State* L);

/* lua_newthread */
lua_State* flutter_lua_bridge_newthread(lua_State* L);

/* lua_newuserdata */
void* flutter_lua_bridge_newuserdata(lua_State* L, size_t sz);

/* lua_newuserdatauv */
void* flutter_lua_bridge_newuserdatauv(lua_State* L, size_t sz, int nuvalue);

/* lua_next */
int flutter_lua_bridge_next(lua_State* L, int idx);

/* lua_numbertocstring */
const char* flutter_lua_bridge_numbertocstring(lua_State* L, double n, size_t* len);

/* lua_numbertointeger */
int flutter_lua_bridge_numbertointeger(double n, int64_t* p);

/* lua_pcall */
int flutter_lua_bridge_pcall(lua_State* L, int nargs, int nresults, int errfunc);

/* lua_pcallk */
int flutter_lua_bridge_pcallk(lua_State* L, int nargs, int nresults, int errfunc, int ctx, void* k);

/* lua_pop */
void flutter_lua_bridge_pop(lua_State* L, int n);

/* lua_pushboolean */
void flutter_lua_bridge_pushboolean(lua_State* L, int b);

/* lua_pushcclosure */
void flutter_lua_bridge_pushcclosure(lua_State* L, void* fn, int n);

/* lua_pushcfunction */
void flutter_lua_bridge_pushcfunction(lua_State* L, void* f);

/* lua_pushexternalstring */
const char* flutter_lua_bridge_pushexternalstring(lua_State* L, const char* s, size_t len, void* falloc, void* ud);

/* lua_pushfstring */
const char* flutter_lua_bridge_pushfstring(lua_State* L, const char* fmt);

/* lua_pushglobaltable */
void flutter_lua_bridge_pushglobaltable(lua_State* L);

/* lua_pushinteger */
void flutter_lua_bridge_pushinteger(lua_State* L, int64_t n);

/* lua_pushlightuserdata */
void flutter_lua_bridge_pushlightuserdata(lua_State* L, void* p);

/* lua_pushliteral */
const char* flutter_lua_bridge_pushliteral(lua_State* L, const char* s);

/* lua_pushlstring */
const char* flutter_lua_bridge_pushlstring(lua_State* L, const char* s, size_t len);

/* lua_pushnil */
void flutter_lua_bridge_pushnil(lua_State* L);

/* lua_pushnumber */
void flutter_lua_bridge_pushnumber(lua_State* L, double n);

/* lua_pushstring */
const char* flutter_lua_bridge_pushstring(lua_State* L, const char* s);

/* lua_pushthread */
int flutter_lua_bridge_pushthread(lua_State* L);

/* lua_pushvalue */
void flutter_lua_bridge_pushvalue(lua_State* L, int idx);

/* lua_pushvfstring */
const char* flutter_lua_bridge_pushvfstring(lua_State* L, const char* fmt, ...);

/* lua_rawequal */
int flutter_lua_bridge_rawequal(lua_State* L, int idx1, int idx2);

/* lua_rawget */
int flutter_lua_bridge_rawget(lua_State* L, int idx);

/* lua_rawgeti */
int flutter_lua_bridge_rawgeti(lua_State* L, int idx, int64_t n);

/* lua_rawgetp */
int flutter_lua_bridge_rawgetp(lua_State* L, int idx, const void* p);

/* lua_rawlen */
size_t flutter_lua_bridge_rawlen(lua_State* L, int idx);

/* lua_rawset */
void flutter_lua_bridge_rawset(lua_State* L, int idx);

/* lua_rawseti */
void flutter_lua_bridge_rawseti(lua_State* L, int idx, int64_t n);

/* lua_rawsetp */
void flutter_lua_bridge_rawsetp(lua_State* L, int idx, const void* p);

/* lua_register */
void flutter_lua_bridge_register(lua_State* L, const char* n, void* f);

/* lua_remove */
void flutter_lua_bridge_remove(lua_State* L, int idx);

/* lua_replace */
void flutter_lua_bridge_replace(lua_State* L, int idx);

/* lua_resetthread */
int flutter_lua_bridge_resetthread(lua_State* L);

/* lua_resume */
int flutter_lua_bridge_resume(lua_State* L, lua_State* from, int narg, int* nres);

/* lua_rotate */
void flutter_lua_bridge_rotate(lua_State* L, int idx, int n);

/* lua_setallocf */
void flutter_lua_bridge_setallocf(lua_State* L, void* f, void* ud);

/* lua_setfield */
void flutter_lua_bridge_setfield(lua_State* L, int idx, const char* k);

/* lua_setglobal */
void flutter_lua_bridge_setglobal(lua_State* L, const char* name);

/* lua_sethook */
void flutter_lua_bridge_sethook(lua_State* L, void* func, int mask, int count);

/* lua_seti */
void flutter_lua_bridge_seti(lua_State* L, int idx, int64_t n);

/* lua_setiuservalue */
void flutter_lua_bridge_setiuservalue(lua_State* L, int idx, int n);

/* lua_setlocal */
const char* flutter_lua_bridge_setlocal(lua_State* L, void* ar, int n);

/* lua_setmetatable */
void flutter_lua_bridge_setmetatable(lua_State* L, int idx);

/* lua_settable */
void flutter_lua_bridge_settable(lua_State* L, int idx);

/* lua_settop */
void flutter_lua_bridge_settop(lua_State* L, int idx);

/* lua_setupvalue */
const char* flutter_lua_bridge_setupvalue(lua_State* L, int funcindex, int n);

/* lua_setuservalue */
void flutter_lua_bridge_setuservalue(lua_State* L, int idx);

/* lua_setwarnf */
void flutter_lua_bridge_setwarnf(lua_State* L, void* f, void* ud);

/* lua_status */
int flutter_lua_bridge_status(lua_State* L);

/* lua_stringtonumber */
size_t flutter_lua_bridge_stringtonumber(lua_State* L, const char* s);

/* lua_toboolean */
int flutter_lua_bridge_toboolean(lua_State* L, int idx);

/* lua_tocfunction */
void* flutter_lua_bridge_tocfunction(lua_State* L, int idx);

/* lua_toclose */
void flutter_lua_bridge_toclose(lua_State* L, int idx);

/* lua_tointeger */
int64_t flutter_lua_bridge_tointeger(lua_State* L, int idx);

/* lua_tointegerx */
int64_t flutter_lua_bridge_tointegerx(lua_State* L, int idx, int* isnum);

/* lua_tolstring */
const char* flutter_lua_bridge_tolstring(lua_State* L, int idx, size_t* len);

/* lua_tonumber */
double flutter_lua_bridge_tonumber(lua_State* L, int idx);

/* lua_tonumberx */
double flutter_lua_bridge_tonumberx(lua_State* L, int idx, int* isnum);

/* lua_topointer */
const void* flutter_lua_bridge_topointer(lua_State* L, int idx);

/* lua_tostring */
const char* flutter_lua_bridge_tostring(lua_State* L, int idx);

/* lua_tothread */
lua_State* flutter_lua_bridge_tothread(lua_State* L, int idx);

/* lua_touserdata */
void* flutter_lua_bridge_touserdata(lua_State* L, int idx);

/* lua_type */
int flutter_lua_bridge_type(lua_State* L, int idx);

/* lua_typename */
const char* flutter_lua_bridge_typename(lua_State* L, int tp);

/* lua_upvalueid */
void* flutter_lua_bridge_upvalueid(lua_State* L, int fidx, int n);

/* lua_upvalueindex */
int flutter_lua_bridge_upvalueindex(int i);

/* lua_upvaluejoin */
void flutter_lua_bridge_upvaluejoin(lua_State* L, int fidx1, int n1, int fidx2, int n2);

/* lua_version */
double flutter_lua_bridge_version(lua_State* L);

/* lua_warning */
void flutter_lua_bridge_warning(lua_State* L, const char* msg, int tocont);

/* lua_xmove */
void flutter_lua_bridge_xmove(lua_State* from, lua_State* to, int n);

/* lua_yield */
int flutter_lua_bridge_yield(lua_State* L, int nresults);

/* lua_yieldk */
int flutter_lua_bridge_yieldk(lua_State* L, int nresults, int ctx, void* k);

/* ================================================================
 * Auxlib API 函数声明
 * ================================================================ */

/* luaL_addchar */
void flutter_lua_bridgeL_addchar(void* B, char c);

/* luaL_addgsub */
void flutter_lua_bridgeL_addgsub(void* B, const char* s, const char* p, const char* r);

/* luaL_addlstring */
void flutter_lua_bridgeL_addlstring(void* B, const char* s, size_t l);

/* luaL_addsize */
void flutter_lua_bridgeL_addsize(void* B, size_t n);

/* luaL_addstring */
void flutter_lua_bridgeL_addstring(void* B, const char* s);

/* luaL_addvalue */
void flutter_lua_bridgeL_addvalue(void* B);

/* luaL_alloc */
void* flutter_lua_bridgeL_alloc(void* ud, void* ptr, size_t osize, size_t nsize);

/* luaL_argcheck */
void flutter_lua_bridgeL_argcheck(lua_State* L, int cond, int arg, const char* extramsg);

/* luaL_argerror */
int flutter_lua_bridgeL_argerror(lua_State* L, int arg, const char* extramsg);

/* luaL_argexpected */
void flutter_lua_bridgeL_argexpected(lua_State* L, int cond, int arg, const char* tname);

/* luaL_buffaddr */
char* flutter_lua_bridgeL_buffaddr(void* B);

/* luaL_buffinit */
void flutter_lua_bridgeL_buffinit(lua_State* L, void* B);

/* luaL_buffinitsize */
char* flutter_lua_bridgeL_buffinitsize(lua_State* L, void* B, size_t sz);

/* luaL_bufflen */
size_t flutter_lua_bridgeL_bufflen(void* B);

/* luaL_buffsub */
void flutter_lua_bridgeL_buffsub(void* B, int n);

/* luaL_callmeta */
int flutter_lua_bridgeL_callmeta(lua_State* L, int obj, const char* e);

/* luaL_checkany */
void flutter_lua_bridgeL_checkany(lua_State* L, int arg);

/* luaL_checkinteger */
int64_t flutter_lua_bridgeL_checkinteger(lua_State* L, int arg);

/* luaL_checklstring */
const char* flutter_lua_bridgeL_checklstring(lua_State* L, int arg, size_t* l);

/* luaL_checknumber */
double flutter_lua_bridgeL_checknumber(lua_State* L, int arg);

/* luaL_checkoption */
int flutter_lua_bridgeL_checkoption(lua_State* L, int arg, const char* def, const char* const lst[]);

/* luaL_checkstack */
void flutter_lua_bridgeL_checkstack(lua_State* L, int sz, const char* msg);

/* luaL_checkstring */
const char* flutter_lua_bridgeL_checkstring(lua_State* L, int arg);

/* luaL_checktype */
void flutter_lua_bridgeL_checktype(lua_State* L, int arg, int t);

/* luaL_checkudata */
void* flutter_lua_bridgeL_checkudata(lua_State* L, int ud, const char* tname);

/* luaL_checkversion */
void flutter_lua_bridgeL_checkversion(lua_State* L);

/* luaL_dofile */
int flutter_lua_bridgeL_dofile(lua_State* L, const char* fn);

/* luaL_dostring */
int flutter_lua_bridgeL_dostring(lua_State* L, const char* s);

/* luaL_error */
int flutter_lua_bridgeL_error(lua_State* L, const char* fmt);

/* luaL_execresult */
int flutter_lua_bridgeL_execresult(lua_State* L, int stat);

/* luaL_fileresult */
int flutter_lua_bridgeL_fileresult(lua_State* L, int stat, const char* fname);

/* luaL_getmetafield */
int flutter_lua_bridgeL_getmetafield(lua_State* L, int obj, const char* e);

/* luaL_getmetatable */
int flutter_lua_bridgeL_getmetatable(lua_State* L, const char* tname);

/* luaL_getsubtable */
int flutter_lua_bridgeL_getsubtable(lua_State* L, int idx, const char* fname);

/* luaL_gsub */
const char* flutter_lua_bridgeL_gsub(lua_State* L, const char* s, const char* p, const char* r);

/* luaL_len */
int64_t flutter_lua_bridgeL_len(lua_State* L, int idx);

/* luaL_loadbuffer */
int flutter_lua_bridgeL_loadbuffer(lua_State* L, const char* buff, size_t sz, const char* name);

/* luaL_loadbufferx */
int flutter_lua_bridgeL_loadbufferx(lua_State* L, const char* buff, size_t sz, const char* name, const char* mode);

/* luaL_loadfile */
int flutter_lua_bridgeL_loadfile(lua_State* L, const char* filename);

/* luaL_loadfilex */
int flutter_lua_bridgeL_loadfilex(lua_State* L, const char* filename, const char* mode);

/* luaL_loadstring */
int flutter_lua_bridgeL_loadstring(lua_State* L, const char* s);

/* luaL_makeseed */
uint64_t flutter_lua_bridgeL_makeseed(lua_State* L);

/* luaL_newlib */
void flutter_lua_bridgeL_newlib(lua_State* L, void* l, int nrec);

/* luaL_newlibtable */
void flutter_lua_bridgeL_newlibtable(lua_State* L, int nrec);

/* luaL_newmetatable */
int flutter_lua_bridgeL_newmetatable(lua_State* L, const char* tname);

/* luaL_newstate */
lua_State* flutter_lua_bridgeL_newstate(void);

/* luaL_openlibs */
void flutter_lua_bridgeL_openlibs(lua_State* L);

/* luaL_openselectedlibs */
void flutter_lua_bridgeL_openselectedlibs(lua_State* L, const char* libs);

/* luaL_opt - 已移除，因为它是宏定义 */

/* luaL_optinteger */
int64_t flutter_lua_bridgeL_optinteger(lua_State* L, int arg, int64_t d);

/* luaL_optlstring */
const char* flutter_lua_bridgeL_optlstring(lua_State* L, int arg, const char* d, size_t* l);

/* luaL_optnumber */
double flutter_lua_bridgeL_optnumber(lua_State* L, int arg, double d);

/* luaL_optstring */
const char* flutter_lua_bridgeL_optstring(lua_State* L, int arg, const char* d);

/* luaL_prepbuffer */
char* flutter_lua_bridgeL_prepbuffer(void* B);

/* luaL_prepbuffsize */
char* flutter_lua_bridgeL_prepbuffsize(void* B, size_t sz);

/* luaL_pushfail */
void flutter_lua_bridgeL_pushfail(lua_State* L);

/* luaL_pushresult */
void flutter_lua_bridgeL_pushresult(void* B);

/* luaL_pushresultsize */
void flutter_lua_bridgeL_pushresultsize(void* B, size_t sz);

/* luaL_ref */
int flutter_lua_bridgeL_ref(lua_State* L, int t);

/* luaL_requiref */
void flutter_lua_bridgeL_requiref(lua_State* L, const char* modname, void* openf, int glb);

/* luaL_setfuncs */
void flutter_lua_bridgeL_setfuncs(lua_State* L, void* l, int nup);

/* luaL_setmetatable */
void flutter_lua_bridgeL_setmetatable(lua_State* L, const char* tname);

/* luaL_testudata */
void* flutter_lua_bridgeL_testudata(lua_State* L, int ud, const char* tname);

/* luaL_tolstring */
const char* flutter_lua_bridgeL_tolstring(lua_State* L, int idx, size_t* len);

/* luaL_traceback */
void flutter_lua_bridgeL_traceback(lua_State* L, lua_State* L1, const char* msg, int level);

/* luaL_typeerror */
int flutter_lua_bridgeL_typeerror(lua_State* L, int arg, const char* tname);

/* luaL_typename */
const char* flutter_lua_bridgeL_typename(lua_State* L, int idx);

/* luaL_unref */
void flutter_lua_bridgeL_unref(lua_State* L, int t, int ref);

/* luaL_where */
void flutter_lua_bridgeL_where(lua_State* L, int lvl);

#ifdef __cplusplus
}
#endif

#endif // FLUTTER_LUA_BRIDGE_H
