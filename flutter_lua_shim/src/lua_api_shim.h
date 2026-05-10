#ifndef LUA_API_SHIM_H
#define LUA_API_SHIM_H

#include "lua_api_types.h"
#include "result.h"

/* 通用结果类型 */
typedef const char* const_char_ptr;

typedef int dart_lua_shim_never;
DEF_RESULT(dart_lua_shim_never, const_char_ptr);
typedef dart_lua_shim_never_const_char_ptr_result dart_lua_shim_void_result_t;

DEF_RESULT(int, const_char_ptr);
typedef int_const_char_ptr_result dart_lua_shim_int_result_t;
#if defined(_WIN32)
  #define DART_LUA_SHIM_API __declspec(dllexport)
#elif defined(__GNUC__) && __GNUC__ >= 4
  #define DART_LUA_SHIM_API __attribute__((visibility("default")))
#else
  #define DART_LUA_SHIM_API
#endif


#ifdef __cplusplus
extern "C" {
#endif

DART_LUA_SHIM_API extern const int kLuaVersionReleaseNum;

typedef struct lua_State lua_State;

typedef int (*DartCFunction)(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shimL_addchar(void* B, char c);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shimL_addgsub(void* B, const char* s, const char* p, const char* r);

DART_LUA_SHIM_API void dart_lua_shimL_addlstring(void* B, const char* s, size_t l);

DART_LUA_SHIM_API void dart_lua_shimL_addsize(void* B, size_t n);

DART_LUA_SHIM_API void dart_lua_shimL_addstring(void* B, const char* s);

DART_LUA_SHIM_API void dart_lua_shimL_addvalue(void* B);

DART_LUA_SHIM_API void* dart_lua_shimL_alloc(lua_State* L, void* ptr, size_t osize, size_t nsize);

DART_LUA_SHIM_API void dart_lua_shimL_argcheck(lua_State* L, int cond, int arg, const char* extramsg);

DART_LUA_SHIM_API int dart_lua_shimL_argerror(lua_State* L, int arg, const char* extramsg);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shimL_argexpected(lua_State* L, int cond, int arg, const char* tname);

DART_LUA_SHIM_API char* dart_lua_shimL_buffaddr(void* B);

DART_LUA_SHIM_API void dart_lua_shimL_buffinit(lua_State* L, void* B);

DART_LUA_SHIM_API char* dart_lua_shimL_buffinitsize(lua_State* L, void* B, size_t sz);

DART_LUA_SHIM_API size_t dart_lua_shimL_bufflen(void* B);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shimL_buffsub(void* B, int n);

DART_LUA_SHIM_API int dart_lua_shimL_callmeta(lua_State* L, int obj, const char* e);

DART_LUA_SHIM_API void dart_lua_shimL_checkany(lua_State* L, int arg);

DART_LUA_SHIM_API int64_t dart_lua_shimL_checkinteger(lua_State* L, int arg);

DART_LUA_SHIM_API const char* dart_lua_shimL_checklstring(lua_State* L, int arg, size_t* l);

DART_LUA_SHIM_API double dart_lua_shimL_checknumber(lua_State* L, int arg);

DART_LUA_SHIM_API int dart_lua_shimL_checkoption(lua_State* L, int arg, const char* def, const char* const lst[]);

DART_LUA_SHIM_API void dart_lua_shimL_checkstack(lua_State* L, int sz, const char* msg);

DART_LUA_SHIM_API const char* dart_lua_shimL_checkstring(lua_State* L, int arg);

DART_LUA_SHIM_API void dart_lua_shimL_checktype(lua_State* L, int arg, int t);

DART_LUA_SHIM_API void* dart_lua_shimL_checkudata(lua_State* L, int ud, const char* tname);

DART_LUA_SHIM_API void dart_lua_shimL_checkversion(lua_State* L);

DART_LUA_SHIM_API int dart_lua_shimL_dofile(lua_State* L, const char* fn);

DART_LUA_SHIM_API int dart_lua_shimL_dostring(lua_State* L, const char* s);

DART_LUA_SHIM_API int dart_lua_shimL_error(lua_State* L, const char* fmt, ...);

DART_LUA_SHIM_API int dart_lua_shimL_execresult(lua_State* L, int stat);

DART_LUA_SHIM_API int dart_lua_shimL_fileresult(lua_State* L, int stat, const char* fname);

DART_LUA_SHIM_API int dart_lua_shimL_getmetafield(lua_State* L, int obj, const char* e);

DART_LUA_SHIM_API int dart_lua_shimL_getmetatable(lua_State* L, const char* tname);

DART_LUA_SHIM_API int dart_lua_shimL_getsubtable(lua_State* L, int idx, const char* fname);

DART_LUA_SHIM_API const char* dart_lua_shimL_gsub(lua_State* L, const char* s, const char* p, const char* r);

DART_LUA_SHIM_API int64_t dart_lua_shimL_len(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shimL_loadbuffer(lua_State* L, const char* buff, size_t sz, const char* name);

DART_LUA_SHIM_API int dart_lua_shimL_loadbufferx(lua_State* L, const char* buff, size_t sz, const char* name, const char* mode);

DART_LUA_SHIM_API int dart_lua_shimL_loadfile(lua_State* L, const char* filename);

DART_LUA_SHIM_API int dart_lua_shimL_loadfilex(lua_State* L, const char* filename, const char* mode);

DART_LUA_SHIM_API int dart_lua_shimL_loadstring(lua_State* L, const char* s);

DART_LUA_SHIM_API uint64_t dart_lua_shimL_makeseed(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shimL_newlib(lua_State* L, void* l, int nrec);

DART_LUA_SHIM_API void dart_lua_shimL_newlibtable(lua_State* L, int nrec);

DART_LUA_SHIM_API int dart_lua_shimL_newmetatable(lua_State* L, const char* tname);

DART_LUA_SHIM_API lua_State* dart_lua_shimL_newstate(void);

DART_LUA_SHIM_API void dart_lua_shimL_openlibs(lua_State* L);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shimL_openselectedlibs(lua_State* L, const char* libs);

DART_LUA_SHIM_API void* dart_lua_shimL_opt(lua_State* L, void* f, int n, void* d);

DART_LUA_SHIM_API int64_t dart_lua_shimL_optinteger(lua_State* L, int arg, int64_t def);

DART_LUA_SHIM_API const char* dart_lua_shimL_optlstring(lua_State* L, int arg, const char* def, size_t* l);

DART_LUA_SHIM_API double dart_lua_shimL_optnumber(lua_State* L, int arg, double def);

DART_LUA_SHIM_API const char* dart_lua_shimL_optstring(lua_State* L, int arg, const char* def);

DART_LUA_SHIM_API char* dart_lua_shimL_prepbuffer(void* B);

DART_LUA_SHIM_API char* dart_lua_shimL_prepbuffsize(void* B, size_t sz);

DART_LUA_SHIM_API void dart_lua_shimL_pushfail(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shimL_pushresult(void* B);

DART_LUA_SHIM_API void dart_lua_shimL_pushresultsize(void* B, size_t sz);

DART_LUA_SHIM_API int dart_lua_shimL_ref(lua_State* L, int t);

DART_LUA_SHIM_API void dart_lua_shimL_requiref(lua_State* L, const char* modname, void* openf, int glb);

DART_LUA_SHIM_API void dart_lua_shimL_setfuncs(lua_State* L, void* l, int nup);

DART_LUA_SHIM_API void dart_lua_shimL_setmetatable(lua_State* L, const char* tname);

DART_LUA_SHIM_API void* dart_lua_shimL_testudata(lua_State* L, int ud, const char* tname);

DART_LUA_SHIM_API const char* dart_lua_shimL_tolstring(lua_State* L, int idx, size_t* len);

DART_LUA_SHIM_API void dart_lua_shimL_traceback(lua_State* L, lua_State* L1, const char* msg, int level);

DART_LUA_SHIM_API dart_lua_shim_int_result_t dart_lua_shimL_typeerror(lua_State* L, int arg, const char* tname);

DART_LUA_SHIM_API const char* dart_lua_shimL_typename(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shimL_unref(lua_State* L, int t, int ref);

DART_LUA_SHIM_API void dart_lua_shimL_where(lua_State* L, int lvl);

DART_LUA_SHIM_API int dart_lua_shim_absindex(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shim_arith(lua_State* L, lua_shim_arith_t op);

DART_LUA_SHIM_API void* dart_lua_shim_atpanic(lua_State* L, void* panicf);

DART_LUA_SHIM_API void dart_lua_shim_call(lua_State* L, int nargs, int nresults);

DART_LUA_SHIM_API void dart_lua_shim_callk(lua_State* L, int nargs, int nresults, int64_t ctx, void* k);

DART_LUA_SHIM_API int dart_lua_shim_checkstack(lua_State* L, int n);

DART_LUA_SHIM_API void dart_lua_shim_close(lua_State* L);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shim_closeslot(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shim_closethread(lua_State* L, lua_State* from);

DART_LUA_SHIM_API int dart_lua_shim_compare(lua_State* L, int idx1, int idx2, lua_shim_compare_t op);

DART_LUA_SHIM_API void dart_lua_shim_concat(lua_State* L, int n);

DART_LUA_SHIM_API void dart_lua_shim_copy(lua_State* L, int fromidx, int toidx);

DART_LUA_SHIM_API void dart_lua_shim_createtable(lua_State* L, int narr, int nrec);

DART_LUA_SHIM_API int dart_lua_shim_dump(lua_State* L, void* writer, void* data, int strip);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_error(lua_State* L);

DART_LUA_SHIM_API int dart_lua_shim_gc(lua_State* L, lua_shim_gc_t what, int data);

DART_LUA_SHIM_API void* dart_lua_shim_getallocf(lua_State* L, void** ud);

DART_LUA_SHIM_API void* dart_lua_shim_getextraspace(lua_State* L);

DART_LUA_SHIM_API lua_shim_type_t dart_lua_shim_getfield(lua_State* L, int idx, const char* k);

DART_LUA_SHIM_API lua_shim_type_t dart_lua_shim_getglobal(lua_State* L, const char* name);

DART_LUA_SHIM_API void* dart_lua_shim_gethook(lua_State* L);

DART_LUA_SHIM_API int dart_lua_shim_gethookcount(lua_State* L);

DART_LUA_SHIM_API int dart_lua_shim_gethookmask(lua_State* L);

DART_LUA_SHIM_API int dart_lua_shim_geti(lua_State* L, int idx, int64_t n);

DART_LUA_SHIM_API int dart_lua_shim_getinfo(lua_State* L, const char* what, void* ar);

DART_LUA_SHIM_API void dart_lua_shim_getiuservalue(lua_State* L, int idx, int n);

DART_LUA_SHIM_API const char* dart_lua_shim_getlocal(lua_State* L, void* ar, int n);

DART_LUA_SHIM_API int dart_lua_shim_getmetatable(lua_State* L, int objindex);

DART_LUA_SHIM_API int dart_lua_shim_getstack(lua_State* L, int level, void* ar);

DART_LUA_SHIM_API void dart_lua_shim_gettable(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shim_gettop(lua_State* L);

DART_LUA_SHIM_API const char* dart_lua_shim_getupvalue(lua_State* L, int funcindex, int n);

DART_LUA_SHIM_API int dart_lua_shim_getuservalue(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shim_insert(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_isboolean(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_iscfunction(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_isfunction(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shim_isinteger(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_islightuserdata(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_isnil(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shim_isnone(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shim_isnoneornil(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_isnumber(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_isstring(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_istable(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_isthread(lua_State* L, int idx);

DART_LUA_SHIM_API bool dart_lua_shim_isuserdata(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shim_isyieldable(lua_State* L);

DART_LUA_SHIM_API const char* dart_lua_shim_lasterror(void);

DART_LUA_SHIM_API void dart_lua_shim_len(lua_State* L, int idx);

DART_LUA_SHIM_API int dart_lua_shim_load(lua_State* L, void* reader, void* dt, const char* chunkname, const char* mode);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_loadstring(lua_State* L, const char* s);

DART_LUA_SHIM_API lua_State* dart_lua_shim_newstate(void);

DART_LUA_SHIM_API void dart_lua_shim_newtable(lua_State* L);

DART_LUA_SHIM_API lua_State* dart_lua_shim_newthread(lua_State* L);

DART_LUA_SHIM_API void* dart_lua_shim_newuserdata(lua_State* L, size_t sz);

DART_LUA_SHIM_API void* dart_lua_shim_newuserdatauv(lua_State* L, size_t sz, int nuvalue);

DART_LUA_SHIM_API int dart_lua_shim_next(lua_State* L, int idx);

DART_LUA_SHIM_API const char* dart_lua_shim_numbertocstring(lua_State* L, double n, size_t* len);

DART_LUA_SHIM_API int dart_lua_shim_numbertointeger(double n, int64_t* p);

DART_LUA_SHIM_API void dart_lua_shim_open_base(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_debug(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_io(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_math(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_os(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_package(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_string(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_table(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_open_utf8(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_openlibs(lua_State* L);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_pcall(lua_State* L, int nargs, int nresults, int errfunc);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_pcallk(lua_State* L, int nargs, int nresults, int errfunc, int64_t ctx, void* k);

DART_LUA_SHIM_API void dart_lua_shim_pop(lua_State* L, int n);

DART_LUA_SHIM_API void dart_lua_shim_pushboolean(lua_State* L, bool b);

DART_LUA_SHIM_API void dart_lua_shim_pushcclosure(lua_State* L, void* fn, int n);

DART_LUA_SHIM_API void dart_lua_shim_pushcfunction(lua_State* L, void* f);

void dart_lua_shim_pushdartfunction(lua_State* L, DartCFunction f);

DART_LUA_SHIM_API const char* dart_lua_shim_pushexternalstring(lua_State* L, const char* s, size_t len, void* ud);

DART_LUA_SHIM_API const char* dart_lua_shim_pushfstring(lua_State* L, const char* fmt, ...);

DART_LUA_SHIM_API void dart_lua_shim_pushglobaltable(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_pushinteger(lua_State* L, int64_t n);

DART_LUA_SHIM_API void dart_lua_shim_pushlightuserdata(lua_State* L, void* p);

DART_LUA_SHIM_API const char* dart_lua_shim_pushliteral(lua_State* L, const char* s);

DART_LUA_SHIM_API void dart_lua_shim_pushlstring(lua_State* L, const char* s, size_t len);

DART_LUA_SHIM_API void dart_lua_shim_pushnil(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_pushnumber(lua_State* L, double n);

DART_LUA_SHIM_API void dart_lua_shim_pushstring(lua_State* L, const char* s);

DART_LUA_SHIM_API int dart_lua_shim_pushthread(lua_State* L);

DART_LUA_SHIM_API void dart_lua_shim_pushvalue(lua_State* L, int idx);

DART_LUA_SHIM_API const char* dart_lua_shim_pushvfstring(lua_State* L, const char* fmt, void* argp);

DART_LUA_SHIM_API int dart_lua_shim_rawequal(lua_State* L, int idx1, int idx2);

DART_LUA_SHIM_API void dart_lua_shim_rawget(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shim_rawgeti(lua_State* L, int idx, int64_t n);

DART_LUA_SHIM_API void dart_lua_shim_rawgetp(lua_State* L, int idx, const void* p);

DART_LUA_SHIM_API size_t dart_lua_shim_rawlen(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shim_rawset(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shim_rawseti(lua_State* L, int idx, int64_t n);

DART_LUA_SHIM_API void dart_lua_shim_rawsetp(lua_State* L, int idx, const void* p);

DART_LUA_SHIM_API int dart_lua_shim_ref(lua_State* L, int t);

DART_LUA_SHIM_API void dart_lua_shim_register(lua_State* L, const char* n, void* f);

DART_LUA_SHIM_API void dart_lua_shim_remove(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shim_replace(lua_State* L, int idx);

DART_LUA_SHIM_API dart_lua_shim_int_result_t dart_lua_shim_resetthread(lua_State* L);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_resume(lua_State* L, lua_State* from, int narg, int* nres);

DART_LUA_SHIM_API void dart_lua_shim_rotate(lua_State* L, int idx, int n);

DART_LUA_SHIM_API void dart_lua_shim_setallocf(lua_State* L, void* f, void* ud);

DART_LUA_SHIM_API void dart_lua_shim_setfield(lua_State* L, int idx, const char* k);

DART_LUA_SHIM_API void dart_lua_shim_setglobal(lua_State* L, const char* name);

DART_LUA_SHIM_API int dart_lua_shim_sethook(lua_State* L, void* func, int mask, int count);

DART_LUA_SHIM_API void dart_lua_shim_seti(lua_State* L, int idx, int64_t n);

DART_LUA_SHIM_API void dart_lua_shim_setiuservalue(lua_State* L, int idx, int n);

DART_LUA_SHIM_API const char* dart_lua_shim_setlocal(lua_State* L, void* ar, int n);

DART_LUA_SHIM_API void dart_lua_shim_setmetatable(lua_State* L, int objindex);

DART_LUA_SHIM_API void dart_lua_shim_settable(lua_State* L, int idx);

DART_LUA_SHIM_API void dart_lua_shim_settop(lua_State* L, int idx);

DART_LUA_SHIM_API const char* dart_lua_shim_setupvalue(lua_State* L, int funcindex, int n);

DART_LUA_SHIM_API void dart_lua_shim_setuservalue(lua_State* L, int idx);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shim_setwarnf(lua_State* L, void* f, void* ud);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_status(lua_State* L);

DART_LUA_SHIM_API size_t dart_lua_shim_stringtonumber(lua_State* L, const char* s);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_throwstring(lua_State* L, const char* s);

DART_LUA_SHIM_API bool dart_lua_shim_toboolean(lua_State* L, int idx);

DART_LUA_SHIM_API void* dart_lua_shim_tocfunction(lua_State* L, int idx);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shim_toclose(lua_State* L, int idx);

DART_LUA_SHIM_API int64_t dart_lua_shim_tointeger(lua_State* L, int idx);

DART_LUA_SHIM_API int64_t dart_lua_shim_tointegerx(lua_State* L, int idx, bool* isnum);

DART_LUA_SHIM_API const char* dart_lua_shim_tolstring(lua_State* L, int idx, size_t* len);

DART_LUA_SHIM_API double dart_lua_shim_tonumber(lua_State* L, int idx);

DART_LUA_SHIM_API double dart_lua_shim_tonumberx(lua_State* L, int idx, bool* isnum);

DART_LUA_SHIM_API const void* dart_lua_shim_topointer(lua_State* L, int idx);

DART_LUA_SHIM_API const char* dart_lua_shim_tostring(lua_State* L, int idx);

DART_LUA_SHIM_API lua_State* dart_lua_shim_tothread(lua_State* L, int idx);

DART_LUA_SHIM_API void* dart_lua_shim_touserdata(lua_State* L, int idx);

DART_LUA_SHIM_API lua_shim_type_t dart_lua_shim_type(lua_State* L, int idx);

DART_LUA_SHIM_API const char* dart_lua_shim_typename(lua_State* L, lua_shim_type_t tp);

DART_LUA_SHIM_API void dart_lua_shim_unref(lua_State* L, int t, int ref);

DART_LUA_SHIM_API void* dart_lua_shim_upvalueid(lua_State* L, int fidx, int n);

DART_LUA_SHIM_API int dart_lua_shim_upvalueindex(int i);

DART_LUA_SHIM_API void dart_lua_shim_upvaluejoin(lua_State* L, int fidx1, int n1, int fidx2, int n2);

DART_LUA_SHIM_API double dart_lua_shim_version(lua_State* L);

DART_LUA_SHIM_API dart_lua_shim_void_result_t dart_lua_shim_warning(lua_State* L, const char* msg, int tocont);

DART_LUA_SHIM_API void dart_lua_shim_xmove(lua_State* L, lua_State* to, int n);

DART_LUA_SHIM_API int dart_lua_shim_yield(lua_State* L, int nresults);

DART_LUA_SHIM_API lua_shim_status_t dart_lua_shim_yieldk(lua_State* L, int nresults, int64_t ctx, void* k);

#ifdef __cplusplus
}
#endif

#endif