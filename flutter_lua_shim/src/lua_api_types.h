#ifndef LUA_API_TYPES_H
#define LUA_API_TYPES_H

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ================================================================
 * 类型安全枚举（替代 Lua 源码中的裸 int 宏常量）
 *
 * 以下枚举值与 Lua 5.3/5.4 源码中的宏定义严格对应，
 * 确保 shim 层可直接进行 (int) 转换而不丢失语义。
 * ================================================================ */

/** Lua 值类型枚举。
 *
 *  对应 Lua 源码中的 LUA_TNONE / LUA_TNIL / LUA_TBOOLEAN 等。
 *  在 shim 层中，所有返回/接收 Lua 类型的 API 均使用此枚举。 */
typedef enum lua_shim_type {
    LUA_SHIM_TNONE          = -1,
    LUA_SHIM_TNIL           = 0,
    LUA_SHIM_TBOOLEAN       = 1,
    LUA_SHIM_TLIGHTUSERDATA = 2,
    LUA_SHIM_TNUMBER        = 3,
    LUA_SHIM_TSTRING        = 4,
    LUA_SHIM_TTABLE         = 5,
    LUA_SHIM_TFUNCTION      = 6,
    LUA_SHIM_TUSERDATA      = 7,
    LUA_SHIM_TTHREAD        = 8,
} lua_shim_type_t;

/** Lua 线程/调用状态枚举。
 *
 *  对应 LUA_OK / LUA_YIELD / LUA_ERRRUN 等。
 *  所有返回状态码的 API（pcall、resume、loadstring 等）均使用此枚举。 */
typedef enum lua_shim_status {
    LUA_SHIM_OK        = 0,
    LUA_SHIM_YIELD     = 1,
    LUA_SHIM_ERRRUN    = 2,
    LUA_SHIM_ERRSYNTAX = 3,
    LUA_SHIM_ERRMEM    = 4,
    LUA_SHIM_ERRGCMM   = 5,
    LUA_SHIM_ERRERR    = 6,
    LUA_SHIM_ERRNOTSUP = 7,
} lua_shim_status_t;

/** GC 操作枚举。
 *
 *  对应 LUA_GCSTOP / LUA_GCRESTART / LUA_GCCOLLECT 等。
 *  用于 lua_shim_gc() 的 what 参数。 */
typedef enum lua_shim_gc {
    LUA_SHIM_GC_STOP       = 0,
    LUA_SHIM_GC_RESTART    = 1,
    LUA_SHIM_GC_COLLECT    = 2,
    LUA_SHIM_GC_COUNT      = 3,
    LUA_SHIM_GC_COUNTB     = 4,
    LUA_SHIM_GC_STEP       = 5,
    LUA_SHIM_GC_SETPAUSE   = 6,
    LUA_SHIM_GC_SETSTEPMUL = 7,
    LUA_SHIM_GC_ISRUNNING  = 9,
} lua_shim_gc_t;

/** 算术操作枚举。
 *
 *  对应 LUA_OPADD / LUA_OPSUB / LUA_OPMUL 等。
 *  用于 lua_shim_arith() 的 op 参数。 */
typedef enum lua_shim_arith {
    LUA_SHIM_OPADD  = 0,
    LUA_SHIM_OPSUB  = 1,
    LUA_SHIM_OPMUL  = 2,
    LUA_SHIM_OPMOD  = 3,
    LUA_SHIM_OPPOW  = 4,
    LUA_SHIM_OPDIV  = 5,
    LUA_SHIM_OPIDIV = 6,
    LUA_SHIM_OPBAND = 7,
    LUA_SHIM_OPBOR  = 8,
    LUA_SHIM_OPBXOR = 9,
    LUA_SHIM_OPSHL  = 10,
    LUA_SHIM_OPSHR  = 11,
    LUA_SHIM_OPUNM  = 12,
    LUA_SHIM_OPBNOT = 13,
} lua_shim_arith_t;

/** 比较操作枚举。
 *
 *  对应 LUA_OPEQ / LUA_OPLT / LUA_OPLE。
 *  用于 lua_shim_compare() 的 op 参数。 */
typedef enum lua_shim_compare {
    LUA_SHIM_OPEQ = 0,
    LUA_SHIM_OPLT = 1,
    LUA_SHIM_OPLE = 2,
} lua_shim_compare_t;

/* ================================================================
 * 值容器 Union（工程中常用的跨层数据传递概念）
 *
 * 不属于 shim 层的核心职责，但为上层（如 Dart FFI 或后续桥接层）
 * 提供一个类型安全的“Lua 值”抽象，避免在 C 侧使用裸 void*。
 * ================================================================ */

/** 无标签的值 Union。调用方需自行保证读取的分支与 Lua 栈实际类型一致。 */
typedef union lua_shim_value {
    double      number;
    int64_t     integer;
    bool        boolean;
    const char* string;
    size_t      length;
    void*       pointer;
    struct lua_State* thread;
} lua_shim_value_t;

/** 带标签的值容器。status 表示操作结果，type + value 表示值内容。 */
typedef struct lua_shim_result {
    lua_shim_status_t status;   /**< 操作状态（OK / 错误码） */
    lua_shim_type_t   type;     /**< 值类型标签 */
    lua_shim_value_t  value;    /**< 值内容 */
} lua_shim_result_t;

#ifdef __cplusplus
}
#endif

#endif
