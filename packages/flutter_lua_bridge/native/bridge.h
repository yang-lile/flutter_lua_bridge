#ifndef FLUTTER_LUA_BRIDGE_H
#define FLUTTER_LUA_BRIDGE_H
#include <stddef.h>
#include <stdint.h>
#if defined(_WIN32)
#define FLB_API __declspec(dllexport)
#else
#define FLB_API __attribute__((visibility("default")))
#endif

#define FLB_ABI_VERSION 1

/* Private transport, shared only by the runtime and generated bindings.
 * Tables contain alternating key/value nodes. Strings carry byte lengths.
 * All owned values/results must be released by this library, not Dart calloc.
 */
typedef struct flb_value {
  int kind; /* nil, boolean, integer, number, string, table */
  int64_t integer;
  double number;
  size_t length;
  char *bytes;
  struct flb_value *children;
} flb_value;
typedef struct flb_result {
  int failed;
  int is_void;
  flb_value value;
} flb_result;
typedef flb_result *(*flb_callback)(int64_t id, const flb_value *arguments);
typedef struct flb_runtime flb_runtime;

FLB_API int flb_abi_version(void);
FLB_API int flb_lua_version_num(void);
FLB_API flb_value *flb_value_new(int kind, size_t length);
FLB_API void flb_value_free(flb_value *value);
FLB_API void flb_value_move(flb_value *target, flb_value *source);
FLB_API flb_result *flb_result_new(void);
FLB_API void flb_result_free(flb_result *result);
FLB_API flb_value *flb_result_value(flb_result *result);
FLB_API flb_runtime *flb_create(flb_callback callback, int open_libraries);
FLB_API void flb_close(flb_runtime *runtime);
FLB_API flb_result *flb_load(flb_runtime *runtime, const char *module,
                          const char *source, size_t length);
FLB_API flb_result *flb_call(flb_runtime *runtime, const char *module,
                          const char *contract, const char *method,
                          const flb_value *arguments, int is_void);
FLB_API flb_result *flb_bind(flb_runtime *runtime, const char *module,
                          const char *contract, const flb_value *methods);
FLB_API flb_result *flb_register(flb_runtime *runtime, const char *module,
                              const char *contract, const flb_value *methods);
#endif
