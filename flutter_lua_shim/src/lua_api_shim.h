#ifndef LUA_API_SHIM_H
#define LUA_API_SHIM_H

#include "lua_api_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct lua_State lua_State;

typedef int (*DartCFunction)(lua_State* L);

void lua_shimL_addchar(void* B, char c);

void lua_shimL_addgsub(void* B, const char* s, const char* p, const char* r);

void lua_shimL_addlstring(void* B, const char* s, size_t l);

void lua_shimL_addsize(void* B, size_t n);

void lua_shimL_addstring(void* B, const char* s);

void lua_shimL_addvalue(void* B);

void* lua_shimL_alloc(lua_State* L, void* ptr, size_t osize, size_t nsize);

void lua_shimL_argcheck(lua_State* L, int cond, int arg, const char* extramsg);

int lua_shimL_argerror(lua_State* L, int arg, const char* extramsg);

void lua_shimL_argexpected(lua_State* L, int cond, int arg, const char* tname);

char* lua_shimL_buffaddr(void* B);

void lua_shimL_buffinit(lua_State* L, void* B);

char* lua_shimL_buffinitsize(lua_State* L, void* B, size_t sz);

size_t lua_shimL_bufflen(void* B);

void lua_shimL_buffsub(void* B, int n);

int lua_shimL_callmeta(lua_State* L, int obj, const char* e);

void lua_shimL_checkany(lua_State* L, int arg);

int64_t lua_shimL_checkinteger(lua_State* L, int arg);

const char* lua_shimL_checklstring(lua_State* L, int arg, size_t* l);

double lua_shimL_checknumber(lua_State* L, int arg);

int lua_shimL_checkoption(lua_State* L, int arg, const char* def, const char* const lst[]);

void lua_shimL_checkstack(lua_State* L, int sz, const char* msg);

const char* lua_shimL_checkstring(lua_State* L, int arg);

void lua_shimL_checktype(lua_State* L, int arg, int t);

void* lua_shimL_checkudata(lua_State* L, int ud, const char* tname);

void lua_shimL_checkversion(lua_State* L);

int lua_shimL_dofile(lua_State* L, const char* fn);

int lua_shimL_dostring(lua_State* L, const char* s);

int lua_shimL_error(lua_State* L, const char* fmt, ...);

int lua_shimL_execresult(lua_State* L, int stat);

int lua_shimL_fileresult(lua_State* L, int stat, const char* fname);

int lua_shimL_getmetafield(lua_State* L, int obj, const char* e);

int lua_shimL_getmetatable(lua_State* L, const char* tname);

int lua_shimL_getsubtable(lua_State* L, int idx, const char* fname);

const char* lua_shimL_gsub(lua_State* L, const char* s, const char* p, const char* r);

int64_t lua_shimL_len(lua_State* L, int idx);

int lua_shimL_loadbuffer(lua_State* L, const char* buff, size_t sz, const char* name);

int lua_shimL_loadbufferx(lua_State* L, const char* buff, size_t sz, const char* name, const char* mode);

int lua_shimL_loadfile(lua_State* L, const char* filename);

int lua_shimL_loadfilex(lua_State* L, const char* filename, const char* mode);

int lua_shimL_loadstring(lua_State* L, const char* s);

uint64_t lua_shimL_makeseed(lua_State* L);

void lua_shimL_newlib(lua_State* L, void* l, int nrec);

void lua_shimL_newlibtable(lua_State* L, int nrec);

int lua_shimL_newmetatable(lua_State* L, const char* tname);

lua_State* lua_shimL_newstate(void);

void lua_shimL_openlibs(lua_State* L);

void lua_shimL_openselectedlibs(lua_State* L, const char* libs);

void* lua_shimL_opt(lua_State* L, void* f, int n, void* d);

int64_t lua_shimL_optinteger(lua_State* L, int arg, int64_t def);

const char* lua_shimL_optlstring(lua_State* L, int arg, const char* def, size_t* l);

double lua_shimL_optnumber(lua_State* L, int arg, double def);

const char* lua_shimL_optstring(lua_State* L, int arg, const char* def);

char* lua_shimL_prepbuffer(void* B);

char* lua_shimL_prepbuffsize(void* B, size_t sz);

void lua_shimL_pushfail(lua_State* L);

void lua_shimL_pushresult(void* B);

void lua_shimL_pushresultsize(void* B, size_t sz);

int lua_shimL_ref(lua_State* L, int t);

void lua_shimL_requiref(lua_State* L, const char* modname, void* openf, int glb);

void lua_shimL_setfuncs(lua_State* L, void* l, int nup);

void lua_shimL_setmetatable(lua_State* L, const char* tname);

void* lua_shimL_testudata(lua_State* L, int ud, const char* tname);

const char* lua_shimL_tolstring(lua_State* L, int idx, size_t* len);

void lua_shimL_traceback(lua_State* L, lua_State* L1, const char* msg, int level);

int lua_shimL_typeerror(lua_State* L, int arg, const char* tname);

const char* lua_shimL_typename(lua_State* L, int idx);

void lua_shimL_unref(lua_State* L, int t, int ref);

void lua_shimL_where(lua_State* L, int lvl);

int lua_shim_absindex(lua_State* L, int idx);

void lua_shim_arith(lua_State* L, lua_shim_arith_t op);

void* lua_shim_atpanic(lua_State* L, void* panicf);

void lua_shim_call(lua_State* L, int nargs, int nresults);

void lua_shim_callk(lua_State* L, int nargs, int nresults, int64_t ctx, void* k);

int lua_shim_checkstack(lua_State* L, int n);

void lua_shim_close(lua_State* L);

void lua_shim_closeslot(lua_State* L, int idx);

int lua_shim_closethread(lua_State* L, lua_State* from);

int lua_shim_compare(lua_State* L, int idx1, int idx2, lua_shim_compare_t op);

void lua_shim_concat(lua_State* L, int n);

void lua_shim_copy(lua_State* L, int fromidx, int toidx);

void lua_shim_createtable(lua_State* L, int narr, int nrec);

int lua_shim_dump(lua_State* L, void* writer, void* data, int strip);

lua_shim_status_t lua_shim_error(lua_State* L);

int lua_shim_gc(lua_State* L, lua_shim_gc_t what, int data);

void* lua_shim_getallocf(lua_State* L, void** ud);

void* lua_shim_getextraspace(lua_State* L);

lua_shim_type_t lua_shim_getfield(lua_State* L, int idx, const char* k);

lua_shim_type_t lua_shim_getglobal(lua_State* L, const char* name);

void* lua_shim_gethook(lua_State* L);

int lua_shim_gethookcount(lua_State* L);

int lua_shim_gethookmask(lua_State* L);

int lua_shim_geti(lua_State* L, int idx, int64_t n);

int lua_shim_getinfo(lua_State* L, const char* what, void* ar);

void lua_shim_getiuservalue(lua_State* L, int idx, int n);

const char* lua_shim_getlocal(lua_State* L, void* ar, int n);

int lua_shim_getmetatable(lua_State* L, int objindex);

int lua_shim_getstack(lua_State* L, int level, void* ar);

void lua_shim_gettable(lua_State* L, int idx);

int lua_shim_gettop(lua_State* L);

const char* lua_shim_getupvalue(lua_State* L, int funcindex, int n);

int lua_shim_getuservalue(lua_State* L, int idx);

void lua_shim_insert(lua_State* L, int idx);

bool lua_shim_isboolean(lua_State* L, int idx);

bool lua_shim_iscfunction(lua_State* L, int idx);

bool lua_shim_isfunction(lua_State* L, int idx);

int lua_shim_isinteger(lua_State* L, int idx);

bool lua_shim_islightuserdata(lua_State* L, int idx);

bool lua_shim_isnil(lua_State* L, int idx);

int lua_shim_isnone(lua_State* L, int idx);

int lua_shim_isnoneornil(lua_State* L, int idx);

bool lua_shim_isnumber(lua_State* L, int idx);

bool lua_shim_isstring(lua_State* L, int idx);

bool lua_shim_istable(lua_State* L, int idx);

bool lua_shim_isthread(lua_State* L, int idx);

bool lua_shim_isuserdata(lua_State* L, int idx);

int lua_shim_isyieldable(lua_State* L);

const char* lua_shim_lasterror(void);

void lua_shim_len(lua_State* L, int idx);

int lua_shim_load(lua_State* L, void* reader, void* dt, const char* chunkname, const char* mode);

lua_shim_status_t lua_shim_loadstring(lua_State* L, const char* s);

lua_State* lua_shim_newstate(void);

void lua_shim_newtable(lua_State* L);

lua_State* lua_shim_newthread(lua_State* L);

void* lua_shim_newuserdata(lua_State* L, size_t sz);

void* lua_shim_newuserdatauv(lua_State* L, size_t sz, int nuvalue);

int lua_shim_next(lua_State* L, int idx);

const char* lua_shim_numbertocstring(lua_State* L, double n, size_t* len);

int lua_shim_numbertointeger(double n, int64_t* p);

void lua_shim_open_base(lua_State* L);

void lua_shim_open_debug(lua_State* L);

void lua_shim_open_io(lua_State* L);

void lua_shim_open_math(lua_State* L);

void lua_shim_open_os(lua_State* L);

void lua_shim_open_package(lua_State* L);

void lua_shim_open_string(lua_State* L);

void lua_shim_open_table(lua_State* L);

void lua_shim_open_utf8(lua_State* L);

void lua_shim_openlibs(lua_State* L);

lua_shim_status_t lua_shim_pcall(lua_State* L, int nargs, int nresults, int errfunc);

lua_shim_status_t lua_shim_pcallk(lua_State* L, int nargs, int nresults, int errfunc, int64_t ctx, void* k);

void lua_shim_pop(lua_State* L, int n);

void lua_shim_pushboolean(lua_State* L, bool b);

void lua_shim_pushcclosure(lua_State* L, void* fn, int n);

void lua_shim_pushcfunction(lua_State* L, void* f);

void lua_shim_pushdartfunction(lua_State* L, DartCFunction f);

const char* lua_shim_pushexternalstring(lua_State* L, const char* s, size_t len, void* ud);

const char* lua_shim_pushfstring(lua_State* L, const char* fmt, ...);

void lua_shim_pushglobaltable(lua_State* L);

void lua_shim_pushinteger(lua_State* L, int64_t n);

void lua_shim_pushlightuserdata(lua_State* L, void* p);

const char* lua_shim_pushliteral(lua_State* L, const char* s);

void lua_shim_pushlstring(lua_State* L, const char* s, size_t len);

void lua_shim_pushnil(lua_State* L);

void lua_shim_pushnumber(lua_State* L, double n);

void lua_shim_pushstring(lua_State* L, const char* s);

int lua_shim_pushthread(lua_State* L);

void lua_shim_pushvalue(lua_State* L, int idx);

const char* lua_shim_pushvfstring(lua_State* L, const char* fmt, void* argp);

int lua_shim_rawequal(lua_State* L, int idx1, int idx2);

void lua_shim_rawget(lua_State* L, int idx);

void lua_shim_rawgeti(lua_State* L, int idx, int64_t n);

void lua_shim_rawgetp(lua_State* L, int idx, const void* p);

size_t lua_shim_rawlen(lua_State* L, int idx);

void lua_shim_rawset(lua_State* L, int idx);

void lua_shim_rawseti(lua_State* L, int idx, int64_t n);

void lua_shim_rawsetp(lua_State* L, int idx, const void* p);

int lua_shim_ref(lua_State* L, int t);

void lua_shim_register(lua_State* L, const char* n, void* f);

void lua_shim_remove(lua_State* L, int idx);

void lua_shim_replace(lua_State* L, int idx);

int lua_shim_resetthread(lua_State* L);

lua_shim_status_t lua_shim_resume(lua_State* L, lua_State* from, int narg, int* nres);

void lua_shim_rotate(lua_State* L, int idx, int n);

void lua_shim_setallocf(lua_State* L, void* f, void* ud);

void lua_shim_setfield(lua_State* L, int idx, const char* k);

void lua_shim_setglobal(lua_State* L, const char* name);

int lua_shim_sethook(lua_State* L, void* func, int mask, int count);

void lua_shim_seti(lua_State* L, int idx, int64_t n);

void lua_shim_setiuservalue(lua_State* L, int idx, int n);

const char* lua_shim_setlocal(lua_State* L, void* ar, int n);

void lua_shim_setmetatable(lua_State* L, int objindex);

void lua_shim_settable(lua_State* L, int idx);

void lua_shim_settop(lua_State* L, int idx);

const char* lua_shim_setupvalue(lua_State* L, int funcindex, int n);

void lua_shim_setuservalue(lua_State* L, int idx);

void lua_shim_setwarnf(lua_State* L, void* f, void* ud);

lua_shim_status_t lua_shim_status(lua_State* L);

size_t lua_shim_stringtonumber(lua_State* L, const char* s);

lua_shim_status_t lua_shim_throwstring(lua_State* L, const char* s);

bool lua_shim_toboolean(lua_State* L, int idx);

void* lua_shim_tocfunction(lua_State* L, int idx);

void lua_shim_toclose(lua_State* L, int idx);

int64_t lua_shim_tointeger(lua_State* L, int idx);

int64_t lua_shim_tointegerx(lua_State* L, int idx, bool* isnum);

const char* lua_shim_tolstring(lua_State* L, int idx, size_t* len);

double lua_shim_tonumber(lua_State* L, int idx);

double lua_shim_tonumberx(lua_State* L, int idx, bool* isnum);

const void* lua_shim_topointer(lua_State* L, int idx);

const char* lua_shim_tostring(lua_State* L, int idx);

lua_State* lua_shim_tothread(lua_State* L, int idx);

void* lua_shim_touserdata(lua_State* L, int idx);

lua_shim_type_t lua_shim_type(lua_State* L, int idx);

const char* lua_shim_typename(lua_State* L, lua_shim_type_t tp);

void lua_shim_unref(lua_State* L, int t, int ref);

void* lua_shim_upvalueid(lua_State* L, int fidx, int n);

int lua_shim_upvalueindex(int i);

void lua_shim_upvaluejoin(lua_State* L, int fidx1, int n1, int fidx2, int n2);

double lua_shim_version(lua_State* L);

void lua_shim_warning(lua_State* L, const char* msg, int tocont);

void lua_shim_xmove(lua_State* L, lua_State* to, int n);

int lua_shim_yield(lua_State* L, int nresults);

lua_shim_status_t lua_shim_yieldk(lua_State* L, int nresults, int64_t ctx, void* k);

#ifdef __cplusplus
}
#endif

#endif