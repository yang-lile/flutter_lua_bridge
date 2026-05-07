#ifndef LUA_API_SHIM_H
#define LUA_API_SHIM_H

#include "lua_api_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct lua_State lua_State;

/* ================================================================
 * 状态管理
 * ================================================================ */
lua_State*       lua_shim_newstate(void);
void             lua_shim_close(lua_State* L);
lua_shim_status_t lua_shim_status(lua_State* L);

/* ================================================================
 * 栈操作
 * ================================================================ */
int  lua_shim_gettop(lua_State* L);
void lua_shim_settop(lua_State* L, int idx);
void lua_shim_pushvalue(lua_State* L, int idx);
void lua_shim_copy(lua_State* L, int fromidx, int toidx);
int  lua_shim_checkstack(lua_State* L, int n);
void lua_shim_xmove(lua_State* L, lua_State* to, int n);

/* ---------- 以下函数在 Lua 源码中由宏定义，shim 层显式化为真实函数 ---------- */

/** 弹出栈顶 n 个元素。
 *  Lua 宏: lua_pop(L,n) => lua_settop(L, -(n)-1) */
void lua_shim_pop(lua_State* L, int n);

/** 移除指定索引处的元素。
 *  Lua 5.3+ 宏: lua_remove(L,idx) => (lua_rotate(L, (idx), -1), lua_pop(L, 1)) */
void lua_shim_remove(lua_State* L, int idx);

/** 将栈顶元素插入到指定索引处。
 *  Lua 5.3+ 宏: lua_insert(L,idx) => lua_rotate(L, (idx), 1) */
void lua_shim_insert(lua_State* L, int idx);

/** 用栈顶元素替换指定索引处的值，并弹出栈顶。
 *  Lua 5.3+ 宏: lua_replace(L,idx) => (lua_copy(L, -1, (idx)), lua_pop(L, 1)) */
void lua_shim_replace(lua_State* L, int idx);

/* ================================================================
 * 类型检查
 * ================================================================ */
bool lua_shim_isnil(lua_State* L, int idx);
bool lua_shim_isboolean(lua_State* L, int idx);
bool lua_shim_isnumber(lua_State* L, int idx);
bool lua_shim_isstring(lua_State* L, int idx);
bool lua_shim_istable(lua_State* L, int idx);
bool lua_shim_isfunction(lua_State* L, int idx);
bool lua_shim_iscfunction(lua_State* L, int idx);
bool lua_shim_isuserdata(lua_State* L, int idx);
bool lua_shim_islightuserdata(lua_State* L, int idx);
bool lua_shim_isthread(lua_State* L, int idx);

lua_shim_type_t lua_shim_type(lua_State* L, int idx);
const char*    lua_shim_typename(lua_State* L, lua_shim_type_t tp);

/* ================================================================
 * 转换
 * ================================================================ */
double      lua_shim_tonumberx(lua_State* L, int idx, bool* isnum);
int64_t     lua_shim_tointegerx(lua_State* L, int idx, bool* isnum);
bool        lua_shim_toboolean(lua_State* L, int idx);
const char* lua_shim_tolstring(lua_State* L, int idx, size_t* len);
size_t      lua_shim_rawlen(lua_State* L, int idx);
void*       lua_shim_touserdata(lua_State* L, int idx);
lua_State*  lua_shim_tothread(lua_State* L, int idx);

/* ================================================================
 * 压栈
 * ================================================================ */
void lua_shim_pushnil(lua_State* L);
void lua_shim_pushnumber(lua_State* L, double n);
void lua_shim_pushinteger(lua_State* L, int64_t n);
void lua_shim_pushlstring(lua_State* L, const char* s, size_t len);
void lua_shim_pushstring(lua_State* L, const char* s);
void lua_shim_pushboolean(lua_State* L, bool b);
void lua_shim_pushlightuserdata(lua_State* L, void* p);
void lua_shim_pushcclosure(lua_State* L, void* fn, int n);

/* ================================================================
 * 获取操作
 * ================================================================ */
void lua_shim_gettable(lua_State* L, int idx);

/** 返回字段值的类型（Lua 5.3+ 中 lua_getfield 返回 int 类型码）。 */
lua_shim_type_t lua_shim_getfield(lua_State* L, int idx, const char* k);

void lua_shim_rawget(lua_State* L, int idx);
void lua_shim_rawgeti(lua_State* L, int idx, int64_t n);
void lua_shim_rawgetp(lua_State* L, int idx, const void* p);

/** 创建新表。
 *  Lua 宏: lua_newtable(L) => lua_createtable(L, 0, 0) */
void lua_shim_newtable(lua_State* L);

void lua_shim_createtable(lua_State* L, int narr, int nrec);
void* lua_shim_newuserdatauv(lua_State* L, size_t sz, int nuvalue);
int   lua_shim_getmetatable(lua_State* L, int objindex);
void  lua_shim_getiuservalue(lua_State* L, int idx, int n);

/* ================================================================
 * 设置操作
 * ================================================================ */
void lua_shim_settable(lua_State* L, int idx);
void lua_shim_setfield(lua_State* L, int idx, const char* k);
void lua_shim_rawset(lua_State* L, int idx);
void lua_shim_rawseti(lua_State* L, int idx, int64_t n);
void lua_shim_rawsetp(lua_State* L, int idx, const void* p);
void lua_shim_setmetatable(lua_State* L, int objindex);
void lua_shim_setiuservalue(lua_State* L, int idx, int n);

/* ================================================================
 * 全局环境
 * ================================================================ */

/** 将全局变量 name 的值压入栈。
 *  Lua 5.3+ 中 lua_getglobal 返回 int 类型码。 */
lua_shim_type_t lua_shim_getglobal(lua_State* L, const char* name);

void lua_shim_setglobal(lua_State* L, const char* name);

/* ================================================================
 * 调用
 * ================================================================ */
lua_shim_status_t lua_shim_pcallk(lua_State* L, int nargs, int nresults, int errfunc, int64_t ctx, void* k);
lua_shim_status_t lua_shim_resume(lua_State* L, lua_State* from, int narg, int* nres);
lua_shim_status_t lua_shim_yieldk(lua_State* L, int nresults, int64_t ctx, void* k);
lua_shim_status_t lua_shim_loadstring(lua_State* L, const char* s);

/* ================================================================
 * 算术与比较
 * ================================================================ */
void lua_shim_arith(lua_State* L, lua_shim_arith_t op);
int  lua_shim_compare(lua_State* L, int idx1, int idx2, lua_shim_compare_t op);
void lua_shim_len(lua_State* L, int idx);
void lua_shim_concat(lua_State* L, int n);

/* ================================================================
 * 垃圾回收
 * ================================================================ */
int lua_shim_gc(lua_State* L, lua_shim_gc_t what, int data);

/* ================================================================
 * 错误处理
 * ================================================================ */
lua_shim_status_t lua_shim_error(lua_State* L);
lua_shim_status_t lua_shim_throwstring(lua_State* L, const char* s);

/* ================================================================
 * 标准库
 * ================================================================ */
void lua_shim_openlibs(lua_State* L);
void lua_shim_open_base(lua_State* L);
void lua_shim_open_table(lua_State* L);
void lua_shim_open_io(lua_State* L);
void lua_shim_open_os(lua_State* L);
void lua_shim_open_string(lua_State* L);
void lua_shim_open_math(lua_State* L);
void lua_shim_open_utf8(lua_State* L);
void lua_shim_open_debug(lua_State* L);
void lua_shim_open_package(lua_State* L);

/* ================================================================
 * 协程
 * ================================================================ */
lua_State* lua_shim_newthread(lua_State* L);
int        lua_shim_closethread(lua_State* L, lua_State* from);

/* ================================================================
 * 辅助函数
 * ================================================================ */
int  lua_shim_ref(lua_State* L, int t);
void lua_shim_unref(lua_State* L, int t, int ref);

/* ================================================================
 * 内存分配器
 * ================================================================ */
void lua_shim_setallocf(lua_State* L, void* f, void* ud);

/* ================================================================
 * 版本
 * ================================================================ */
double lua_shim_version(lua_State* L);

/* ================================================================
 * 注册 Dart 回调（特殊）
 * ================================================================ */
typedef int (*DartCFunction)(lua_State* L);
void lua_shim_pushdartfunction(lua_State* L, DartCFunction f);

#ifdef __cplusplus
}
#endif

#endif
