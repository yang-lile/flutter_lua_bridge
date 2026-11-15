/*
 * flb: a stable, high-level C interface to Lua for host language bindings.
 *
 * The header exposes no Lua type and no Lua constant, so one set of host
 * bindings works against Lua 5.3, 5.4 and 5.5. All differences between those
 * releases are handled in flb.c.
 *
 * Model
 * -----
 * - There is no stack. Values cross the boundary as `flb_value`.
 * - nil, booleans, integers, numbers and strings are passed by value.
 * - Tables, functions, userdata and threads are passed as references
 *   (`flb_ref`). Every reference the host receives is owned by the host and
 *   must be released with `flb_release` or through a reference token.
 * - Every operation that can raise a Lua error runs protected. A Lua error
 *   never unwinds through a host frame; it is reported as a status code and
 *   the details are read with `flb_error_*`.
 *
 * Memory returned to the host
 * ---------------------------
 * `flb_value` arrays and string bytes returned by a call belong to the state
 * and stay valid until the next flb call on that state made at the same
 * nesting level (calls made from inside a host function use their own
 * storage). Copy what you need before calling again. References inside those
 * values are not affected by this rule: they stay valid until released.
 *
 * Threads
 * -------
 * A state is used from one thread at a time. The only functions that may be
 * called from any thread are `flb_interrupt`, `flb_token_release` and
 * `flb_state_release`.
 */
#ifndef FLB_H
#define FLB_H

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#define FLB_API __declspec(dllexport)
#else
#define FLB_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define FLB_ABI_VERSION 1

typedef struct flb_state flb_state;

/* A host-owned reference to a Lua value. 0 is never a valid reference. */
typedef int64_t flb_ref;

/* Status codes. FLB_YIELD is returned only by flb_resume. */
enum {
  FLB_OK = 0,
  FLB_YIELD = 1,
  FLB_ERROR_RUNTIME = 2,
  FLB_ERROR_SYNTAX = 3,
  FLB_ERROR_MEMORY = 4,
  FLB_ERROR_HANDLER = 5,     /* error while running the message handler */
  FLB_ERROR_ARGUMENT = 100,  /* the host passed an invalid argument */
  FLB_ERROR_CLOSED = 101,    /* the state has been closed */
  FLB_ERROR_INTERRUPTED = 102,
  FLB_ERROR_HOST = 103       /* a host function failed; see flb_error_host_id */
};

/* Value types. Integers and floating point numbers are distinct. */
enum {
  FLB_NIL = 0,
  FLB_BOOLEAN = 1,
  FLB_INTEGER = 2,
  FLB_NUMBER = 3,
  FLB_STRING = 4,
  FLB_TABLE = 5,
  FLB_FUNCTION = 6,
  FLB_USERDATA = 7,
  FLB_THREAD = 8,
  FLB_LIGHTUSERDATA = 9,
  /* A table passed by value instead of by reference; see flb_copy. */
  FLB_TABLE_VALUE = 10
};

/*
 * A Lua value.
 *
 *   type                 fields used
 *   FLB_NIL             -
 *   FLB_BOOLEAN         i (0 or 1)
 *   FLB_INTEGER         i
 *   FLB_NUMBER          n
 *   FLB_STRING          bytes, length (not NUL terminated; any bytes)
 *   FLB_TABLE           i (flb_ref)
 *   FLB_FUNCTION        i (flb_ref)
 *   FLB_USERDATA        i (flb_ref), id (host object id, 0 if not a host object)
 *   FLB_THREAD          i (flb_ref)
 *   FLB_LIGHTUSERDATA   i (the pointer value)
 *   FLB_TABLE_VALUE     items, length (number of key/value pairs; items holds
 *                        key0, value0, key1, value1, ...)
 *
 * When the host passes a value in, string bytes are copied and references are
 * borrowed (the host keeps ownership). When the host receives a value,
 * references in it are new and owned by the host.
 *
 * Every function that takes values accepts FLB_TABLE_VALUE and builds a new
 * Lua table from it (nested up to 64 levels). The host receives
 * FLB_TABLE_VALUE only from flb_copy and in the arguments of a host function
 * created with FLB_FUNCTION_BY_VALUE.
 */
typedef struct flb_value {
  int32_t type;
  int64_t i;
  double n;
  const char *bytes;
  size_t length;
  int64_t id;
  const struct flb_value *items;
} flb_value;

/* Standard libraries selectable in flb_options.libraries. */
enum {
  FLB_LIB_BASE = 1 << 0,
  FLB_LIB_COROUTINE = 1 << 1,
  FLB_LIB_TABLE = 1 << 2,
  FLB_LIB_STRING = 1 << 3,
  FLB_LIB_MATH = 1 << 4,
  FLB_LIB_UTF8 = 1 << 5,
  /* `require` and `package`, limited to modules provided by the host through
   * flb_preload and flb_add_searcher. No file or native library loading. */
  FLB_LIB_REQUIRE = 1 << 6,
  FLB_LIB_IO = 1 << 7,
  FLB_LIB_OS = 1 << 8,
  FLB_LIB_DEBUG = 1 << 9,
  /* The unrestricted `package` library. Implies FLB_LIB_REQUIRE. */
  FLB_LIB_PACKAGE = 1 << 10,
  /* Libraries that cannot reach the file system, processes or native code.
   * `dofile` and `loadfile` are removed and `load` accepts text chunks only
   * unless FLB_LIB_IO is selected. */
  FLB_LIBS_SAFE = (1 << 7) - 1,
  FLB_LIBS_ALL = (1 << 11) - 1
};

/*
 * Called when Lua calls a host function created with flb_function_new.
 *
 * The host reads `arguments`, then reports the outcome by calling exactly one
 * of flb_return or flb_fail before returning. Returning without calling
 * either means "no results". The host may call other flb functions on
 * `state` while inside the callback.
 */
typedef void (*flb_host_call)(flb_state *state, int64_t function_id,
                               const flb_value *arguments, size_t count);

/*
 * Called when Lua no longer references a host function (function id) or a
 * host object (object id). `is_object` tells which. Must not call back into
 * flb. Not called for a state released through flb_state_release from a
 * finalizer; the host drops everything belonging to that state itself.
 */
typedef void (*flb_host_release)(flb_state *state, int64_t id,
                                  int32_t is_object);

typedef struct flb_options {
  uint32_t libraries;         /* FLB_LIB_* mask */
  size_t memory_limit;        /* bytes, 0 for no limit */
  flb_host_call call;        /* may be NULL if no host function is created */
  flb_host_release release;  /* may be NULL */
} flb_options;

/* ---- Library ----------------------------------------------------------- */

FLB_API int32_t flb_abi_version(void);
/* 503, 504 or 505. */
FLB_API int32_t flb_lua_version(void);
/* For example "Lua 5.4.9". */
FLB_API const char *flb_lua_release(void);
/* A static name for a status code, for example "runtime error". */
FLB_API const char *flb_status_name(int32_t status);
/* A static name for a value type, for example "table". */
FLB_API const char *flb_type_name(int32_t type);

/* ---- State ------------------------------------------------------------- */

/* Returns NULL if memory cannot be allocated. `options` may be NULL. */
FLB_API flb_state *flb_open(const flb_options *options);
/*
 * Closes the Lua VM. All references become invalid. The `flb_state` itself
 * stays valid (every call returns FLB_ERROR_CLOSED) until the owner releases
 * it with flb_state_release. Closing twice is harmless. Must not be called
 * from inside a host function.
 */
FLB_API void flb_close(flb_state *state);
FLB_API int32_t flb_is_closed(const flb_state *state);
/*
 * Drops the owner's hold on the state, closing it first if needed. Thread
 * safe and usable as a native finalizer (`void (*)(void *)`). The state is
 * freed once every reference token has been released as well.
 */
FLB_API void flb_state_release(void *state);

/* ---- Errors ------------------------------------------------------------ */

/* Details of the last failed call on this state. Valid until the next call. */
FLB_API const char *flb_error_message(const flb_state *state, size_t *length);
FLB_API const char *flb_error_traceback(const flb_state *state,
                                          size_t *length);
/* The id given to flb_fail when the error came from a host function that was
 * not handled by Lua code, otherwise 0. Lets the host rethrow its own error. */
FLB_API int64_t flb_error_host_id(const flb_state *state);

/* ---- Resources --------------------------------------------------------- */

FLB_API size_t flb_memory_used(const flb_state *state);
FLB_API size_t flb_memory_limit(const flb_state *state);
FLB_API void flb_set_memory_limit(flb_state *state, size_t bytes);

enum { FLB_GC_COLLECT = 0, FLB_GC_STOP = 1, FLB_GC_RESTART = 2, FLB_GC_STEP = 3 };
FLB_API int32_t flb_gc(flb_state *state, int32_t what);

/*
 * Makes running Lua code fail with FLB_ERROR_INTERRUPTED. Thread safe. Lua
 * code cannot catch the interruption. It is cleared when the outermost call
 * returns to the host. Interruption is checked every
 * `flb_set_interrupt_interval` VM instructions (default 1000, 0 disables).
 */
FLB_API void flb_interrupt(flb_state *state);
FLB_API int32_t flb_set_interrupt_interval(flb_state *state,
                                             int32_t instructions);

/* ---- References -------------------------------------------------------- */

FLB_API int32_t flb_release(flb_state *state, flb_ref ref);
/* A second, independent reference to the same value. */
FLB_API int32_t flb_retain(flb_state *state, flb_ref ref, flb_ref *out);
/* The FLB_* type of the referenced value. */
FLB_API int32_t flb_ref_type(flb_state *state, flb_ref ref, int32_t *out);
/* Primitive equality (no metamethods). */
FLB_API int32_t flb_equals(flb_state *state, const flb_value *left,
                             const flb_value *right, int32_t *out);
/* `tostring(value)`, honouring __tostring and __name. */
FLB_API int32_t flb_tostring(flb_state *state, const flb_value *value,
                               const flb_value **out);

/*
 * Copies `value` out of Lua. A table becomes a FLB_TABLE_VALUE tree read with
 * raw access (no metamethod runs); other values are returned as they are.
 * Fails with FLB_ERROR_ARGUMENT when the value holds a cycle, a function, a
 * userdata, a thread, a key that is not a string or an integer, more than 64
 * levels or more than 100000 values. The copy holds no references, so there
 * is nothing to release.
 */
FLB_API int32_t flb_copy(flb_state *state, const flb_value *value,
                           const flb_value **out);

/*
 * Reference tokens let a garbage-collected host release references from a
 * finalizer on any thread. A token takes over ownership of `ref`.
 * flb_token_release is thread safe and usable as a native finalizer; the
 * reference is released the next time the state is used, and a token may
 * outlive its state.
 */
FLB_API void *flb_token_new(flb_state *state, flb_ref ref);
FLB_API void flb_token_release(void *token);

/* ---- Chunks ------------------------------------------------------------ */

enum { FLB_MODE_TEXT = 1, FLB_MODE_BINARY = 2 };

/*
 * Compiles a chunk into a function without running it. `name` is the chunk
 * name used in messages (may be NULL). `mode` is a FLB_MODE_* mask (0 means
 * text). `environment` is a table reference used as the chunk's _ENV, or 0
 * for the globals.
 */
FLB_API int32_t flb_load(flb_state *state, const char *code, size_t length,
                           const char *name, int32_t mode, flb_ref environment,
                           flb_ref *out);
/* Compiles and runs a text chunk. `results`/`count` may be NULL. */
FLB_API int32_t flb_run(flb_state *state, const char *code, size_t length,
                          const char *name, const flb_value **results,
                          size_t *count);
/* Serializes a Lua function to a binary chunk for flb_load. */
FLB_API int32_t flb_dump(flb_state *state, flb_ref function, int32_t strip,
                           const flb_value **out);

/* ---- Calls ------------------------------------------------------------- */

enum {
  /* Results are copied as by flb_copy: plain data, no references. A result
   * that cannot be copied makes the call fail with FLB_ERROR_RUNTIME. */
  FLB_CALL_BY_VALUE = 1
};

/*
 * Calls a function (or callable value). All results are returned. `flags` is
 * a FLB_CALL_* mask.
 */
FLB_API int32_t flb_call(flb_state *state, flb_ref function,
                         const flb_value *arguments, size_t argument_count,
                         int32_t flags, const flb_value **results,
                         size_t *count);
/* `object.name(arguments...)`. */
FLB_API int32_t flb_call_field(flb_state *state, flb_ref object,
                               const char *name, const flb_value *arguments,
                               size_t argument_count, int32_t flags,
                               const flb_value **results, size_t *count);
/* `object:name(arguments...)`. */
FLB_API int32_t flb_call_method(flb_state *state, flb_ref object,
                                const char *name, const flb_value *arguments,
                                size_t argument_count, int32_t flags,
                                const flb_value **results, size_t *count);

/* ---- Tables and globals ------------------------------------------------ */

FLB_API int32_t flb_globals(flb_state *state, flb_ref *out);
FLB_API int32_t flb_get_global(flb_state *state, const char *name,
                                 const flb_value **out);
FLB_API int32_t flb_set_global(flb_state *state, const char *name,
                                 const flb_value *value);

/*
 * Creates a table. `pairs` holds `pair_count` key/value pairs laid out as
 * key0, value0, key1, value1, ... (may be NULL when `pair_count` is 0).
 */
FLB_API int32_t flb_table_new(flb_state *state, const flb_value *pairs,
                                size_t pair_count, flb_ref *out);
/* Creates a sequence: items[0] is stored at index 1. */
FLB_API int32_t flb_sequence_new(flb_state *state, const flb_value *items,
                                   size_t count, flb_ref *out);

/* object[key]. With `raw` != 0 metamethods are bypassed. */
FLB_API int32_t flb_get(flb_state *state, flb_ref object,
                          const flb_value *key, int32_t raw,
                          const flb_value **out);
FLB_API int32_t flb_set(flb_state *state, flb_ref object,
                          const flb_value *key, const flb_value *value,
                          int32_t raw);
/* #object. With `raw` != 0 the __len metamethod is bypassed. */
FLB_API int32_t flb_length(flb_state *state, flb_ref object, int32_t raw,
                             int64_t *out);
/*
 * A snapshot of every entry, laid out as key0, value0, key1, value1, ...
 * `pair_count` receives the number of pairs.
 */
FLB_API int32_t flb_pairs(flb_state *state, flb_ref table,
                            const flb_value **out, size_t *pair_count);
/* The sequence part: values at 1..#table (raw), in order. */
FLB_API int32_t flb_sequence(flb_state *state, flb_ref table,
                               const flb_value **out, size_t *count);
/*
 * Incremental traversal for large tables. Pass a nil key to start. `out`
 * receives two values (next key, value); `has_next` is 0 at the end.
 */
FLB_API int32_t flb_next(flb_state *state, flb_ref table,
                           const flb_value *key, const flb_value **out,
                           int32_t *has_next);

/* `out` receives 0 when the value has no metatable. */
FLB_API int32_t flb_get_metatable(flb_state *state, flb_ref object,
                                    flb_ref *out);
/* `metatable` 0 removes the metatable. */
FLB_API int32_t flb_set_metatable(flb_state *state, flb_ref object,
                                    flb_ref metatable);

/* ---- Host functions and objects ---------------------------------------- */

enum {
  /* Arguments are copied as by flb_copy, so the host receives plain data
   * and no references. A value that cannot be copied is a Lua error raised
   * in the caller, before the host is invoked. */
  FLB_FUNCTION_BY_VALUE = 1
};

/*
 * Creates a Lua function that invokes flb_options.call with `function_id`.
 * `flags` is a FLB_FUNCTION_* mask. flb_options.release is called with the
 * id once Lua has collected the function.
 */
FLB_API int32_t flb_function_new(flb_state *state, int64_t function_id,
                                   int32_t flags, flb_ref *out);
/* Inside a host call: the values the host function returns to Lua. */
FLB_API int32_t flb_return(flb_state *state, const flb_value *values,
                             size_t count);
/*
 * Inside a host call: makes the host function raise a Lua error whose value
 * is the string `message`, so Lua code handles it like any other error. If
 * the same string reaches the host again without being caught, the call fails
 * with FLB_ERROR_HOST and flb_error_host_id returns `host_error_id`.
 */
FLB_API int32_t flb_fail(flb_state *state, int64_t host_error_id,
                           const char *message, size_t length);

/*
 * Creates the metatable shared by host objects of one kind. `name` is used
 * as __name. The host fills in __index and other metamethods with flb_set.
 */
FLB_API int32_t flb_class_new(flb_state *state, const char *name,
                                flb_ref *out);
/*
 * Creates a userdata standing for the host object `object_id`, using a
 * metatable made by flb_class_new. flb_options.release is called with the
 * id once Lua has collected the userdata.
 */
FLB_API int32_t flb_object_new(flb_state *state, flb_ref class_metatable,
                                 int64_t object_id, flb_ref *out);

/* ---- Modules ----------------------------------------------------------- */

/* package.preload[name] = loader. Requires FLB_LIB_REQUIRE. */
FLB_API int32_t flb_preload(flb_state *state, const char *name,
                              flb_ref loader);
/*
 * package.loaded[name] = value: what `require(name)` returns from now on. A
 * nil value removes the module. Works without FLB_LIB_REQUIRE as well.
 */
FLB_API int32_t flb_set_module(flb_state *state, const char *name,
                                 const flb_value *value);
/* package.loaded[name], nil if the module is not loaded. */
FLB_API int32_t flb_get_module(flb_state *state, const char *name,
                                 const flb_value **out);
/*
 * Appends a searcher: a function called with the module name that returns a
 * loader function, or a string explaining why the module was not found.
 * Requires FLB_LIB_REQUIRE.
 */
FLB_API int32_t flb_add_searcher(flb_state *state, flb_ref searcher);

/* ---- Coroutines -------------------------------------------------------- */

enum {
  FLB_THREAD_SUSPENDED = 0,
  FLB_THREAD_RUNNING = 1,
  FLB_THREAD_NORMAL = 2,
  FLB_THREAD_DEAD = 3
};

/* Creates a coroutine whose body is `function`. */
FLB_API int32_t flb_thread_new(flb_state *state, flb_ref function,
                                 flb_ref *out);
/*
 * Starts or continues a coroutine. Returns FLB_YIELD with the yielded
 * values, FLB_OK with the returned values, or an error status.
 */
FLB_API int32_t flb_resume(flb_state *state, flb_ref thread,
                             const flb_value *arguments, size_t argument_count,
                             const flb_value **results, size_t *count);
FLB_API int32_t flb_thread_status(flb_state *state, flb_ref thread,
                                    int32_t *out);
/* Closes a suspended or dead coroutine, running its pending to-be-closed
 * variables. On Lua 5.3, which has neither, this does nothing and the
 * coroutine is collected once its references are released. */
FLB_API int32_t flb_thread_close(flb_state *state, flb_ref thread);

#ifdef __cplusplus
}
#endif

#endif
