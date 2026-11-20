/*
 * flb implementation. This is the only file that knows which Lua release it
 * is compiled against; see flb.h for the interface and its rules.
 */
#include "flb.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"

#if LUA_VERSION_NUM < 503 || LUA_VERSION_NUM > 505
#error "flb supports Lua 5.3, 5.4 and 5.5"
#endif

typedef char flb_integer_is_64_bits[(sizeof(lua_Integer) == 8) ? 1 : -1];
typedef char flb_number_is_double[(sizeof(lua_Number) == sizeof(double)) ? 1 : -1];
typedef char flb_extra_space_fits[(LUA_EXTRASPACE >= sizeof(void *)) ? 1 : -1];

/* ---- Cross-thread lock ---------------------------------------------------
 * Guards state reference counts and the queues of references released from
 * finalizer threads. Contention is negligible, so one lock serves all states.
 */
#if defined(_WIN32)
#include <windows.h>
static SRWLOCK flb_lock = SRWLOCK_INIT;
static void lock(void) { AcquireSRWLockExclusive(&flb_lock); }
static void unlock(void) { ReleaseSRWLockExclusive(&flb_lock); }
#else
#include <pthread.h>
static pthread_mutex_t flb_lock = PTHREAD_MUTEX_INITIALIZER;
static void lock(void) { pthread_mutex_lock(&flb_lock); }
static void unlock(void) { pthread_mutex_unlock(&flb_lock); }
#endif

/* ---- Data ---------------------------------------------------------------- */

#define FLB_MAX_DEPTH 190 /* below Lua's own limit on nested C calls */
#define FLB_DEFAULT_INTERVAL 1000
#define FLB_COPY_DEPTH 64     /* nesting of tables passed by value */
#define FLB_COPY_NODES 100000 /* values in one by-value copy */

typedef struct values {
  flb_value *items;
  size_t count;
  size_t capacity;
} values;

/* Bump storage for by-value copies handed to the host. */
typedef struct block {
  struct block *next;
  size_t used;
  size_t capacity;
} block;

typedef struct pool {
  block *first;
} pool;

/*
 * One nesting level of host activity. Frame 0 is the host calling into Lua;
 * each host function invocation runs in the next frame, so storage handed to
 * the host at one level is not disturbed by calls made at a deeper level.
 */
typedef struct frame {
  lua_State *L;
  int base;          /* stack slots below this belong to the frame's owner */
  int argument_top;  /* host call frames: top of the argument anchors */
  values results;    /* storage returned by the last call at this level */
  values arguments;  /* host call frames: the arguments given to the host */
  pool result_pool;   /* by-value copies in `results` */
  pool argument_pool; /* by-value copies in `arguments` */
  int returned;
  int failed;
  int yielded;       /* host call frames: flb_yield was called */
  int64_t failure_id;
  char *failure_message;
  size_t failure_length;
} frame;

struct flb_state {
  lua_State *L; /* NULL once closed */
  flb_options options;
  size_t used;
  size_t limit;
  volatile int interrupted;
  int interval; /* VM instructions between interruption checks */
  int host_gone; /* host callbacks must no longer be invoked */
  int references; /* owner + tokens; guarded by the lock */
  int *pending;   /* references released from other threads; guarded */
  size_t pending_count;
  size_t pending_capacity;
  frame *frames[FLB_MAX_DEPTH];
  int depth;
  int override_status; /* set by an operation just before raising */
  int status;
  char *message;
  size_t message_length;
  char *traceback;
  size_t traceback_length;
  int64_t host_error_id;
  /* The last failure raised by a host function, to recognise it when the
   * same error string comes back to the host. */
  char *host_failure;
  size_t host_failure_length;
  int64_t host_failure_id;
};

typedef struct token {
  flb_state *state;
  int ref;
} token;

typedef struct holder {
  int64_t id;
  int32_t flags;
} holder;

/* Parameters and outputs of one protected operation. */
typedef struct op {
  flb_state *S;
  frame *f;
  values *target;
  flb_ref ref;
  flb_ref ref2;
  const flb_value *a;
  const flb_value *b;
  size_t n;
  const char *s;
  size_t length;
  const char *name;
  int flag;
  int intermediate; /* a step of a larger call: do not finish on success */
  int64_t id;
  lua_State *thread;
  flb_ref out_ref;
  int64_t out_integer;
  int out_flag;
} op;

/* Registry keys (their addresses are the keys). */
static const char KEY_REFS = 0;
static const char KEY_TRACEBACK = 0;
static const char KEY_FUNCTION_HOLDER = 0;
static const char KEY_HOST_OBJECT = 0;
/* Marks the resume arguments of flb_resume_failure. Lua code cannot create a
 * light userdata, so it cannot forge this marker. */
static const char KEY_RESUME_FAILURE = 0;

static flb_state *state_of(lua_State *L) {
  return *(flb_state **)lua_getextraspace(L);
}

/* ---- Library ------------------------------------------------------------- */

int32_t flb_abi_version(void) { return FLB_ABI_VERSION; }
int32_t flb_lua_version(void) { return (int32_t)LUA_VERSION_NUM; }
const char *flb_lua_release(void) { return LUA_RELEASE; }

const char *flb_status_name(int32_t status) {
  switch (status) {
    case FLB_OK: return "ok";
    case FLB_YIELD: return "yield";
    case FLB_ERROR_RUNTIME: return "runtime error";
    case FLB_ERROR_SYNTAX: return "syntax error";
    case FLB_ERROR_MEMORY: return "memory error";
    case FLB_ERROR_HANDLER: return "error in message handler";
    case FLB_ERROR_ARGUMENT: return "invalid argument";
    case FLB_ERROR_CLOSED: return "state is closed";
    case FLB_ERROR_INTERRUPTED: return "interrupted";
    case FLB_ERROR_HOST: return "host error";
    default: return "unknown status";
  }
}

const char *flb_type_name(int32_t type) {
  switch (type) {
    case FLB_NIL: return "nil";
    case FLB_BOOLEAN: return "boolean";
    case FLB_INTEGER: return "integer";
    case FLB_NUMBER: return "number";
    case FLB_STRING: return "string";
    case FLB_TABLE: return "table";
    case FLB_FUNCTION: return "function";
    case FLB_USERDATA: return "userdata";
    case FLB_THREAD: return "thread";
    case FLB_LIGHTUSERDATA: return "lightuserdata";
    default: return "unknown";
  }
}

/* ---- Errors -------------------------------------------------------------- */

static void clear_error(flb_state *S) {
  free(S->message);
  free(S->traceback);
  S->message = NULL;
  S->traceback = NULL;
  S->message_length = 0;
  S->traceback_length = 0;
  S->host_error_id = 0;
  S->status = FLB_OK;
  S->override_status = 0;
}

static char *copy_bytes(const char *bytes, size_t length) {
  char *copy = malloc(length + 1);
  if (copy) {
    if (length) memcpy(copy, bytes, length);
    copy[length] = '\0';
  }
  return copy;
}

static void set_message(flb_state *S, const char *bytes, size_t length) {
  free(S->message);
  S->message = copy_bytes(bytes, length);
  S->message_length = S->message ? length : 0;
}

/* Applies interruption, which only ever replaces a failure at the top level. */
static int finish(flb_state *S, int status) {
  if (S->depth == 0 && S->interrupted) {
    S->interrupted = 0;
    if (status >= FLB_ERROR_RUNTIME && status < FLB_ERROR_ARGUMENT) {
      status = FLB_ERROR_INTERRUPTED;
      set_message(S, "interrupted", 11);
    }
  }
  S->status = status;
  return status;
}

static int fail(flb_state *S, int status, const char *message) {
  set_message(S, message, strlen(message));
  S->status = status;
  return status;
}

const char *flb_error_message(const flb_state *state, size_t *length) {
  if (length) *length = state ? state->message_length : 0;
  return (state && state->message) ? state->message : "";
}

const char *flb_error_traceback(const flb_state *state, size_t *length) {
  if (length) *length = state ? state->traceback_length : 0;
  return (state && state->traceback) ? state->traceback : "";
}

int64_t flb_error_host_id(const flb_state *state) {
  return state ? state->host_error_id : 0;
}

/* Raises an error reported to the host as FLB_ERROR_ARGUMENT. */
static int argument_error(lua_State *L, const char *message) {
  state_of(L)->override_status = FLB_ERROR_ARGUMENT;
  lua_pushstring(L, message);
  return lua_error(L);
}

/* ---- Values -------------------------------------------------------------- */

static int reference_table(lua_State *L) {
  lua_rawgetp(L, LUA_REGISTRYINDEX, &KEY_REFS);
  return lua_gettop(L);
}

/* References the value at `index`. Runs protected (may allocate). */
static flb_ref make_ref(lua_State *L, int index) {
  int absolute = lua_absindex(L, index);
  int table = reference_table(L);
  int ref;
  lua_pushvalue(L, absolute);
  ref = luaL_ref(L, table);
  lua_pop(L, 1);
  return (flb_ref)ref;
}

/* Pushes the referenced value without raising; returns 0 for a bad reference. */
static int push_ref_plain(lua_State *L, flb_ref ref) {
  if (ref <= 0 || ref > INT_MAX) return 0;
  lua_rawgetp(L, LUA_REGISTRYINDEX, &KEY_REFS);
  lua_rawgeti(L, -1, (lua_Integer)ref);
  lua_remove(L, -2);
  /* Only these types are ever referenced. A released slot holds nil or the
   * integer link of luaL_ref's free list, which must not be mistaken for a
   * value. */
  switch (lua_type(L, -1)) {
    case LUA_TTABLE:
    case LUA_TFUNCTION:
    case LUA_TUSERDATA:
    case LUA_TTHREAD: return 1;
    default:
      lua_pop(L, 1);
      return 0;
  }
}

static void push_ref(lua_State *L, flb_ref ref) {
  if (!push_ref_plain(L, ref)) argument_error(L, "invalid reference");
}

static void push_ref_of_type(lua_State *L, flb_ref ref, int lua_type_id,
                             const char *message) {
  push_ref(L, ref);
  if (lua_type(L, -1) != lua_type_id) argument_error(L, message);
}

static void push_value_at(lua_State *L, const flb_value *value, int depth) {
  if (!value) {
    lua_pushnil(L);
    return;
  }
  switch (value->type) {
    case FLB_TABLE_VALUE: {
      size_t i;
      if (depth >= FLB_COPY_DEPTH) argument_error(L, "value is nested too deeply");
      if (value->length && !value->items) argument_error(L, "table without items");
      luaL_checkstack(L, 4, "value is nested too deeply");
      lua_createtable(L, 0, value->length > 1024 ? 1024 : (int)value->length);
      for (i = 0; i < value->length; i++) {
        push_value_at(L, &value->items[2 * i], depth + 1);
        if (lua_isnil(L, -1)) argument_error(L, "table key is nil");
        push_value_at(L, &value->items[2 * i + 1], depth + 1);
        lua_rawset(L, -3);
      }
      break;
    }
    case FLB_NIL: lua_pushnil(L); break;
    case FLB_BOOLEAN: lua_pushboolean(L, value->i != 0); break;
    case FLB_INTEGER: lua_pushinteger(L, (lua_Integer)value->i); break;
    case FLB_NUMBER: lua_pushnumber(L, (lua_Number)value->n); break;
    case FLB_STRING:
      if (value->length && !value->bytes) argument_error(L, "string without bytes");
      lua_pushlstring(L, value->bytes ? value->bytes : "", value->length);
      break;
    case FLB_TABLE:
    case FLB_FUNCTION:
    case FLB_USERDATA:
    case FLB_THREAD: push_ref(L, (flb_ref)value->i); break;
    case FLB_LIGHTUSERDATA:
      lua_pushlightuserdata(L, (void *)(intptr_t)value->i);
      break;
    default: argument_error(L, "invalid value type");
  }
}

static void push_value(lua_State *L, const flb_value *value) {
  push_value_at(L, value, 0);
}

static void push_values(lua_State *L, const flb_value *items, size_t count) {
  size_t i;
  if (count > (size_t)INT_MAX / 2) argument_error(L, "too many values");
  if (count && !items) argument_error(L, "values are missing");
  luaL_checkstack(L, (int)count + LUA_MINSTACK, "too many values");
  for (i = 0; i < count; i++) push_value(L, &items[i]);
}

static int is_host_object(lua_State *L, int index) {
  int result = 0;
  if (lua_type(L, index) == LUA_TUSERDATA && lua_getmetatable(L, index)) {
    lua_rawgetp(L, -1, &KEY_HOST_OBJECT);
    result = lua_toboolean(L, -1);
    lua_pop(L, 2);
  }
  return result;
}

static void reserve(lua_State *L, values *target, size_t extra) {
  size_t needed = target->count + extra;
  size_t capacity = target->capacity ? target->capacity : 8;
  flb_value *items;
  if (needed <= target->capacity) return;
  while (capacity < needed) capacity *= 2;
  items = realloc(target->items, capacity * sizeof(flb_value));
  if (!items) {
    state_of(L)->override_status = FLB_ERROR_MEMORY;
    luaL_error(L, "not enough memory");
  }
  target->items = items;
  target->capacity = capacity;
}

/*
 * Describes the value at `index`. String bytes point into the Lua string, so
 * the value must stay on the stack for as long as the host may read it.
 */
static void read_value(lua_State *L, int index, flb_value *out) {
  memset(out, 0, sizeof(*out));
  switch (lua_type(L, index)) {
    case LUA_TNIL: out->type = FLB_NIL; break;
    case LUA_TBOOLEAN:
      out->type = FLB_BOOLEAN;
      out->i = lua_toboolean(L, index);
      break;
    case LUA_TNUMBER:
      if (lua_isinteger(L, index)) {
        out->type = FLB_INTEGER;
        out->i = (int64_t)lua_tointeger(L, index);
      } else {
        out->type = FLB_NUMBER;
        out->n = (double)lua_tonumber(L, index);
      }
      break;
    case LUA_TSTRING:
      out->type = FLB_STRING;
      out->bytes = lua_tolstring(L, index, &out->length);
      break;
    case LUA_TLIGHTUSERDATA:
      out->type = FLB_LIGHTUSERDATA;
      out->i = (int64_t)(intptr_t)lua_touserdata(L, index);
      break;
    case LUA_TTABLE: out->type = FLB_TABLE; break;
    case LUA_TFUNCTION: out->type = FLB_FUNCTION; break;
    case LUA_TTHREAD: out->type = FLB_THREAD; break;
    case LUA_TUSERDATA:
      out->type = FLB_USERDATA;
      if (is_host_object(L, index)) out->id = ((holder *)lua_touserdata(L, index))->id;
      break;
    default: out->type = FLB_NIL; break;
  }
  if (out->type >= FLB_TABLE && out->type <= FLB_THREAD) {
    out->i = make_ref(L, index);
  }
}

/*
 * Appends the top `count` stack values to `target` and leaves them on the
 * stack as anchors. A protected body ends with `return emit(...)`.
 */
static int emit(lua_State *L, values *target, int count) {
  int first = lua_gettop(L) - count + 1;
  int i;
  reserve(L, target, (size_t)count);
  luaL_checkstack(L, 4, "stack overflow");
  for (i = 0; i < count; i++) {
    read_value(L, first + i, &target->items[target->count]);
    target->count++;
  }
  return count;
}

static void release_values(lua_State *L, values *target) {
  size_t i;
  if (target->count == 0) return;
  if (lua_checkstack(L, 2)) {
    lua_rawgetp(L, LUA_REGISTRYINDEX, &KEY_REFS);
    for (i = 0; i < target->count; i++) {
      const flb_value *value = &target->items[i];
      if (value->type >= FLB_TABLE && value->type <= FLB_THREAD && value->i > 0) {
        luaL_unref(L, -1, (int)value->i);
      }
    }
    lua_pop(L, 1);
  }
  target->count = 0;
}

/* ---- By-value copies ----------------------------------------------------- */

static void pool_reset(pool *p) {
  block *b = p->first;
  if (!b) return;
  while (b->next) {
    block *next = b->next->next;
    free(b->next);
    b->next = next;
  }
  b->used = 0;
}

static void pool_free(pool *p) {
  while (p->first) {
    block *next = p->first->next;
    free(p->first);
    p->first = next;
  }
}

/* Never returns NULL: raises a memory error instead. */
static void *pool_take(lua_State *L, pool *p, size_t size) {
  block *b = p->first;
  void *result;
  size = (size + 15) & ~(size_t)15;
  if (!b || b->capacity - b->used < size) {
    size_t capacity = size > 4096 ? size : 4096;
    size_t header = (sizeof(block) + 15) & ~(size_t)15;
    block *fresh = malloc(header + capacity);
    if (!fresh) {
      state_of(L)->override_status = FLB_ERROR_MEMORY;
      luaL_error(L, "not enough memory");
    }
    fresh->used = 0;
    fresh->capacity = capacity;
    if (b && b->used == 0) {
      /* Keep the reusable first block in front. */
      fresh->next = b->next;
      b->next = fresh;
    } else {
      fresh->next = b;
      p->first = fresh;
    }
    b = fresh;
  }
  result = (char *)b + ((sizeof(block) + 15) & ~(size_t)15) + b->used;
  b->used += size;
  return result;
}

typedef struct copier {
  pool *storage;
  const void *ancestors[FLB_COPY_DEPTH];
  size_t nodes;
} copier;

/*
 * Copies the value at `index` into `out`, following tables with raw access
 * (no metamethod runs). Nothing in the copy refers to Lua memory.
 */
static void copy_value(lua_State *L, int index, flb_value *out, copier *c,
                       int depth) {
  memset(out, 0, sizeof(*out));
  if (++c->nodes > FLB_COPY_NODES) luaL_error(L, "value is too large to copy");
  index = lua_absindex(L, index);
  switch (lua_type(L, index)) {
    case LUA_TNIL: out->type = FLB_NIL; break;
    case LUA_TBOOLEAN:
      out->type = FLB_BOOLEAN;
      out->i = lua_toboolean(L, index);
      break;
    case LUA_TNUMBER:
      if (lua_isinteger(L, index)) {
        out->type = FLB_INTEGER;
        out->i = (int64_t)lua_tointeger(L, index);
      } else {
        out->type = FLB_NUMBER;
        out->n = (double)lua_tonumber(L, index);
      }
      break;
    case LUA_TSTRING: {
      size_t length;
      const char *bytes = lua_tolstring(L, index, &length);
      char *copy = pool_take(L, c->storage, length + 1);
      memcpy(copy, bytes, length);
      copy[length] = '\0';
      out->type = FLB_STRING;
      out->bytes = copy;
      out->length = length;
      break;
    }
    case LUA_TTABLE: {
      const void *identity = lua_topointer(L, index);
      flb_value *items = NULL;
      size_t count = 0, i = 0;
      int level;
      if (depth >= FLB_COPY_DEPTH) luaL_error(L, "table is nested too deeply to copy");
      for (level = 0; level < depth; level++) {
        if (c->ancestors[level] == identity) {
          luaL_error(L, "cyclic tables cannot be copied by value");
        }
      }
      c->ancestors[depth] = identity;
      luaL_checkstack(L, 4, "table is nested too deeply to copy");
      lua_pushnil(L);
      while (lua_next(L, index)) {
        lua_pop(L, 1);
        if (++count > FLB_COPY_NODES) luaL_error(L, "value is too large to copy");
      }
      if (count) items = pool_take(L, c->storage, count * 2 * sizeof(flb_value));
      lua_pushnil(L);
      while (lua_next(L, index)) {
        if (lua_type(L, -2) != LUA_TSTRING && !lua_isinteger(L, -2)) {
          luaL_error(L, "keys of a table copied by value must be strings or integers");
        }
        copy_value(L, -2, &items[2 * i], c, depth + 1);
        copy_value(L, -1, &items[2 * i + 1], c, depth + 1);
        i++;
        lua_pop(L, 1);
      }
      out->type = FLB_TABLE_VALUE;
      out->items = items;
      out->length = count;
      break;
    }
    default:
      luaL_error(L, "a %s cannot be copied by value", luaL_typename(L, index));
  }
}

/* ---- Protected execution ------------------------------------------------- */

static int message_handler(lua_State *L) {
  const char *message = lua_type(L, 1) == LUA_TSTRING ? lua_tostring(L, 1) : NULL;
  luaL_traceback(L, L, message, 1);
  lua_rawsetp(L, LUA_REGISTRYINDEX, &KEY_TRACEBACK);
  lua_settop(L, 1);
  return 1;
}

static int describe_error(lua_State *L) {
  luaL_tolstring(L, 1, NULL);
  return 1;
}

static int translate(int code) {
  switch (code) {
    case LUA_OK: return FLB_OK;
    case LUA_YIELD: return FLB_YIELD;
    case LUA_ERRSYNTAX: return FLB_ERROR_SYNTAX;
    case LUA_ERRMEM: return FLB_ERROR_MEMORY;
    case LUA_ERRERR: return FLB_ERROR_HANDLER;
    default: return FLB_ERROR_RUNTIME; /* LUA_ERRRUN, and LUA_ERRGCMM in 5.3 */
  }
}

/*
 * Records the failure whose error object is on top of the stack of `L`, then
 * restores the frame. `partial` holds values emitted before the failure.
 */
static int capture(flb_state *S, frame *f, int code, values *partial) {
  lua_State *L = f->L;
  int status = translate(code);
  int error = lua_gettop(L);
  if (S->override_status) {
    status = S->override_status;
    S->override_status = 0;
  }
  free(S->message);
  free(S->traceback);
  S->message = S->traceback = NULL;
  S->message_length = S->traceback_length = 0;
  S->host_error_id = 0;

  if (lua_checkstack(L, 6)) {
    {
      if (lua_type(L, error) == LUA_TSTRING) {
        size_t length;
        const char *bytes = lua_tolstring(L, error, &length);
        set_message(S, bytes, length);
        if (S->host_failure && status == FLB_ERROR_RUNTIME &&
            length == S->host_failure_length &&
            memcmp(bytes, S->host_failure, length) == 0) {
          S->host_error_id = S->host_failure_id;
          status = FLB_ERROR_HOST;
        }
      } else {
        lua_pushcfunction(L, describe_error);
        lua_pushvalue(L, error);
        if (lua_pcall(L, 1, 1, 0) == LUA_OK && lua_type(L, -1) == LUA_TSTRING) {
          size_t length;
          const char *bytes = lua_tolstring(L, -1, &length);
          set_message(S, bytes, length);
        } else {
          set_message(S, "(error object is not a string)", 30);
        }
        lua_pop(L, 1);
      }
    }
    lua_rawgetp(L, LUA_REGISTRYINDEX, &KEY_TRACEBACK);
    if (lua_type(L, -1) == LUA_TSTRING) {
      size_t length;
      const char *bytes = lua_tolstring(L, -1, &length);
      S->traceback = copy_bytes(bytes, length);
      S->traceback_length = S->traceback ? length : 0;
      lua_pushnil(L);
      lua_rawsetp(L, LUA_REGISTRYINDEX, &KEY_TRACEBACK);
    }
    lua_pop(L, 1);
  }
  if (partial) release_values(L, partial);
  lua_settop(L, f->base);
  return finish(S, status);
}

/*
 * Runs `body` protected with `o` as its only argument, after moving `moved`
 * values from `from` (if any) onto the argument list. On success the values
 * returned by the body stay on the frame's stack.
 */
static int run_with(op *o, lua_CFunction body, lua_State *from, int moved) {
  flb_state *S = o->S;
  lua_State *L = o->f->L;
  int handler, code;
  if (!lua_checkstack(L, moved + 8)) {
    if (from) lua_pop(from, moved);
    return fail(S, FLB_ERROR_MEMORY, "stack overflow");
  }
  lua_pushcfunction(L, message_handler);
  handler = lua_gettop(L);
  lua_pushcfunction(L, body);
  lua_pushlightuserdata(L, o);
  if (from && moved) lua_xmove(from, L, moved);
  code = lua_pcall(L, moved + 1, LUA_MULTRET, handler);
  if (code != LUA_OK) return capture(S, o->f, code, o->target);
  lua_remove(L, handler);
  return o->intermediate ? FLB_OK : finish(S, FLB_OK);
}

static int run(op *o, lua_CFunction body) { return run_with(o, body, NULL, 0); }

static op *begin(lua_State *L) {
  op *o = lua_touserdata(L, 1);
  lua_remove(L, 1);
  return o;
}

/* ---- Frames and entry ---------------------------------------------------- */

static void drain_pending(flb_state *S) {
  int *pending;
  size_t count, i;
  lock();
  pending = S->pending;
  count = S->pending_count;
  S->pending = NULL;
  S->pending_count = S->pending_capacity = 0;
  unlock();
  if (!pending) return;
  if (lua_checkstack(S->L, 2)) {
    lua_rawgetp(S->L, LUA_REGISTRYINDEX, &KEY_REFS);
    for (i = 0; i < count; i++) luaL_unref(S->L, -1, pending[i]);
    lua_pop(S->L, 1);
  }
  free(pending);
}

/* Prepares the current frame for a new call; NULL if the state is closed. */
static frame *enter(flb_state *S) {
  frame *f;
  if (!S || !S->L) return NULL;
  f = S->frames[S->depth];
  if (S->depth == 0) {
    drain_pending(S);
    free(S->host_failure);
    S->host_failure = NULL;
  }
  lua_settop(f->L, f->base);
  f->results.count = 0;
  pool_reset(&f->result_pool);
  clear_error(S);
  return f;
}

#define ENTER(state)                                   \
  op o;                                                \
  frame *f = enter(state);                             \
  if (!f) return FLB_ERROR_CLOSED;                    \
  memset(&o, 0, sizeof(o));                            \
  o.S = (state);                                       \
  o.f = f;                                             \
  o.target = &f->results

static void give(const frame *f, int status, const flb_value **out,
                 size_t *count) {
  int ok = status == FLB_OK || status == FLB_YIELD;
  if (out) *out = (ok && f->results.count) ? f->results.items : NULL;
  if (count) *count = ok ? f->results.count : 0;
}

/* ---- State --------------------------------------------------------------- */

static void *allocate(void *ud, void *pointer, size_t old_size, size_t new_size) {
  flb_state *S = ud;
  size_t old = pointer ? old_size : 0;
  void *result;
  if (new_size == 0) {
    free(pointer);
    S->used -= old;
    return NULL;
  }
  if (S->limit && new_size > old && S->used - old + new_size > S->limit) {
    return NULL;
  }
  result = realloc(pointer, new_size);
  if (result) S->used = S->used - old + new_size;
  return result;
}

static int panic(lua_State *L) {
  const char *message = lua_type(L, -1) == LUA_TSTRING ? lua_tostring(L, -1) : "?";
  fprintf(stderr, "flb: unprotected Lua error: %s\n", message);
  return 0;
}

/*
 * Once interrupted, the hook fires on every instruction of this thread, so a
 * `pcall` that catches the error is interrupted again on its next step and
 * the error keeps unwinding until it reaches the host.
 */
static void interrupt_hook(lua_State *L, lua_Debug *ar) {
  flb_state *S = state_of(L);
  (void)ar;
  if (S->interrupted) {
    if (lua_gethookcount(L) != 1) lua_sethook(L, interrupt_hook, LUA_MASKCOUNT, 1);
    luaL_error(L, "interrupted");
  }
  if (S->interval > 0 && lua_gethookcount(L) != S->interval) {
    lua_sethook(L, interrupt_hook, LUA_MASKCOUNT, S->interval);
  }
}

static int function_holder_gc(lua_State *L) {
  flb_state *S = state_of(L);
  holder *h = lua_touserdata(L, 1);
  if (h && S->options.release && !S->host_gone) S->options.release(S, h->id, 0);
  return 0;
}

static int host_object_gc(lua_State *L) {
  flb_state *S = state_of(L);
  holder *h = lua_touserdata(L, 1);
  if (h && S->options.release && !S->host_gone) S->options.release(S, h->id, 1);
  return 0;
}

/* `load` restricted to text chunks; upvalue 1 is the original function. */
static int text_only_load(lua_State *L) {
  int count = lua_gettop(L);
  if (count < 3) {
    lua_settop(L, 3);
    count = 3;
  }
  lua_pushliteral(L, "t");
  lua_replace(L, 3);
  lua_pushvalue(L, lua_upvalueindex(1));
  lua_insert(L, 1);
  lua_call(L, count, LUA_MULTRET);
  return lua_gettop(L);
}

static void open_library(lua_State *L, const char *name, lua_CFunction open) {
  luaL_requiref(L, name, open, 1);
  lua_pop(L, 1);
}

static int initialize(lua_State *L) {
  op *o = begin(L);
  uint32_t libraries = o->S->options.libraries;

  lua_newtable(L);
  lua_rawsetp(L, LUA_REGISTRYINDEX, &KEY_REFS);

  lua_newtable(L);
  lua_pushcfunction(L, function_holder_gc);
  lua_setfield(L, -2, "__gc");
  lua_rawsetp(L, LUA_REGISTRYINDEX, &KEY_FUNCTION_HOLDER);

  if (libraries & FLB_LIB_PACKAGE) libraries |= FLB_LIB_REQUIRE;
  if (libraries & FLB_LIB_BASE) open_library(L, "_G", luaopen_base);
  if (libraries & FLB_LIB_REQUIRE) {
    luaL_requiref(L, LUA_LOADLIBNAME, luaopen_package, 1);
    if (!(libraries & FLB_LIB_PACKAGE)) {
      /* Keep only the preload searcher: no files, no native libraries. */
      lua_pushnil(L);
      lua_setfield(L, -2, "loadlib");
      lua_pushliteral(L, "");
      lua_setfield(L, -2, "path");
      lua_pushliteral(L, "");
      lua_setfield(L, -2, "cpath");
      lua_getfield(L, -1, "searchers");
      lua_createtable(L, 1, 0);
      lua_rawgeti(L, -2, 1);
      lua_rawseti(L, -2, 1);
      lua_setfield(L, -3, "searchers");
      lua_pop(L, 1);
    }
    lua_pop(L, 1);
  }
  if (libraries & FLB_LIB_COROUTINE) open_library(L, LUA_COLIBNAME, luaopen_coroutine);
  if (libraries & FLB_LIB_TABLE) open_library(L, LUA_TABLIBNAME, luaopen_table);
  if (libraries & FLB_LIB_STRING) open_library(L, LUA_STRLIBNAME, luaopen_string);
  if (libraries & FLB_LIB_MATH) open_library(L, LUA_MATHLIBNAME, luaopen_math);
  if (libraries & FLB_LIB_UTF8) open_library(L, LUA_UTF8LIBNAME, luaopen_utf8);
  if (libraries & FLB_LIB_IO) open_library(L, LUA_IOLIBNAME, luaopen_io);
  if (libraries & FLB_LIB_OS) open_library(L, LUA_OSLIBNAME, luaopen_os);
  if (libraries & FLB_LIB_DEBUG) open_library(L, LUA_DBLIBNAME, luaopen_debug);

  if ((libraries & FLB_LIB_BASE) && !(libraries & FLB_LIB_IO)) {
    lua_pushnil(L);
    lua_setglobal(L, "dofile");
    lua_pushnil(L);
    lua_setglobal(L, "loadfile");
    lua_getglobal(L, "load");
    lua_pushcclosure(L, text_only_load, 1);
    lua_setglobal(L, "load");
  }
  return 0;
}

static void free_frame(frame *f) {
  if (!f) return;
  free(f->results.items);
  free(f->arguments.items);
  free(f->failure_message);
  pool_free(&f->result_pool);
  pool_free(&f->argument_pool);
  free(f);
}

static void free_state(flb_state *S) {
  int i;
  for (i = 0; i < FLB_MAX_DEPTH; i++) free_frame(S->frames[i]);
  free(S->pending);
  free(S->message);
  free(S->traceback);
  free(S->host_failure);
  free(S);
}

flb_state *flb_open(const flb_options *options) {
  flb_state *S = calloc(1, sizeof(flb_state));
  lua_State *L;
  op o;
  if (!S) return NULL;
  S->frames[0] = calloc(1, sizeof(frame));
  if (!S->frames[0]) {
    free(S);
    return NULL;
  }
  if (options) {
    S->options = *options;
  } else {
    S->options.libraries = FLB_LIBS_SAFE;
  }
  S->references = 1;
#if LUA_VERSION_NUM >= 505
  L = lua_newstate(allocate, S, luaL_makeseed(NULL));
#else
  L = lua_newstate(allocate, S);
#endif
  if (!L) {
    free_state(S);
    return NULL;
  }
  *(flb_state **)lua_getextraspace(L) = S;
  lua_atpanic(L, panic);
  S->L = L;
  S->frames[0]->L = L;

  memset(&o, 0, sizeof(o));
  o.S = S;
  o.f = S->frames[0];
  if (run(&o, initialize) != FLB_OK) {
    S->L = NULL;
    lua_close(L);
    free_state(S);
    return NULL;
  }
  lua_settop(L, 0);
  S->limit = S->options.memory_limit;
  S->interval = FLB_DEFAULT_INTERVAL;
  lua_sethook(L, interrupt_hook, LUA_MASKCOUNT, S->interval);
  return S;
}

void flb_close(flb_state *state) {
  lua_State *L;
  if (!state || state->depth > 0) return;
  lock();
  L = state->L;
  state->L = NULL;
  unlock();
  if (!L) return;
  state->limit = 0;
  lua_close(L);
  state->frames[0]->L = NULL;
}

int32_t flb_is_closed(const flb_state *state) {
  return (!state || !state->L) ? 1 : 0;
}

static void drop_reference(flb_state *S) {
  int unused;
  lock();
  S->references--;
  unused = S->references == 0;
  unlock();
  if (unused) free_state(S);
}

void flb_state_release(void *pointer) {
  flb_state *S = pointer;
  lua_State *L;
  if (!S) return;
  lock();
  L = S->L;
  S->L = NULL;
  unlock();
  if (L) {
    /* Possibly a finalizer thread: the host can no longer be called. */
    S->host_gone = 1;
    S->limit = 0;
    lua_close(L);
  }
  drop_reference(S);
}

/* ---- Resources ----------------------------------------------------------- */

size_t flb_memory_used(const flb_state *state) { return state ? state->used : 0; }
size_t flb_memory_limit(const flb_state *state) { return state ? state->limit : 0; }
void flb_set_memory_limit(flb_state *state, size_t bytes) {
  if (state) state->limit = bytes;
}

static int body_gc(lua_State *L) {
  op *o = begin(L);
  switch (o->flag) {
#if LUA_VERSION_NUM >= 505
    case FLB_GC_COLLECT: lua_gc(L, LUA_GCCOLLECT); break;
    case FLB_GC_STOP: lua_gc(L, LUA_GCSTOP); break;
    case FLB_GC_RESTART: lua_gc(L, LUA_GCRESTART); break;
    case FLB_GC_STEP: lua_gc(L, LUA_GCSTEP, (size_t)0); break;
#else
    case FLB_GC_COLLECT: lua_gc(L, LUA_GCCOLLECT, 0); break;
    case FLB_GC_STOP: lua_gc(L, LUA_GCSTOP, 0); break;
    case FLB_GC_RESTART: lua_gc(L, LUA_GCRESTART, 0); break;
    case FLB_GC_STEP: lua_gc(L, LUA_GCSTEP, 0); break;
#endif
    default: return argument_error(L, "invalid gc operation");
  }
  return 0;
}

int32_t flb_gc(flb_state *state, int32_t what) {
  ENTER(state);
  o.flag = what;
  return run(&o, body_gc);
}

void flb_interrupt(flb_state *state) {
  if (state) state->interrupted = 1;
}

int32_t flb_set_interrupt_interval(flb_state *state, int32_t instructions) {
  ENTER(state);
  if (instructions < 0) return fail(state, FLB_ERROR_ARGUMENT, "invalid interval");
  state->interval = instructions;
  if (instructions == 0) {
    lua_sethook(f->L, NULL, 0, 0);
  } else {
    lua_sethook(f->L, interrupt_hook, LUA_MASKCOUNT, instructions);
  }
  return FLB_OK;
}

/* ---- References ---------------------------------------------------------- */

int32_t flb_release(flb_state *state, flb_ref ref) {
  ENTER(state);
  (void)o;
  if (ref <= 0 || ref > INT_MAX) return fail(state, FLB_ERROR_ARGUMENT, "invalid reference");
  if (!lua_checkstack(f->L, 2)) return fail(state, FLB_ERROR_MEMORY, "stack overflow");
  lua_rawgetp(f->L, LUA_REGISTRYINDEX, &KEY_REFS);
  luaL_unref(f->L, -1, (int)ref);
  lua_pop(f->L, 1);
  return FLB_OK;
}

static int body_retain(lua_State *L) {
  op *o = begin(L);
  push_ref(L, o->ref);
  o->out_ref = make_ref(L, -1);
  return 0;
}

int32_t flb_retain(flb_state *state, flb_ref ref, flb_ref *out) {
  int status;
  ENTER(state);
  o.ref = ref;
  status = run(&o, body_retain);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int type_at(lua_State *L, int index) {
  switch (lua_type(L, index)) {
    case LUA_TBOOLEAN: return FLB_BOOLEAN;
    case LUA_TNUMBER: return lua_isinteger(L, index) ? FLB_INTEGER : FLB_NUMBER;
    case LUA_TSTRING: return FLB_STRING;
    case LUA_TTABLE: return FLB_TABLE;
    case LUA_TFUNCTION: return FLB_FUNCTION;
    case LUA_TUSERDATA: return FLB_USERDATA;
    case LUA_TTHREAD: return FLB_THREAD;
    case LUA_TLIGHTUSERDATA: return FLB_LIGHTUSERDATA;
    default: return FLB_NIL;
  }
}

int32_t flb_ref_type(flb_state *state, flb_ref ref, int32_t *out) {
  ENTER(state);
  (void)o;
  if (!lua_checkstack(f->L, 3)) return fail(state, FLB_ERROR_MEMORY, "stack overflow");
  if (!push_ref_plain(f->L, ref)) return fail(state, FLB_ERROR_ARGUMENT, "invalid reference");
  if (out) *out = type_at(f->L, -1);
  lua_pop(f->L, 1);
  return FLB_OK;
}

static int body_equals(lua_State *L) {
  op *o = begin(L);
  push_value(L, o->a);
  push_value(L, o->b);
  o->out_flag = lua_rawequal(L, -1, -2);
  return 0;
}

int32_t flb_equals(flb_state *state, const flb_value *left,
                    const flb_value *right, int32_t *out) {
  int status;
  ENTER(state);
  o.a = left;
  o.b = right;
  status = run(&o, body_equals);
  if (out) *out = status == FLB_OK ? o.out_flag : 0;
  return status;
}

static int body_tostring(lua_State *L) {
  op *o = begin(L);
  push_value(L, o->a);
  luaL_tolstring(L, -1, NULL);
  return emit(L, o->target, 1);
}

int32_t flb_tostring(flb_state *state, const flb_value *value,
                      const flb_value **out) {
  int status;
  ENTER(state);
  o.a = value;
  status = run(&o, body_tostring);
  give(f, status, out, NULL);
  return status;
}

static int body_copy(lua_State *L) {
  op *o = begin(L);
  copier c;
  memset(&c, 0, sizeof(c));
  c.storage = &o->f->result_pool;
  push_value(L, o->a);
  reserve(L, o->target, 1);
  o->S->override_status = FLB_ERROR_ARGUMENT;
  copy_value(L, 1, &o->target->items[o->target->count], &c, 0);
  o->S->override_status = 0;
  o->target->count++;
  return 0;
}

int32_t flb_copy(flb_state *state, const flb_value *value,
                  const flb_value **out) {
  int status;
  ENTER(state);
  o.a = value;
  status = run(&o, body_copy);
  give(f, status, out, NULL);
  return status;
}

void *flb_token_new(flb_state *state, flb_ref ref) {
  token *t;
  if (!state || ref <= 0 || ref > INT_MAX) return NULL;
  t = malloc(sizeof(token));
  if (!t) return NULL;
  t->state = state;
  t->ref = (int)ref;
  lock();
  state->references++;
  unlock();
  return t;
}

void flb_token_release(void *pointer) {
  token *t = pointer;
  flb_state *S;
  if (!t) return;
  S = t->state;
  lock();
  if (S->L) {
    if (S->pending_count == S->pending_capacity) {
      size_t capacity = S->pending_capacity ? S->pending_capacity * 2 : 16;
      int *pending = realloc(S->pending, capacity * sizeof(int));
      if (pending) {
        S->pending = pending;
        S->pending_capacity = capacity;
      }
    }
    /* If the queue could not grow the reference stays until the state closes. */
    if (S->pending_count < S->pending_capacity) S->pending[S->pending_count++] = t->ref;
  }
  unlock();
  free(t);
  drop_reference(S);
}

/* ---- Chunks -------------------------------------------------------------- */

static void load_chunk(lua_State *L, op *o, const char *mode) {
  int code;
  if (o->length && !o->s) argument_error(L, "chunk is missing");
  code = luaL_loadbufferx(L, o->s ? o->s : "", o->length,
                          o->name ? o->name : "=(chunk)", mode);
  if (code != LUA_OK) {
    o->S->override_status = translate(code);
    lua_error(L);
  }
}

static int body_load(lua_State *L) {
  op *o = begin(L);
  const char *mode = "t";
  if (o->flag == FLB_MODE_BINARY) mode = "b";
  if (o->flag == (FLB_MODE_TEXT | FLB_MODE_BINARY)) mode = "bt";
  if (o->flag & ~(FLB_MODE_TEXT | FLB_MODE_BINARY)) return argument_error(L, "invalid mode");
  load_chunk(L, o, mode);
  if (o->ref) {
    push_ref_of_type(L, o->ref, LUA_TTABLE, "environment must be a table");
    if (!lua_setupvalue(L, -2, 1)) lua_pop(L, 1);
  }
  o->out_ref = make_ref(L, -1);
  return 0;
}

int32_t flb_load(flb_state *state, const char *code, size_t length,
                  const char *name, int32_t mode, flb_ref environment,
                  flb_ref *out) {
  int status;
  ENTER(state);
  o.s = code;
  o.length = length;
  o.name = name;
  o.flag = mode;
  o.ref = environment;
  status = run(&o, body_load);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int body_run(lua_State *L) {
  op *o = begin(L);
  load_chunk(L, o, "t");
  lua_call(L, 0, LUA_MULTRET);
  return emit(L, o->target, lua_gettop(L));
}

int32_t flb_run(flb_state *state, const char *code, size_t length,
                 const char *name, const flb_value **results, size_t *count) {
  int status;
  ENTER(state);
  o.s = code;
  o.length = length;
  o.name = name;
  status = run(&o, body_run);
  if (status == FLB_OK && !results) release_values(f->L, &f->results);
  give(f, status, results, count);
  return status;
}

typedef struct dump_buffer {
  int started;
  luaL_Buffer buffer;
} dump_buffer;

static int dump_writer(lua_State *L, const void *bytes, size_t size, void *ud) {
  dump_buffer *dump = ud;
  if (!dump->started) {
    dump->started = 1;
    luaL_buffinit(L, &dump->buffer);
  }
  if (bytes && size) luaL_addlstring(&dump->buffer, bytes, size);
  return 0;
}

static int body_dump(lua_State *L) {
  op *o = begin(L);
  dump_buffer dump;
  dump.started = 0;
  push_ref_of_type(L, o->ref, LUA_TFUNCTION, "not a function");
  if (lua_iscfunction(L, -1)) return argument_error(L, "cannot dump a host function");
  if (lua_dump(L, dump_writer, &dump, o->flag) != 0) {
    return luaL_error(L, "unable to dump the function");
  }
  if (dump.started) {
    luaL_pushresult(&dump.buffer);
  } else {
    lua_pushliteral(L, "");
  }
  return emit(L, o->target, 1);
}

int32_t flb_dump(flb_state *state, flb_ref function, int32_t strip,
                  const flb_value **out) {
  int status;
  ENTER(state);
  o.ref = function;
  o.flag = strip != 0;
  status = run(&o, body_dump);
  give(f, status, out, NULL);
  return status;
}

/* ---- Calls --------------------------------------------------------------- */

/* Hands every value on the stack to the host, by reference or by value. */
static int emit_results(lua_State *L, op *o) {
  int count = lua_gettop(L);
  if (o->flag & FLB_CALL_BY_VALUE) {
    copier c;
    int i;
    memset(&c, 0, sizeof(c));
    c.storage = &o->f->result_pool;
    reserve(L, o->target, (size_t)count);
    for (i = 0; i < count; i++) {
      copy_value(L, i + 1, &o->target->items[o->target->count], &c, 0);
      o->target->count++;
    }
    return 0;
  }
  return emit(L, o->target, count);
}

static int body_call(lua_State *L) {
  op *o = begin(L);
  push_ref(L, o->ref);
  push_values(L, o->a, o->n);
  lua_call(L, (int)o->n, LUA_MULTRET);
  return emit_results(L, o);
}

int32_t flb_call(flb_state *state, flb_ref function,
                  const flb_value *arguments, size_t argument_count,
                  int32_t flags, const flb_value **results, size_t *count) {
  int status;
  ENTER(state);
  o.flag = flags;
  o.ref = function;
  o.a = arguments;
  o.n = argument_count;
  status = run(&o, body_call);
  if (status == FLB_OK && !results) release_values(f->L, &f->results);
  give(f, status, results, count);
  return status;
}

static int body_call_method(lua_State *L) {
  op *o = begin(L);
  if (!o->name) return argument_error(L, "method name is missing");
  push_ref(L, o->ref);
  lua_getfield(L, 1, o->name);
  if (o->out_flag) {
    /* object.name(...): the object is not passed. */
    lua_remove(L, 1);
    push_values(L, o->a, o->n);
    lua_call(L, (int)o->n, LUA_MULTRET);
  } else {
    lua_insert(L, 1);
    push_values(L, o->a, o->n);
    lua_call(L, (int)o->n + 1, LUA_MULTRET);
  }
  return emit_results(L, o);
}

static int32_t call_named(flb_state *state, flb_ref object, const char *name,
                          const flb_value *arguments, size_t argument_count,
                          int32_t flags, int field, const flb_value **results,
                          size_t *count) {
  int status;
  ENTER(state);
  o.flag = flags;
  o.out_flag = field;
  o.ref = object;
  o.name = name;
  o.a = arguments;
  o.n = argument_count;
  status = run(&o, body_call_method);
  if (status == FLB_OK && !results) release_values(f->L, &f->results);
  give(f, status, results, count);
  return status;
}

int32_t flb_call_field(flb_state *state, flb_ref object, const char *name,
                       const flb_value *arguments, size_t argument_count,
                       int32_t flags, const flb_value **results, size_t *count) {
  return call_named(state, object, name, arguments, argument_count, flags, 1,
                    results, count);
}

int32_t flb_call_method(flb_state *state, flb_ref object, const char *name,
                         const flb_value *arguments, size_t argument_count,
                         int32_t flags, const flb_value **results, size_t *count) {
  return call_named(state, object, name, arguments, argument_count, flags, 0,
                    results, count);
}

/* ---- Tables and globals -------------------------------------------------- */

static int body_globals(lua_State *L) {
  op *o = begin(L);
  lua_pushglobaltable(L);
  o->out_ref = make_ref(L, -1);
  return 0;
}

int32_t flb_globals(flb_state *state, flb_ref *out) {
  int status;
  ENTER(state);
  status = run(&o, body_globals);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int body_get_global(lua_State *L) {
  op *o = begin(L);
  if (!o->name) return argument_error(L, "name is missing");
  lua_getglobal(L, o->name);
  return emit(L, o->target, 1);
}

int32_t flb_get_global(flb_state *state, const char *name,
                        const flb_value **out) {
  int status;
  ENTER(state);
  o.name = name;
  status = run(&o, body_get_global);
  give(f, status, out, NULL);
  return status;
}

static int body_set_global(lua_State *L) {
  op *o = begin(L);
  if (!o->name) return argument_error(L, "name is missing");
  push_value(L, o->a);
  lua_setglobal(L, o->name);
  return 0;
}

int32_t flb_set_global(flb_state *state, const char *name,
                        const flb_value *value) {
  ENTER(state);
  o.name = name;
  o.a = value;
  return run(&o, body_set_global);
}

static int body_table_new(lua_State *L) {
  op *o = begin(L);
  size_t i;
  if (o->n && !o->a) return argument_error(L, "pairs are missing");
  lua_createtable(L, 0, o->n > 1024 ? 1024 : (int)o->n);
  for (i = 0; i < o->n; i++) {
    push_value(L, &o->a[2 * i]);
    push_value(L, &o->a[2 * i + 1]);
    lua_rawset(L, 1);
  }
  o->out_ref = make_ref(L, 1);
  return 0;
}

int32_t flb_table_new(flb_state *state, const flb_value *pairs,
                       size_t pair_count, flb_ref *out) {
  int status;
  ENTER(state);
  o.a = pairs;
  o.n = pair_count;
  status = run(&o, body_table_new);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int body_sequence_new(lua_State *L) {
  op *o = begin(L);
  size_t i;
  if (o->n && !o->a) return argument_error(L, "items are missing");
  lua_createtable(L, o->n > 1024 ? 1024 : (int)o->n, 0);
  for (i = 0; i < o->n; i++) {
    push_value(L, &o->a[i]);
    lua_rawseti(L, 1, (lua_Integer)i + 1);
  }
  o->out_ref = make_ref(L, 1);
  return 0;
}

int32_t flb_sequence_new(flb_state *state, const flb_value *items,
                          size_t count, flb_ref *out) {
  int status;
  ENTER(state);
  o.a = items;
  o.n = count;
  status = run(&o, body_sequence_new);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static void push_object(lua_State *L, op *o) {
  push_ref(L, o->ref);
  if (o->flag && !lua_istable(L, -1)) argument_error(L, "raw access requires a table");
}

static int body_get(lua_State *L) {
  op *o = begin(L);
  push_object(L, o);
  push_value(L, o->a);
  if (o->flag) {
    lua_rawget(L, 1);
  } else {
    lua_gettable(L, 1);
  }
  return emit(L, o->target, 1);
}

int32_t flb_get(flb_state *state, flb_ref object, const flb_value *key,
                 int32_t raw, const flb_value **out) {
  int status;
  ENTER(state);
  o.ref = object;
  o.a = key;
  o.flag = raw != 0;
  status = run(&o, body_get);
  give(f, status, out, NULL);
  return status;
}

static int body_set(lua_State *L) {
  op *o = begin(L);
  push_object(L, o);
  push_value(L, o->a);
  push_value(L, o->b);
  if (o->flag) {
    lua_rawset(L, 1);
  } else {
    lua_settable(L, 1);
  }
  return 0;
}

int32_t flb_set(flb_state *state, flb_ref object, const flb_value *key,
                 const flb_value *value, int32_t raw) {
  ENTER(state);
  o.ref = object;
  o.a = key;
  o.b = value;
  o.flag = raw != 0;
  return run(&o, body_set);
}

static int body_length(lua_State *L) {
  op *o = begin(L);
  push_ref(L, o->ref);
  o->out_integer = o->flag ? (int64_t)lua_rawlen(L, 1) : (int64_t)luaL_len(L, 1);
  return 0;
}

int32_t flb_length(flb_state *state, flb_ref object, int32_t raw,
                    int64_t *out) {
  int status;
  ENTER(state);
  o.ref = object;
  o.flag = raw != 0;
  status = run(&o, body_length);
  if (out) *out = status == FLB_OK ? o.out_integer : 0;
  return status;
}

static int body_pairs(lua_State *L) {
  op *o = begin(L);
  push_ref_of_type(L, o->ref, LUA_TTABLE, "not a table");
  lua_pushnil(L);
  while (lua_next(L, 1)) {
    luaL_checkstack(L, 4, "table is too large for flb_pairs; use flb_next");
    lua_pushvalue(L, -2); /* the key again, consumed by the next lua_next */
  }
  lua_remove(L, 1);
  return emit(L, o->target, lua_gettop(L));
}

int32_t flb_pairs(flb_state *state, flb_ref table, const flb_value **out,
                   size_t *pair_count) {
  int status;
  size_t count = 0;
  ENTER(state);
  o.ref = table;
  status = run(&o, body_pairs);
  give(f, status, out, &count);
  if (pair_count) *pair_count = count / 2;
  return status;
}

static int body_sequence(lua_State *L) {
  op *o = begin(L);
  lua_Unsigned length, i;
  push_ref_of_type(L, o->ref, LUA_TTABLE, "not a table");
  length = lua_rawlen(L, 1);
  if (length > (lua_Unsigned)INT_MAX / 2) return luaL_error(L, "sequence is too long");
  luaL_checkstack(L, (int)length + LUA_MINSTACK, "sequence is too long");
  for (i = 1; i <= length; i++) lua_rawgeti(L, 1, (lua_Integer)i);
  lua_remove(L, 1);
  return emit(L, o->target, (int)length);
}

int32_t flb_sequence(flb_state *state, flb_ref table, const flb_value **out,
                      size_t *count) {
  int status;
  ENTER(state);
  o.ref = table;
  status = run(&o, body_sequence);
  give(f, status, out, count);
  return status;
}

static int body_next(lua_State *L) {
  op *o = begin(L);
  push_ref_of_type(L, o->ref, LUA_TTABLE, "not a table");
  push_value(L, o->a);
  if (!lua_next(L, 1)) {
    o->out_flag = 0;
    return 0;
  }
  o->out_flag = 1;
  return emit(L, o->target, 2);
}

int32_t flb_next(flb_state *state, flb_ref table, const flb_value *key,
                  const flb_value **out, int32_t *has_next) {
  int status;
  ENTER(state);
  o.ref = table;
  o.a = key;
  status = run(&o, body_next);
  give(f, status, out, NULL);
  if (has_next) *has_next = status == FLB_OK ? o.out_flag : 0;
  return status;
}

static int body_get_metatable(lua_State *L) {
  op *o = begin(L);
  push_ref(L, o->ref);
  if (lua_getmetatable(L, 1)) o->out_ref = make_ref(L, -1);
  return 0;
}

int32_t flb_get_metatable(flb_state *state, flb_ref object, flb_ref *out) {
  int status;
  ENTER(state);
  o.ref = object;
  status = run(&o, body_get_metatable);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int body_set_metatable(lua_State *L) {
  op *o = begin(L);
  push_ref(L, o->ref);
  if (o->ref2) {
    push_ref_of_type(L, o->ref2, LUA_TTABLE, "metatable must be a table");
  } else {
    lua_pushnil(L);
  }
  lua_setmetatable(L, 1);
  return 0;
}

int32_t flb_set_metatable(flb_state *state, flb_ref object,
                           flb_ref metatable) {
  ENTER(state);
  o.ref = object;
  o.ref2 = metatable;
  return run(&o, body_set_metatable);
}

/* ---- Host functions and objects ------------------------------------------ */

static frame *host_frame(lua_State *L, flb_state *S) {
  frame *f;
  if (S->depth + 1 >= FLB_MAX_DEPTH) luaL_error(L, "host calls are nested too deeply");
  f = S->frames[S->depth + 1];
  if (!f) {
    f = calloc(1, sizeof(frame));
    if (!f) luaL_error(L, "not enough memory");
    S->frames[S->depth + 1] = f;
  }
  return f;
}

/* Raises the error held in S->host_failure, as a failed host call does. */
static int raise_host_failure(lua_State *L, flb_state *S) {
  lua_pushlstring(L, S->host_failure ? S->host_failure : "", S->host_failure_length);
  return lua_error(L);
}

/*
 * Runs when a coroutine suspended by flb_yield is resumed: in C, never in the
 * host. Above `ctx` (the argument anchors) lie the resume arguments, which
 * become the host function's results, or the marker of flb_resume_failure
 * followed by the message.
 */
static int host_continue(lua_State *L, int status, lua_KContext ctx) {
  int base = (int)ctx;
  (void)status;
  if (lua_gettop(L) > base && lua_type(L, base + 1) == LUA_TLIGHTUSERDATA &&
      lua_touserdata(L, base + 1) == (void *)&KEY_RESUME_FAILURE) {
    flb_state *S = state_of(L);
    lua_settop(L, base + 2);
    return raise_host_failure(L, S);
  }
  return lua_gettop(L) - base;
}

/* The Lua function behind every host function. Upvalue 1 is the holder. */
static int host_function(lua_State *L) {
  flb_state *S = state_of(L);
  const holder *h = lua_touserdata(L, lua_upvalueindex(1));
  int count = lua_gettop(L);
  frame *f;
  if (!S->options.call || S->host_gone) return luaL_error(L, "the host is not available");
  f = host_frame(L, S);
  f->arguments.count = 0;
  f->results.count = 0;
  pool_reset(&f->argument_pool);
  if (h->flags & FLB_FUNCTION_BY_VALUE) {
    copier c;
    int i;
    memset(&c, 0, sizeof(c));
    c.storage = &f->argument_pool;
    reserve(L, &f->arguments, (size_t)count);
    for (i = 0; i < count; i++) {
      copy_value(L, i + 1, &f->arguments.items[i], &c, 0);
      f->arguments.count++;
    }
  } else {
    emit(L, &f->arguments, count); /* the arguments stay on the stack as anchors */
  }
  f->L = L;
  f->base = count;
  f->argument_top = count;
  f->returned = 0;
  f->failed = 0;
  f->yielded = 0;

  S->depth++;
  S->options.call(S, h->id, f->arguments.items, (size_t)count);
  S->depth--;

  if (f->failed) {
    lua_settop(L, count);
    free(S->host_failure);
    S->host_failure = f->failure_message;
    S->host_failure_length = f->failure_length;
    S->host_failure_id = f->failure_id;
    f->failure_message = NULL;
    return raise_host_failure(L, S);
  }
  lua_settop(L, count + f->returned);
  if (f->yielded) {
    /* The host has returned: only C frames lie between here and the resume,
     * so Lua may unwind them. Raises if the caller cannot yield. */
    return lua_yieldk(L, f->returned, (lua_KContext)count, host_continue);
  }
  return f->returned;
}

static int body_function_new(lua_State *L) {
  op *o = begin(L);
  holder *h = lua_newuserdata(L, sizeof(holder));
  h->id = o->id;
  h->flags = o->flag;
  lua_rawgetp(L, LUA_REGISTRYINDEX, &KEY_FUNCTION_HOLDER);
  lua_setmetatable(L, -2);
  lua_pushcclosure(L, host_function, 1);
  o->out_ref = make_ref(L, -1);
  return 0;
}

int32_t flb_function_new(flb_state *state, int64_t function_id,
                          int32_t flags, flb_ref *out) {
  int status;
  ENTER(state);
  o.id = function_id;
  o.flag = flags;
  status = run(&o, body_function_new);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int body_return(lua_State *L) {
  op *o = begin(L);
  push_values(L, o->a, o->n);
  return (int)o->n;
}

static int32_t host_results(flb_state *state, const flb_value *values,
                            size_t count, int yield) {
  frame *f;
  op o;
  int status;
  if (!state || !state->L) return FLB_ERROR_CLOSED;
  if (state->depth == 0) return fail(state, FLB_ERROR_ARGUMENT, "not inside a host function");
  f = state->frames[state->depth];
  f->base = f->argument_top;
  f->returned = 0;
  f->failed = 0;
  f->yielded = 0;
  lua_settop(f->L, f->base);
  memset(&o, 0, sizeof(o));
  o.S = state;
  o.f = f;
  o.a = values;
  o.n = count;
  status = run(&o, body_return);
  if (status == FLB_OK) {
    f->returned = (int)count;
    f->base = f->argument_top + (int)count;
    f->yielded = yield;
  }
  return status;
}

int32_t flb_return(flb_state *state, const flb_value *values, size_t count) {
  return host_results(state, values, count, 0);
}

int32_t flb_yield(flb_state *state, const flb_value *values, size_t count) {
  return host_results(state, values, count, 1);
}

int32_t flb_can_yield(flb_state *state) {
  if (!state || !state->L || state->depth == 0) return 0;
  return lua_isyieldable(state->frames[state->depth]->L) ? 1 : 0;
}

int32_t flb_fail(flb_state *state, int64_t host_error_id, const char *message,
                  size_t length) {
  frame *f;
  if (!state || !state->L) return FLB_ERROR_CLOSED;
  if (state->depth == 0) return fail(state, FLB_ERROR_ARGUMENT, "not inside a host function");
  f = state->frames[state->depth];
  free(f->failure_message);
  f->failure_message = copy_bytes(message ? message : "", message ? length : 0);
  f->failure_length = f->failure_message ? (message ? length : 0) : 0;
  f->failure_id = host_error_id;
  f->failed = 1;
  f->returned = 0;
  f->yielded = 0;
  return FLB_OK;
}

static int body_class_new(lua_State *L) {
  op *o = begin(L);
  lua_newtable(L);
  lua_pushstring(L, o->name ? o->name : "host object");
  lua_setfield(L, 1, "__name");
  lua_pushcfunction(L, host_object_gc);
  lua_setfield(L, 1, "__gc");
  lua_pushboolean(L, 1);
  lua_rawsetp(L, 1, &KEY_HOST_OBJECT);
  o->out_ref = make_ref(L, 1);
  return 0;
}

int32_t flb_class_new(flb_state *state, const char *name, flb_ref *out) {
  int status;
  ENTER(state);
  o.name = name;
  status = run(&o, body_class_new);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int body_object_new(lua_State *L) {
  op *o = begin(L);
  holder *h;
  push_ref_of_type(L, o->ref, LUA_TTABLE, "not a class metatable");
  lua_rawgetp(L, 1, &KEY_HOST_OBJECT);
  if (!lua_toboolean(L, -1)) return argument_error(L, "not a class metatable");
  lua_pop(L, 1);
  h = lua_newuserdata(L, sizeof(holder));
  h->id = o->id;
  h->flags = 0;
  lua_pushvalue(L, 1);
  lua_setmetatable(L, -2);
  o->out_ref = make_ref(L, -1);
  return 0;
}

int32_t flb_object_new(flb_state *state, flb_ref class_metatable,
                        int64_t object_id, flb_ref *out) {
  int status;
  ENTER(state);
  o.ref = class_metatable;
  o.id = object_id;
  status = run(&o, body_object_new);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

/* ---- Modules ------------------------------------------------------------- */

static void push_package(lua_State *L) {
  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
  lua_getfield(L, -1, LUA_LOADLIBNAME);
  if (!lua_istable(L, -1)) argument_error(L, "FLB_LIB_REQUIRE is not selected");
  lua_remove(L, -2);
}

static int body_preload(lua_State *L) {
  op *o = begin(L);
  if (!o->name) return argument_error(L, "module name is missing");
  push_package(L);
  lua_getfield(L, -1, "preload");
  if (!lua_istable(L, -1)) return luaL_error(L, "package.preload is not a table");
  push_ref_of_type(L, o->ref, LUA_TFUNCTION, "loader must be a function");
  lua_setfield(L, -2, o->name);
  return 0;
}

int32_t flb_preload(flb_state *state, const char *name, flb_ref loader) {
  ENTER(state);
  o.name = name;
  o.ref = loader;
  return run(&o, body_preload);
}

static int body_set_module(lua_State *L) {
  op *o = begin(L);
  if (!o->name) return argument_error(L, "module name is missing");
  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
  push_value(L, o->a);
  lua_setfield(L, -2, o->name);
  return 0;
}

int32_t flb_set_module(flb_state *state, const char *name,
                        const flb_value *value) {
  ENTER(state);
  o.name = name;
  o.a = value;
  return run(&o, body_set_module);
}

static int body_get_module(lua_State *L) {
  op *o = begin(L);
  if (!o->name) return argument_error(L, "module name is missing");
  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_LOADED_TABLE);
  lua_getfield(L, -1, o->name);
  return emit(L, o->target, 1);
}

int32_t flb_get_module(flb_state *state, const char *name,
                        const flb_value **out) {
  int status;
  ENTER(state);
  o.name = name;
  status = run(&o, body_get_module);
  give(f, status, out, NULL);
  return status;
}

static int body_add_searcher(lua_State *L) {
  op *o = begin(L);
  push_package(L);
  lua_getfield(L, -1, "searchers");
  if (!lua_istable(L, -1)) return luaL_error(L, "package.searchers is not a table");
  push_ref_of_type(L, o->ref, LUA_TFUNCTION, "searcher must be a function");
  lua_rawseti(L, -2, (lua_Integer)lua_rawlen(L, -2) + 1);
  return 0;
}

int32_t flb_add_searcher(flb_state *state, flb_ref searcher) {
  ENTER(state);
  o.ref = searcher;
  return run(&o, body_add_searcher);
}

/* ---- Coroutines ---------------------------------------------------------- */

static int body_thread_new(lua_State *L) {
  op *o = begin(L);
  lua_State *thread = lua_newthread(L);
  push_ref_of_type(L, o->ref, LUA_TFUNCTION, "not a function");
  lua_xmove(L, thread, 1);
  o->out_ref = make_ref(L, 1);
  return 0;
}

int32_t flb_thread_new(flb_state *state, flb_ref function, flb_ref *out) {
  int status;
  ENTER(state);
  o.ref = function;
  status = run(&o, body_thread_new);
  if (out) *out = status == FLB_OK ? o.out_ref : 0;
  return status;
}

static int thread_status(lua_State *L, lua_State *thread) {
  lua_Debug ar;
  if (thread == L) return FLB_THREAD_RUNNING;
  switch (lua_status(thread)) {
    case LUA_YIELD: return FLB_THREAD_SUSPENDED;
    case LUA_OK:
      if (lua_getstack(thread, 0, &ar)) return FLB_THREAD_NORMAL;
      return lua_gettop(thread) == 0 ? FLB_THREAD_DEAD : FLB_THREAD_SUSPENDED;
    default: return FLB_THREAD_DEAD;
  }
}

/* Leaves the thread on the frame's stack as an anchor; NULL if not a thread. */
static lua_State *thread_of(frame *f, flb_ref ref) {
  lua_State *thread;
  if (!lua_checkstack(f->L, 3) || !push_ref_plain(f->L, ref)) return NULL;
  thread = lua_tothread(f->L, -1);
  if (!thread) lua_pop(f->L, 1);
  return thread;
}

static int body_push_arguments(lua_State *L) {
  op *o = begin(L);
  push_values(L, o->a, o->n);
  return (int)o->n;
}

static int body_emit_arguments(lua_State *L) {
  op *o = begin(L);
  return emit(L, o->target, lua_gettop(L));
}

static int body_thread_traceback(lua_State *L) {
  op *o = begin(L);
  const char *message = lua_type(o->thread, -1) == LUA_TSTRING
                            ? lua_tostring(o->thread, -1)
                            : NULL;
  luaL_traceback(L, o->thread, message, 0);
  lua_rawsetp(L, LUA_REGISTRYINDEX, &KEY_TRACEBACK);
  return 0;
}

/* Moves the error on top of `thread` to the frame and records it. */
static int capture_thread_error(op *o, lua_State *thread, int code) {
  lua_State *L = o->f->L;
  if (!lua_checkstack(L, 4)) return fail(o->S, FLB_ERROR_MEMORY, "stack overflow");
  o->thread = thread;
  lua_pushcfunction(L, body_thread_traceback);
  lua_pushlightuserdata(L, o);
  if (lua_pcall(L, 1, 0, 0) != LUA_OK) lua_pop(L, 1);
  if (lua_gettop(thread) > 0) {
    lua_xmove(thread, L, 1);
  } else {
    lua_pushnil(L);
  }
  return capture(o->S, o->f, code, NULL);
}

/* Whether `thread` is suspended by flb_yield, inside a host function. */
static int suspended_in_host(lua_State *thread) {
  lua_Debug ar;
  int found;
  if (lua_status(thread) != LUA_YIELD || !lua_getstack(thread, 0, &ar)) return 0;
  if (!lua_checkstack(thread, 1)) return 0;
  lua_getinfo(thread, "f", &ar); /* pushes the function onto the thread */
  found = lua_tocfunction(thread, -1) == host_function;
  lua_pop(thread, 1);
  return found;
}

static int body_push_failure(lua_State *L) {
  op *o = begin(L);
  lua_pushlightuserdata(L, (void *)&KEY_RESUME_FAILURE);
  lua_pushlstring(L, o->s ? o->s : "", o->s ? o->length : 0);
  return 2;
}

/* flb_resume, or flb_resume_failure when `failure` is set. */
static int32_t resume(flb_state *state, flb_ref thread_ref,
                      const flb_value *arguments, size_t argument_count,
                      int failure, int64_t host_error_id, const char *message,
                      size_t length, const flb_value **results, size_t *count) {
  lua_State *thread;
  int status, code, produced, pushed;
  ENTER(state);
  give(f, FLB_ERROR_ARGUMENT, results, count);
  thread = thread_of(f, thread_ref);
  if (!thread) return fail(state, FLB_ERROR_ARGUMENT, "not a thread");
  if (thread_status(f->L, thread) != FLB_THREAD_SUSPENDED) {
    return fail(state, FLB_ERROR_ARGUMENT, "cannot resume a coroutine that is not suspended");
  }
  if (failure && !suspended_in_host(thread)) {
    return fail(state, FLB_ERROR_ARGUMENT, "the coroutine is not suspended in a host function");
  }
  o.intermediate = 1;
  if (failure) {
    o.s = message;
    o.length = message ? length : 0;
    status = run(&o, body_push_failure);
    pushed = 2;
  } else {
    o.a = arguments;
    o.n = argument_count;
    status = run(&o, body_push_arguments);
    pushed = (int)argument_count;
  }
  if (status != FLB_OK) return status;
  if (!lua_checkstack(thread, pushed + 1)) {
    return fail(state, FLB_ERROR_MEMORY, "stack overflow");
  }
  if (failure) {
    /* What the continuation raises; capture matches it to host_error_id. */
    free(state->host_failure);
    state->host_failure = copy_bytes(message ? message : "", message ? length : 0);
    state->host_failure_length = state->host_failure ? (message ? length : 0) : 0;
    state->host_failure_id = host_error_id;
  }
  lua_xmove(f->L, thread, pushed);
#if LUA_VERSION_NUM >= 504
  code = lua_resume(thread, f->L, pushed, &produced);
#else
  code = lua_resume(thread, f->L, pushed);
  produced = lua_gettop(thread);
#endif
  if (code != LUA_OK && code != LUA_YIELD) return capture_thread_error(&o, thread, code);
  status = run_with(&o, body_emit_arguments, thread, produced);
  if (status != FLB_OK) return status;
  status = finish(state, code == LUA_YIELD ? FLB_YIELD : FLB_OK);
  if (!results) release_values(f->L, &f->results);
  give(f, status, results, count);
  return status;
}

int32_t flb_resume(flb_state *state, flb_ref thread_ref,
                    const flb_value *arguments, size_t argument_count,
                    const flb_value **results, size_t *count) {
  return resume(state, thread_ref, arguments, argument_count, 0, 0, NULL, 0,
                results, count);
}

int32_t flb_resume_failure(flb_state *state, flb_ref thread_ref,
                            int64_t host_error_id, const char *message,
                            size_t length, const flb_value **results,
                            size_t *count) {
  return resume(state, thread_ref, NULL, 0, 1, host_error_id, message, length,
                results, count);
}

int32_t flb_thread_status(flb_state *state, flb_ref thread_ref,
                           int32_t *out) {
  lua_State *thread;
  ENTER(state);
  (void)o;
  thread = thread_of(f, thread_ref);
  if (!thread) return fail(state, FLB_ERROR_ARGUMENT, "not a thread");
  if (out) *out = thread_status(f->L, thread);
  return FLB_OK;
}

int32_t flb_thread_close(flb_state *state, flb_ref thread_ref) {
  lua_State *thread;
  int code = LUA_OK;
  int current;
  ENTER(state);
  thread = thread_of(f, thread_ref);
  if (!thread) return fail(state, FLB_ERROR_ARGUMENT, "not a thread");
  current = thread_status(f->L, thread);
  if (current == FLB_THREAD_RUNNING || current == FLB_THREAD_NORMAL) {
    return fail(state, FLB_ERROR_ARGUMENT, "cannot close a running coroutine");
  }
#if LUA_VERSION_NUM >= 505 || \
    (LUA_VERSION_NUM == 504 && defined(LUA_VERSION_RELEASE_NUM) && LUA_VERSION_RELEASE_NUM >= 50406)
  code = lua_closethread(thread, f->L);
#elif LUA_VERSION_NUM == 504
  code = lua_resetthread(thread);
#else
  /* Lua 5.3 has no to-be-closed variables and cannot reset a coroutine: it
   * is simply collected once the host releases its reference. */
#endif
  if (code != LUA_OK) return capture_thread_error(&o, thread, code);
  return finish(state, FLB_OK);
}
