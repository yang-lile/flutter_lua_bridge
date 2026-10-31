#include "bridge.h"
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <stdlib.h>
#include <string.h>

typedef char flb_integer_must_be_64_bits[(sizeof(lua_Integer) == 8) ? 1 : -1];
typedef char flb_number_must_be_double[(sizeof(lua_Number) == sizeof(double)) ? 1 : -1];
#define FLB_MAX_DEPTH 64
#define FLB_MAX_NODES 100000

typedef struct transient {
  flb_result *result;
  struct transient *next;
} transient;
typedef struct operation {
  flb_runtime *runtime;
  const char *module, *contract, *method, *source;
  size_t length;
  const flb_value *arguments;
  int is_void;
  flb_result *result;
  transient *temporaries;
  struct operation *previous;
} operation;
struct flb_runtime {
  lua_State *L;
  flb_callback callback;
  operation *active;
};
static const char modules_key = 0;

int flb_abi_version(void) { return FLB_ABI_VERSION; }
int flb_lua_version_num(void) { return LUA_VERSION_NUM; }

static void clear_value(flb_value *v) {
  if (v->children) {
    for (size_t i = 0; i < v->length * 2; i++) clear_value(&v->children[i]);
    free(v->children);
  }
  free(v->bytes);
  memset(v, 0, sizeof(*v));
}
static int init_value(flb_value *v, int kind, size_t length) {
  v->kind = kind;
  v->length = length;
  if (kind == 4) v->bytes = calloc(length + 1, 1);
  if (kind == 5 && length) v->children = calloc(length * 2, sizeof(flb_value));
  return (kind != 4 || v->bytes) && (kind != 5 || !length || v->children);
}
flb_value *flb_value_new(int kind, size_t length) {
  if (length > FLB_MAX_NODES && kind == 5) return NULL;
  flb_value *v = calloc(1, sizeof(*v));
  if (v && !init_value(v, kind, length)) { flb_value_free(v); return NULL; }
  return v;
}
void flb_value_free(flb_value *v) { if (v) { clear_value(v); free(v); } }
void flb_value_move(flb_value *target, flb_value *source) {
  clear_value(target); *target = *source; free(source);
}
flb_result *flb_result_new(void) { return calloc(1, sizeof(flb_result)); }
flb_value *flb_result_value(flb_result *result) { return &result->value; }
void flb_result_free(flb_result *r) {
  if (r) { clear_value(&r->value); free(r); }
}
static void set_error(flb_result *r, const char *message, size_t length) {
  r->failed = 1;
  clear_value(&r->value);
  if (init_value(&r->value, 4, length)) memcpy(r->value.bytes, message, length);
  else clear_value(&r->value);
}
static int push_value(lua_State *L, const flb_value *v, int depth) {
  if (depth > FLB_MAX_DEPTH || !lua_checkstack(L, 4))
    return luaL_error(L, "bridge value exceeds nesting/stack limit");
  switch (v->kind) {
    case 0: lua_pushnil(L); break;
    case 1: lua_pushboolean(L, (int)v->integer); break;
    case 2: lua_pushinteger(L, (lua_Integer)v->integer); break;
    case 3: lua_pushnumber(L, v->number); break;
    case 4: lua_pushlstring(L, v->bytes, v->length); break;
    case 5:
      lua_createtable(L, 0, (int)v->length);
      for (size_t i = 0; i < v->length; i++) {
        push_value(L, &v->children[i * 2], depth + 1);
        push_value(L, &v->children[i * 2 + 1], depth + 1);
        lua_rawset(L, -3);
      }
      break;
    default: return luaL_error(L, "invalid bridge value");
  }
  return 1;
}
/* Reads raw values: no __index, __pairs or tostring metamethod executes here.
 * Partially allocated trees remain owned by the operation on every error path.
 */
static const char *read_value(lua_State *L, int index, flb_value *v,
                             const void **ancestors, int depth, size_t *nodes) {
  if (depth >= FLB_MAX_DEPTH || ++*nodes > FLB_MAX_NODES)
    return "bridge value exceeds nesting/size limit";
  if (!lua_checkstack(L, 4)) return "bridge value exceeds stack limit";
  index = lua_absindex(L, index);
  switch (lua_type(L, index)) {
    case LUA_TNIL: return NULL;
    case LUA_TBOOLEAN: v->kind = 1; v->integer = lua_toboolean(L, index); return NULL;
    case LUA_TNUMBER:
      if (lua_isinteger(L, index)) { v->kind = 2; v->integer = lua_tointeger(L, index); }
      else { v->kind = 3; v->number = lua_tonumber(L, index); }
      return NULL;
    case LUA_TSTRING: {
      size_t n;
      const char *s = lua_tolstring(L, index, &n);
      if (!init_value(v, 4, n)) return "out of memory";
      memcpy(v->bytes, s, n);
      return NULL;
    }
    case LUA_TTABLE: {
      const void *identity = lua_topointer(L, index);
      for (int i = 0; i < depth; i++)
        if (ancestors[i] == identity) return "cyclic Lua tables are not DTOs";
      ancestors[depth] = identity;
      size_t n = 0;
      lua_pushnil(L);
      while (lua_next(L, index)) {
        lua_pop(L, 1);
        if (++n > FLB_MAX_NODES) return "Lua table exceeds size limit";
      }
      if (!init_value(v, 5, n)) return "out of memory";
      size_t i = 0;
      lua_pushnil(L);
      while (lua_next(L, index)) {
        if (lua_type(L, -2) != LUA_TSTRING && !lua_isinteger(L, -2))
          return "bridge table keys must be strings or integers";
        const char *error = read_value(L, -2, &v->children[i * 2], ancestors, depth + 1, nodes);
        if (!error) error = read_value(L, -1, &v->children[i * 2 + 1], ancestors, depth + 1, nodes);
        if (error) return error;
        i++;
        lua_pop(L, 1);
      }
      return NULL;
    }
    default: return "Lua functions, threads and userdata cannot be copied as DTOs";
  }
}
static int traceback(lua_State *L) {
  const char *message = lua_type(L, 1) == LUA_TSTRING ? lua_tostring(L, 1) : "non-string Lua error";
  luaL_traceback(L, L, message, 1);
  return 1;
}
static flb_result *run(operation *op, lua_CFunction body) {
  flb_runtime *runtime = op->runtime;
  lua_State *L = runtime->L;
  int base = lua_gettop(L);
  op->result = flb_result_new();
  if (!op->result) return NULL;
  if (!lua_checkstack(L, 4)) {
    set_error(op->result, "out of memory", 13);
    return op->result;
  }
  op->previous = runtime->active;
  runtime->active = op;
  lua_pushcfunction(L, traceback); /* zero-upvalue C functions do not allocate */
  lua_pushcfunction(L, body);
  lua_pushlightuserdata(L, op);
  int status = lua_pcall(L, 1, 0, base + 1);
  if (status != LUA_OK) {
    size_t length = 0;
    const char *s = lua_type(L, -1) == LUA_TSTRING ? lua_tolstring(L, -1, &length) : NULL;
    if (s) set_error(op->result, s, length);
    else set_error(op->result, "non-string Lua error", 20);
  }
  lua_settop(L, base);
  runtime->active = op->previous;
  while (op->temporaries) {
    transient *t = op->temporaries;
    op->temporaries = t->next;
    flb_result_free(t->result);
    free(t);
  }
  return op->result;
}
static int initialize(lua_State *L) {
  operation *op = lua_touserdata(L, 1);
  lua_newtable(L);
  lua_rawsetp(L, LUA_REGISTRYINDEX, &modules_key);
  if (op->is_void) luaL_openlibs(L);
  return 0;
}
flb_runtime *flb_create(flb_callback callback, int open_libraries) {
  flb_runtime *r = calloc(1, sizeof(*r));
  if (!r) return NULL;
  r->L = luaL_newstate();
  r->callback = callback;
  if (!r->L) { free(r); return NULL; }
  operation op = {0}; op.runtime = r; op.is_void = open_libraries;
  flb_result *result = run(&op, initialize);
  int failed = !result || result->failed;
  flb_result_free(result);
  if (failed) { flb_close(r); return NULL; }
  return r;
}
void flb_close(flb_runtime *runtime) {
  if (runtime) { lua_close(runtime->L); free(runtime); }
}
static void get_module(lua_State *L, const char *name) {
  lua_rawgetp(L, LUA_REGISTRYINDEX, &modules_key);
  lua_pushstring(L, name); lua_rawget(L, -2); lua_remove(L, -2);
  if (!lua_istable(L, -1)) luaL_error(L, "module '%s' is not loaded", name);
}
static void check_contract(lua_State *L, const char *contract) {
  lua_pushliteral(L, "__flb_contract"); lua_rawget(L, -2);
  if (lua_type(L, -1) != LUA_TSTRING || strcmp(lua_tostring(L, -1), contract) != 0)
    luaL_error(L, "bridge contract mismatch; regenerate both Dart and Lua bindings");
  lua_pop(L, 1);
}
static int load_body(lua_State *L) {
  operation *op = lua_touserdata(L, 1);
  if (luaL_loadbufferx(L, op->source, op->length, op->module, "t") != LUA_OK) return lua_error(L);
  lua_call(L, 0, 1);
  if (!lua_istable(L, -1)) return luaL_error(L, "module '%s' must return a table", op->module);
  lua_rawgetp(L, LUA_REGISTRYINDEX, &modules_key);
  lua_pushstring(L, op->module); lua_pushvalue(L, -3); lua_rawset(L, -3);
  /* Make loaded modules available to require(), including generated companions. */
  lua_getfield(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
  if (lua_istable(L, -1)) {
    lua_pushstring(L, op->module); lua_pushvalue(L, -4); lua_rawset(L, -3);
  }
  return 0;
}
flb_result *flb_load(flb_runtime *r, const char *module, const char *source, size_t length) {
  operation op = {0}; op.runtime = r; op.module = module; op.source = source; op.length = length;
  return run(&op, load_body);
}
static int call_body(lua_State *L) {
  operation *op = lua_touserdata(L, 1);
  lua_settop(L, 0);
  get_module(L, op->module); check_contract(L, op->contract);
  lua_pushstring(L, op->method); lua_rawget(L, -2); lua_remove(L, -2);
  if (!lua_isfunction(L, -1)) return luaL_error(L, "method '%s' is missing", op->method);
  for (size_t i = 0; i < op->arguments->length; i++) push_value(L, &op->arguments->children[i * 2 + 1], 0);
  lua_call(L, (int)op->arguments->length, LUA_MULTRET);
  if (lua_gettop(L) != (op->is_void ? 0 : 1))
    return luaL_error(L, "method '%s' must return exactly %d values", op->method, op->is_void ? 0 : 1);
  if (!op->is_void) {
    const void *ancestors[FLB_MAX_DEPTH] = {0}; size_t nodes = 0;
    const char *error = read_value(L, 1, &op->result->value, ancestors, 0, &nodes);
    if (error) return luaL_error(L, "%s", error);
  }
  return 0;
}
flb_result *flb_call(flb_runtime *r, const char *module, const char *contract,
                    const char *method, const flb_value *arguments, int is_void) {
  operation op = {0}; op.runtime = r; op.module = module; op.contract = contract;
  op.method = method; op.arguments = arguments; op.is_void = is_void;
  return run(&op, call_body);
}
static int bind_body(lua_State *L) {
  operation *op = lua_touserdata(L, 1);
  get_module(L, op->module); check_contract(L, op->contract);
  for (size_t i = 0; i < op->arguments->length; i++) {
    push_value(L, &op->arguments->children[i * 2 + 1], 0); lua_rawget(L, -2);
    if (!lua_isfunction(L, -1)) return luaL_error(L, "declared Lua method is missing");
    lua_pop(L, 1);
  }
  return 0;
}
flb_result *flb_bind(flb_runtime *r, const char *module, const char *contract, const flb_value *methods) {
  operation op = {0}; op.runtime = r; op.module = module; op.contract = contract; op.arguments = methods;
  return run(&op, bind_body);
}
static transient *temporary(lua_State *L, operation *op) {
  transient *t = calloc(1, sizeof(*t));
  if (!t) { luaL_error(L, "out of memory"); return NULL; }
  t->next = op->temporaries; op->temporaries = t;
  return t;
}
static void release_temporary(operation *op, transient *t) {
  /* Allocation while pushing results can run Lua finalizers. Unlink explicitly
   * so even a nested host call caught by Lua cannot orphan pending allocations. */
  transient **link = &op->temporaries;
  while (*link && *link != t) link = &(*link)->next;
  if (*link) *link = t->next;
  flb_result_free(t->result);
  free(t);
}
static int host_call(lua_State *L) {
  flb_runtime *r = lua_touserdata(L, lua_upvalueindex(1));
  if (!r->active) return luaL_error(L, "host callbacks are unavailable while closing");
  int64_t id = lua_tointeger(L, lua_upvalueindex(2));
  transient *input = temporary(L, r->active);
  input->result = flb_result_new();
  if (!input->result) return luaL_error(L, "out of memory");
  int count = lua_gettop(L);
  if (!init_value(&input->result->value, 5, (size_t)count)) return luaL_error(L, "out of memory");
  const void *ancestors[FLB_MAX_DEPTH] = {0}; size_t nodes = 0;
  for (int i = 0; i < count; i++) {
    flb_value *key = &input->result->value.children[i * 2]; key->kind = 2; key->integer = i + 1;
    const char *error = read_value(L, i + 1, key + 1, ancestors, 0, &nodes);
    if (error) {
      release_temporary(r->active, input);
      return luaL_error(L, "%s", error);
    }
  }
  transient *output = temporary(L, r->active);
  /* The callback never invokes Lua. A Dart exception becomes a returned error;
   * lua_error/allocations happen only after every Dart frame has returned. */
  output->result = r->callback(id, &input->result->value);
  if (!output->result) {
    release_temporary(r->active, output);
    release_temporary(r->active, input);
    return luaL_error(L, "Dart callback failed to allocate a response");
  }
  if (output->result->failed) {
    push_value(L, &output->result->value, 0);
    release_temporary(r->active, output);
    release_temporary(r->active, input);
    return lua_error(L);
  }
  int count_result = output->result->is_void ? 0 : 1;
  if (count_result) push_value(L, &output->result->value, 0);
  release_temporary(r->active, output);
  release_temporary(r->active, input);
  return count_result;
}
static int register_body(lua_State *L) {
  operation *op = lua_touserdata(L, 1);
  lua_newtable(L);
  for (size_t i = 0; i < op->arguments->length; i++) {
    const flb_value *key = &op->arguments->children[i * 2];
    const flb_value *id = key + 1;
    push_value(L, key, 0);
    lua_pushlightuserdata(L, op->runtime); lua_pushinteger(L, id->integer);
    lua_pushcclosure(L, host_call, 2); lua_rawset(L, -3);
  }
  lua_pushliteral(L, "__flb_contract"); lua_pushstring(L, op->contract); lua_rawset(L, -3);
  lua_getfield(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1); lua_newtable(L); lua_pushvalue(L, -1);
    lua_setfield(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
  }
  lua_pushstring(L, op->module);
  if (op->arguments->kind == 0) lua_pushnil(L); else lua_pushvalue(L, -3);
  lua_rawset(L, -3);
  return 0;
}
flb_result *flb_register(flb_runtime *r, const char *module, const char *contract, const flb_value *methods) {
  operation op = {0}; op.runtime = r; op.module = module; op.contract = contract; op.arguments = methods;
  return run(&op, register_body);
}
