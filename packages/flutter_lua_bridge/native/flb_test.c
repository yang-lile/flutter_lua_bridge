/* Native tests for flb. Built and run with sanitizers by tool/test_native.py
 * against every bundled Lua release. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "flb.h"

static int checks = 0;

#define CHECK(condition)                                                    \
  do {                                                                      \
    checks++;                                                               \
    if (!(condition)) {                                                     \
      fprintf(stderr, "%s:%d: check failed: %s\n", __FILE__, __LINE__,      \
              #condition);                                                  \
      exit(1);                                                              \
    }                                                                       \
  } while (0)

#define OK(call) CHECK((call) == FLB_OK)

static flb_value nil_value(void) {
  flb_value v;
  memset(&v, 0, sizeof(v));
  return v;
}
static flb_value integer(int64_t i) {
  flb_value v = nil_value();
  v.type = FLB_INTEGER;
  v.i = i;
  return v;
}
static flb_value number(double n) {
  flb_value v = nil_value();
  v.type = FLB_NUMBER;
  v.n = n;
  return v;
}
static flb_value boolean(int b) {
  flb_value v = nil_value();
  v.type = FLB_BOOLEAN;
  v.i = b;
  return v;
}
static flb_value bytes(const char *s, size_t length) {
  flb_value v = nil_value();
  v.type = FLB_STRING;
  v.bytes = s;
  v.length = length;
  return v;
}
static flb_value string(const char *s) { return bytes(s, strlen(s)); }
static flb_value reference(int32_t type, flb_ref ref) {
  flb_value v = nil_value();
  v.type = type;
  v.i = ref;
  return v;
}
static int is_string(const flb_value *v, const char *expected);
/* The value stored under a string key of a by-value table. */
static const flb_value *field(const flb_value *table, const char *name) {
  size_t i;
  for (i = 0; i < table->length; i++) {
    if (is_string(&table->items[2 * i], name)) return &table->items[2 * i + 1];
  }
  return NULL;
}
static int is_string(const flb_value *v, const char *expected) {
  return v->type == FLB_STRING && v->length == strlen(expected) &&
         memcmp(v->bytes, expected, v->length) == 0;
}
static int message_contains(flb_state *S, const char *text) {
  return strstr(flb_error_message(S, NULL), text) != NULL;
}

/* Runs a chunk and expects exactly one result. */
static const flb_value *eval(flb_state *S, const char *code) {
  const flb_value *results = NULL;
  size_t count = 0;
  int status = flb_run(S, code, strlen(code), "=test", &results, &count);
  if (status != FLB_OK) {
    fprintf(stderr, "eval failed: %s\n%s\n", flb_error_message(S, NULL), code);
    exit(1);
  }
  if (count != 1) {
    fprintf(stderr, "eval returned %d values: %s\n", (int)count, code);
    exit(1);
  }
  checks++;
  return results;
}

/* ---- Host callbacks ------------------------------------------------------ */

enum {
  FN_BY_VALUE = 900, FN_ADD = 1,
  FN_FAIL = 2,
  FN_CALL_BACK = 3,
  FN_SWAP = 4,
  FN_OBJECT_ID = 5,
  FN_INTERRUPT = 6,
  FN_LOADER = 7,
  FN_SEARCHER = 8,
  FN_AWAIT = 9,
  FN_CAN_YIELD = 10
};

static int released_functions = 0;
static int released_objects = 0;
static int64_t last_released_object = 0;
static flb_ref call_back_target = 0;

static void host_call(flb_state *S, int64_t id, const flb_value *args,
                      size_t count) {
  switch (id) {
    case FN_ADD: {
      flb_value result;
      if (count != 2 || args[0].type != FLB_INTEGER || args[1].type != FLB_INTEGER) {
        flb_fail(S, 0, "add expects two integers", 24);
        return;
      }
      result = integer(args[0].i + args[1].i);
      flb_return(S, &result, 1);
      return;
    }
    case FN_FAIL:
      flb_fail(S, 4242, "host exploded", 13);
      return;
    case FN_BY_VALUE: {
      /* Receives {name = 'n', list = {10, 20}} and 7 as plain data. */
      const flb_value *list = field(&args[0], "list");
      flb_value result;
      CHECK(count == 2 && args[0].type == FLB_TABLE_VALUE && args[0].length == 2);
      CHECK(is_string(field(&args[0], "name"), "n"));
      CHECK(list && list->type == FLB_TABLE_VALUE && list->length == 2);
      CHECK(list->items[0].type == FLB_INTEGER && list->items[1].type == FLB_INTEGER);
      /* A nested call must not disturb the copied arguments. */
      CHECK(eval(S, "return 'nested'")->type == FLB_STRING);
      CHECK(is_string(field(&args[0], "name"), "n"));
      result = integer(list->items[1].i + list->items[3].i + args[1].i);
      flb_return(S, &result, 1);
      return;
    }
    case FN_CALL_BACK: {
      /* Re-enters Lua from inside a host function; the arguments of this
       * call must survive the nested calls. */
      const flb_value *nested = NULL;
      size_t nested_count = 0;
      flb_value doubled;
      flb_value argument = integer(args[0].i);
      OK(flb_call(S, call_back_target, &argument, 1, 0, &nested, &nested_count));
      CHECK(nested_count == 1 && nested[0].type == FLB_INTEGER);
      doubled = integer(nested[0].i);
      CHECK(eval(S, "return 'nested'")->type == FLB_STRING);
      CHECK(args[0].type == FLB_INTEGER && is_string(&args[1], "kept"));
      flb_return(S, &doubled, 1);
      return;
    }
    case FN_SWAP: {
      flb_value swapped[2];
      swapped[0] = args[1];
      swapped[1] = args[0];
      flb_return(S, swapped, 2);
      return;
    }
    case FN_OBJECT_ID: {
      flb_value result = integer(args[0].id);
      CHECK(args[0].type == FLB_USERDATA);
      OK(flb_release(S, args[0].i));
      flb_return(S, &result, 1);
      return;
    }
    case FN_INTERRUPT:
      flb_interrupt(S);
      return;
    case FN_LOADER: {
      flb_value result = string("module value");
      flb_return(S, &result, 1);
      return;
    }
    case FN_SEARCHER: {
      /* Finds only "dynamic"; anything else gets an explanation string. */
      if (count >= 1 && is_string(&args[0], "dynamic")) {
        flb_ref loader = 0;
        flb_value result;
        OK(flb_function_new(S, FN_LOADER, 0, &loader));
        result = reference(FLB_FUNCTION, loader);
        flb_return(S, &result, 1);
        OK(flb_release(S, loader));
      } else {
        flb_value result = string("\n\tno host module");
        flb_return(S, &result, 1);
      }
      return;
    }
    case FN_AWAIT:
      /* Suspends the calling coroutine, yielding the arguments. */
      OK(flb_yield(S, args, count));
      return;
    case FN_CAN_YIELD: {
      flb_value result = boolean(flb_can_yield(S));
      flb_return(S, &result, 1);
      return;
    }
    default:
      flb_fail(S, 0, "unknown host function", 21);
  }
}

static void host_release(flb_state *S, int64_t id, int32_t is_object) {
  (void)S;
  if (is_object) {
    released_objects++;
    last_released_object = id;
  } else {
    released_functions++;
  }
}

static flb_state *open(uint32_t libraries, size_t memory_limit) {
  flb_options options;
  flb_state *S;
  memset(&options, 0, sizeof(options));
  options.libraries = libraries;
  options.memory_limit = memory_limit;
  options.call = host_call;
  options.release = host_release;
  S = flb_open(&options);
  CHECK(S != NULL);
  return S;
}

static void set_host_function(flb_state *S, const char *name, int64_t id) {
  flb_ref function = 0;
  flb_value value;
  OK(flb_function_new(S, id, id == FN_BY_VALUE ? FLB_FUNCTION_BY_VALUE : 0, &function));
  value = reference(FLB_FUNCTION, function);
  OK(flb_set_global(S, name, &value));
  OK(flb_release(S, function));
}

/* ---- Tests --------------------------------------------------------------- */

static void test_library(void) {
  int version = flb_lua_version();
  CHECK(flb_abi_version() == FLB_ABI_VERSION);
  CHECK(version == 503 || version == 504 || version == 505);
  CHECK(strncmp(flb_lua_release(), "Lua 5.", 6) == 0);
  CHECK(strcmp(flb_status_name(FLB_ERROR_SYNTAX), "syntax error") == 0);
  CHECK(strcmp(flb_type_name(FLB_TABLE), "table") == 0);
}

static void test_values(flb_state *S) {
  const flb_value *results = NULL;
  size_t count = 0;
  const char *code =
      "return nil, true, 42, 42.0, 1.5, 'a\\0b', math.maxinteger, {}, print";
  OK(flb_run(S, code, strlen(code), "=values", &results, &count));
  CHECK(count == 9);
  CHECK(results[0].type == FLB_NIL);
  CHECK(results[1].type == FLB_BOOLEAN && results[1].i == 1);
  CHECK(results[2].type == FLB_INTEGER && results[2].i == 42);
  CHECK(results[3].type == FLB_NUMBER && results[3].n == 42.0);
  CHECK(results[4].type == FLB_NUMBER && results[4].n == 1.5);
  CHECK(results[5].type == FLB_STRING && results[5].length == 3);
  CHECK(memcmp(results[5].bytes, "a\0b", 3) == 0);
  CHECK(results[6].type == FLB_INTEGER && results[6].i == INT64_MAX);
  CHECK(results[7].type == FLB_TABLE && results[7].i > 0);
  CHECK(results[8].type == FLB_FUNCTION && results[8].i > 0);
  {
    flb_ref table = results[7].i, function = results[8].i;
    int32_t type = 0;
    OK(flb_ref_type(S, table, &type));
    CHECK(type == FLB_TABLE);
    OK(flb_release(S, table));
    OK(flb_release(S, function));
    CHECK(flb_ref_type(S, table, &type) == FLB_ERROR_ARGUMENT);
  }
  /* A chunk with no results, and discarding results. */
  OK(flb_run(S, "x = 1", 5, NULL, &results, &count));
  CHECK(count == 0 && results == NULL);
  OK(flb_run(S, "return {}, {}", 13, NULL, NULL, NULL));
}

static void test_globals_and_calls(flb_state *S) {
  const flb_value *out = NULL;
  size_t count = 0;
  flb_value value = integer(10);
  flb_value arguments[2];
  flb_ref function;

  OK(flb_set_global(S, "x", &value));
  OK(flb_get_global(S, "x", &out));
  CHECK(out->type == FLB_INTEGER && out->i == 10);
  OK(flb_get_global(S, "missing", &out));
  CHECK(out->type == FLB_NIL);

  CHECK(eval(S, "function divmod(a, b) return a // b, a % b end return 1")->i == 1);
  OK(flb_get_global(S, "divmod", &out));
  CHECK(out->type == FLB_FUNCTION);
  function = out->i;
  arguments[0] = integer(17);
  arguments[1] = integer(5);
  OK(flb_call(S, function, arguments, 2, 0, &out, &count));
  CHECK(count == 2 && out[0].i == 3 && out[1].i == 2);
  OK(flb_release(S, function));

  /* Globals as a table, and method calls. */
  {
    flb_ref globals = 0;
    flb_value key = string("x");
    OK(flb_globals(S, &globals));
    OK(flb_get(S, globals, &key, 0, &out));
    CHECK(out->i == 10);
    OK(flb_release(S, globals));
  }
  out = eval(S, "return { n = 5, add = function(self, d) return self.n + d end }");
  {
    flb_ref object = out->i;
    flb_value delta = integer(3);
    OK(flb_call_method(S, object, "add", &delta, 1, 0, &out, &count));
    CHECK(count == 1 && out->i == 8);
    OK(flb_release(S, object));
  }
}

static void test_tables(flb_state *S) {
  const flb_value *out = NULL;
  size_t count = 0;
  flb_ref table = 0, sequence = 0, metatable = 0;
  flb_value pairs[4], items[3], key, value;
  int64_t length = 0;
  int32_t flag = 0;

  pairs[0] = string("name");
  pairs[1] = string("lua");
  pairs[2] = integer(1);
  pairs[3] = number(2.5);
  OK(flb_table_new(S, pairs, 2, &table));
  key = string("name");
  OK(flb_get(S, table, &key, 0, &out));
  CHECK(is_string(out, "lua"));
  key = string("extra");
  value = boolean(1);
  OK(flb_set(S, table, &key, &value, 1));
  OK(flb_pairs(S, table, &out, &count));
  CHECK(count == 3);
  {
    size_t i, seen = 0;
    for (i = 0; i < count; i++) {
      const flb_value *k = &out[2 * i], *v = &out[2 * i + 1];
      if (is_string(k, "name")) seen += is_string(v, "lua");
      if (is_string(k, "extra")) seen += v->type == FLB_BOOLEAN && v->i == 1;
      if (k->type == FLB_INTEGER && k->i == 1) seen += v->n == 2.5;
    }
    CHECK(seen == 3);
  }

  /* Incremental traversal visits the same three entries. */
  {
    flb_value current = nil_value();
    size_t visited = 0;
    for (;;) {
      OK(flb_next(S, table, &current, &out, &flag));
      if (!flag) break;
      visited++;
      current = out[0];
      if (current.type == FLB_STRING) {
        /* The key bytes are only valid until the next call: keep a copy. */
        static char copy[32];
        memcpy(copy, current.bytes, current.length);
        current.bytes = copy;
      }
    }
    CHECK(visited == 3);
  }

  items[0] = string("a");
  items[1] = string("b");
  items[2] = string("c");
  OK(flb_sequence_new(S, items, 3, &sequence));
  OK(flb_length(S, sequence, 1, &length));
  CHECK(length == 3);
  OK(flb_sequence(S, sequence, &out, &count));
  CHECK(count == 3 && is_string(&out[0], "a") && is_string(&out[2], "c"));

  /* Metatables and metamethods. */
  out = eval(S, "return { __index = function(_, k) return k .. '!' end,"
                " __len = function() return 99 end }");
  metatable = out->i;
  OK(flb_set_metatable(S, table, metatable));
  key = string("ghost");
  OK(flb_get(S, table, &key, 0, &out));
  CHECK(is_string(out, "ghost!"));
  OK(flb_get(S, table, &key, 1, &out));
  CHECK(out->type == FLB_NIL);
  OK(flb_length(S, table, 0, &length));
  CHECK(length == 99);
  {
    flb_ref found = 0;
    flb_value left = reference(FLB_TABLE, metatable), right;
    OK(flb_get_metatable(S, table, &found));
    CHECK(found != 0 && found != metatable);
    right = reference(FLB_TABLE, found);
    OK(flb_equals(S, &left, &right, &flag));
    CHECK(flag == 1);
    OK(flb_release(S, found));
    OK(flb_get_metatable(S, sequence, &found));
    CHECK(found == 0);
  }
  OK(flb_set_metatable(S, table, 0));
  OK(flb_length(S, table, 0, &length));
  CHECK(length == 1);

  value = reference(FLB_TABLE, sequence);
  OK(flb_tostring(S, &value, &out));
  CHECK(out->type == FLB_STRING && strncmp(out->bytes, "table: ", 7) == 0);

  /* Raw access is only defined for tables. */
  CHECK(flb_get(S, 987654, &key, 0, &out) == FLB_ERROR_ARGUMENT);
  CHECK(message_contains(S, "invalid reference"));

  OK(flb_release(S, table));
  OK(flb_release(S, sequence));
  OK(flb_release(S, metatable));
}

static void test_errors(flb_state *S) {
  const flb_value *out = NULL;
  size_t count = 0, length = 0;
  const char *code = "local x = = 1";
  CHECK(flb_run(S, code, strlen(code), "=bad", &out, &count) == FLB_ERROR_SYNTAX);
  CHECK(out == NULL && count == 0);
  CHECK(message_contains(S, "bad:1:"));

  code = "local function inner() error('boom') end\ninner()";
  CHECK(flb_run(S, code, strlen(code), "=err", &out, &count) == FLB_ERROR_RUNTIME);
  CHECK(message_contains(S, "err:1: boom"));
  CHECK(strstr(flb_error_traceback(S, &length), "stack traceback") != NULL);
  CHECK(length > 0);
  CHECK(flb_error_host_id(S) == 0);

  /* Non-string error objects are described through __tostring. */
  code = "error(setmetatable({}, { __tostring = function() return 'custom' end }))";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_RUNTIME);
  CHECK(message_contains(S, "custom"));

  /* The error state is cleared by the next successful call. */
  CHECK(eval(S, "return 1")->i == 1);
  CHECK(flb_error_message(S, &length)[0] == '\0' && length == 0);
}

static void test_host_functions(flb_state *S) {
  const flb_value *out = NULL;
  size_t count = 0;
  const char *code;

  set_host_function(S, "add", FN_ADD);
  set_host_function(S, "explode", FN_FAIL);
  set_host_function(S, "call_back", FN_CALL_BACK);
  set_host_function(S, "swap", FN_SWAP);

  CHECK(eval(S, "return add(20, 22)")->i == 42);

  code = "return swap('left', 2)";
  OK(flb_run(S, code, strlen(code), NULL, &out, &count));
  CHECK(count == 2 && out[0].i == 2 && is_string(&out[1], "left"));

  /* A host failure that Lua does not handle keeps its identity. */
  code = "explode()";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_HOST);
  CHECK(flb_error_host_id(S) == 4242);
  CHECK(message_contains(S, "host exploded"));

  /* Lua sees an ordinary string error and can rethrow it unchanged. */
  CHECK(is_string(eval(S, "local ok, e = pcall(explode) return type(e)"), "string"));
  out = eval(S, "local ok, e = pcall(explode) return tostring(ok) .. ':' .. tostring(e)");
  CHECK(is_string(out, "false:host exploded"));
  code = "local ok, e = pcall(explode) error(e, 0)";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_HOST);
  CHECK(flb_error_host_id(S) == 4242);

  /* Argument validation done by the host surfaces as an ordinary error. */
  code = "return add('x', 1)";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_HOST);
  CHECK(flb_error_host_id(S) == 0);

  /* Re-entrancy: host -> Lua -> host -> Lua. */
  out = eval(S, "return function(n) return n * 2 end");
  call_back_target = out->i;
  CHECK(eval(S, "return call_back(21, 'kept')")->i == 42);
  OK(flb_release(S, call_back_target));

  /* flb_return and flb_fail are only meaningful inside a host call. */
  CHECK(flb_return(S, NULL, 0) == FLB_ERROR_ARGUMENT);
  CHECK(flb_fail(S, 1, "x", 1) == FLB_ERROR_ARGUMENT);

  /* Collected host functions are reported to the host. */
  {
    int before = released_functions;
    flb_value nil = nil_value();
    OK(flb_set_global(S, "swap", &nil));
    OK(flb_gc(S, FLB_GC_COLLECT));
    OK(flb_gc(S, FLB_GC_COLLECT));
    CHECK(released_functions == before + 1);
  }
}

static void test_by_value(flb_state *S) {
  const flb_value *out = NULL;
  const flb_value *inner;
  flb_value table, pairs[4], nested_pairs[2], argument;
  const char *code;

  /* Lua -> host: a table tree with no references. */
  out = eval(S, "return {name = 'copy', [1] = 1.5, inner = {flag = true, text = 'a\\0b'}}");
  argument = *out;
  OK(flb_copy(S, &argument, &out));
  OK(flb_release(S, argument.i));
  CHECK(out->type == FLB_TABLE_VALUE && out->length == 3);
  CHECK(is_string(field(out, "name"), "copy"));
  inner = field(out, "inner");
  CHECK(inner && inner->type == FLB_TABLE_VALUE && inner->length == 2);
  CHECK(field(inner, "flag")->type == FLB_BOOLEAN && field(inner, "flag")->i == 1);
  CHECK(field(inner, "text")->length == 3);
  /* Scalars pass through unchanged. */
  argument = integer(5);
  OK(flb_copy(S, &argument, &out));
  CHECK(out->type == FLB_INTEGER && out->i == 5);

  /* What cannot be copied is rejected and leaves the state usable. */
  out = eval(S, "local t = {} t.self = t return t");
  argument = *out;
  CHECK(flb_copy(S, &argument, &out) == FLB_ERROR_ARGUMENT);
  CHECK(message_contains(S, "cyclic"));
  OK(flb_release(S, argument.i));
  out = eval(S, "return {f = print}");
  argument = *out;
  CHECK(flb_copy(S, &argument, &out) == FLB_ERROR_ARGUMENT);
  CHECK(message_contains(S, "function"));
  OK(flb_release(S, argument.i));
  out = eval(S, "return {[1.5] = 1}");
  argument = *out;
  CHECK(flb_copy(S, &argument, &out) == FLB_ERROR_ARGUMENT);
  OK(flb_release(S, argument.i));
  /* Metamethods are not consulted. */
  out = eval(S, "return setmetatable({}, {__index = function() error('no') end, "
                "__pairs = function() error('no') end})");
  argument = *out;
  OK(flb_copy(S, &argument, &out));
  CHECK(out->type == FLB_TABLE_VALUE && out->length == 0);
  OK(flb_release(S, argument.i));

  /* Host -> Lua: a table tree becomes a fresh table. */
  nested_pairs[0] = integer(1);
  nested_pairs[1] = string("first");
  pairs[0] = string("count");
  pairs[1] = integer(3);
  pairs[2] = string("items");
  pairs[3] = nil_value();
  pairs[3].type = FLB_TABLE_VALUE;
  pairs[3].items = nested_pairs;
  pairs[3].length = 1;
  table = nil_value();
  table.type = FLB_TABLE_VALUE;
  table.items = pairs;
  table.length = 2;
  OK(flb_set_global(S, "by_value", &table));
  CHECK(is_string(eval(S, "return by_value.count .. by_value.items[1]"), "3first"));

  /* A host function declared by value gets data, not references. */
  set_host_function(S, "sum", FN_BY_VALUE);
  CHECK(eval(S, "return sum({name = 'n', list = {10, 20}}, 7)")->i == 37);
  code = "return sum({name = 'n', list = {print}}, 7)";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_RUNTIME);
  CHECK(message_contains(S, "function"));
  CHECK(is_string(eval(S, "return (select(2, pcall(sum, coroutine.create(print))))"),
                  "a thread cannot be copied by value"));

  /* Calls can hand their results back by value, and call a plain field. */
  out = eval(S, "return {make = function(n) return {n = n, list = {n, n}}, 'x' end, "
                "bad = function() return print end}");
  argument = *out;
  {
    flb_value n = integer(4);
    size_t count = 0;
    OK(flb_call_field(S, argument.i, "make", &n, 1, FLB_CALL_BY_VALUE, &out, &count));
    CHECK(count == 2 && out[0].type == FLB_TABLE_VALUE && is_string(&out[1], "x"));
    CHECK(field(&out[0], "n")->i == 4 && field(&out[0], "list")->length == 2);
    CHECK(flb_call_field(S, argument.i, "bad", NULL, 0, FLB_CALL_BY_VALUE, &out,
                         &count) == FLB_ERROR_RUNTIME);
    CHECK(message_contains(S, "function"));
    CHECK(flb_call_field(S, argument.i, "absent", NULL, 0, 0, &out, &count) ==
          FLB_ERROR_RUNTIME);
  }
  OK(flb_release(S, argument.i));

  /* Modules: what require() returns. */
  OK(flb_set_module(S, "host.data", &table));
  CHECK(eval(S, "return require('host.data').count")->i == 3);
  OK(flb_get_module(S, "host.data", &out));
  CHECK(out->type == FLB_TABLE);
  OK(flb_release(S, out->i));
  argument = nil_value();
  OK(flb_set_module(S, "host.data", &argument));
  OK(flb_get_module(S, "host.data", &out));
  CHECK(out->type == FLB_NIL);
}

static void test_host_objects(flb_state *S) {
  const flb_value *out = NULL;
  flb_ref class_metatable = 0, methods = 0, object = 0, getter = 0;
  flb_value key, value;
  int before = released_objects;

  OK(flb_class_new(S, "Counter", &class_metatable));
  OK(flb_function_new(S, FN_OBJECT_ID, 0, &getter));
  key = string("id");
  value = reference(FLB_FUNCTION, getter);
  OK(flb_table_new(S, NULL, 0, &methods));
  OK(flb_set(S, methods, &key, &value, 1));
  key = string("__index");
  value = reference(FLB_TABLE, methods);
  OK(flb_set(S, class_metatable, &key, &value, 1));

  OK(flb_object_new(S, class_metatable, 777, &object));
  value = reference(FLB_USERDATA, object);
  OK(flb_set_global(S, "counter", &value));

  /* Lua calls a method; the host recovers which object it was. */
  CHECK(eval(S, "return counter:id()")->i == 777);
  out = eval(S, "return counter");
  CHECK(out->type == FLB_USERDATA && out->id == 777);
  OK(flb_release(S, out->i));
  out = eval(S, "return tostring(counter)");
  CHECK(strncmp(out->bytes, "Counter: ", 9) == 0);

  /* Only metatables made by flb_class_new can back host objects. */
  {
    flb_ref rejected = 1;
    CHECK(flb_object_new(S, methods, 1, &rejected) == FLB_ERROR_ARGUMENT);
    CHECK(rejected == 0);
  }

  /* Once unreachable from both sides the object is released to the host. */
  OK(flb_release(S, object));
  value = nil_value();
  OK(flb_set_global(S, "counter", &value));
  OK(flb_gc(S, FLB_GC_COLLECT));
  OK(flb_gc(S, FLB_GC_COLLECT));
  CHECK(released_objects == before + 1 && last_released_object == 777);

  OK(flb_release(S, class_metatable));
  OK(flb_release(S, methods));
  OK(flb_release(S, getter));
}

static void test_chunks(flb_state *S) {
  const flb_value *out = NULL;
  size_t count = 0;
  flb_ref function = 0, binary = 0, environment = 0;
  flb_value pairs[2];
  const char *code = "return (...) + offset";
  char *dumped;
  size_t dumped_length;
  flb_value argument = integer(1);

  /* A chunk with its own environment does not see the globals. */
  pairs[0] = string("offset");
  pairs[1] = integer(100);
  OK(flb_table_new(S, pairs, 1, &environment));
  OK(flb_load(S, code, strlen(code), "=env", FLB_MODE_TEXT, environment, &function));
  OK(flb_call(S, function, &argument, 1, 0, &out, &count));
  CHECK(count == 1 && out->i == 101);

  /* Dump to bytecode and load it back. */
  OK(flb_dump(S, function, 1, &out));
  CHECK(out->type == FLB_STRING && out->length > 4 && out->bytes[0] == 27);
  dumped_length = out->length;
  dumped = malloc(dumped_length);
  CHECK(dumped != NULL);
  memcpy(dumped, out->bytes, dumped_length);
  CHECK(flb_load(S, dumped, dumped_length, "=bin", FLB_MODE_TEXT, 0, &binary) ==
        FLB_ERROR_SYNTAX);
  OK(flb_load(S, dumped, dumped_length, "=bin", FLB_MODE_BINARY, environment, &binary));
  OK(flb_call(S, binary, &argument, 1, 0, &out, &count));
  CHECK(out->i == 101);
  free(dumped);

  {
    flb_ref rejected = 1;
    CHECK(flb_load(S, "x", 1, NULL, 64, 0, &rejected) == FLB_ERROR_ARGUMENT);
    CHECK(rejected == 0);
  }
  OK(flb_release(S, function));
  OK(flb_release(S, binary));
  OK(flb_release(S, environment));
}

static void test_coroutines(flb_state *S) {
  const flb_value *out = NULL;
  size_t count = 0;
  flb_ref body, thread = 0;
  flb_value argument;
  int32_t status = -1;

  out = eval(S, "return function(a)\n"
                "  local b = coroutine.yield(a + 1)\n"
                "  local c = coroutine.yield(b * 2, 'second')\n"
                "  return a + b + c\n"
                "end");
  body = out->i;
  OK(flb_thread_new(S, body, &thread));
  OK(flb_thread_status(S, thread, &status));
  CHECK(status == FLB_THREAD_SUSPENDED);

  argument = integer(1);
  CHECK(flb_resume(S, thread, &argument, 1, &out, &count) == FLB_YIELD);
  CHECK(count == 1 && out->i == 2);
  argument = integer(10);
  CHECK(flb_resume(S, thread, &argument, 1, &out, &count) == FLB_YIELD);
  CHECK(count == 2 && out[0].i == 20 && is_string(&out[1], "second"));
  argument = integer(100);
  OK(flb_resume(S, thread, &argument, 1, &out, &count));
  CHECK(count == 1 && out->i == 111);
  OK(flb_thread_status(S, thread, &status));
  CHECK(status == FLB_THREAD_DEAD);
  CHECK(flb_resume(S, thread, NULL, 0, &out, &count) == FLB_ERROR_ARGUMENT);
  OK(flb_release(S, thread));

  /* An error inside a coroutine is reported with the coroutine's traceback. */
  out = eval(S, "return function() coroutine.yield() error('in coroutine') end");
  OK(flb_release(S, body));
  body = out->i;
  OK(flb_thread_new(S, body, &thread));
  CHECK(flb_resume(S, thread, NULL, 0, NULL, NULL) == FLB_YIELD);
  CHECK(flb_resume(S, thread, NULL, 0, &out, &count) == FLB_ERROR_RUNTIME);
  CHECK(message_contains(S, "in coroutine"));
  CHECK(strstr(flb_error_traceback(S, NULL), "stack traceback") != NULL);
  OK(flb_thread_status(S, thread, &status));
  CHECK(status == FLB_THREAD_DEAD);
  OK(flb_release(S, thread));

  /* Closing a suspended coroutine. */
  OK(flb_thread_new(S, body, &thread));
  CHECK(flb_resume(S, thread, NULL, 0, NULL, NULL) == FLB_YIELD);
  OK(flb_thread_close(S, thread));
  if (flb_lua_version() >= 504) {
    OK(flb_thread_status(S, thread, &status));
    CHECK(status == FLB_THREAD_DEAD);
  }
  OK(flb_release(S, thread));
  OK(flb_release(S, body));

  CHECK(flb_thread_status(S, 987654, &status) == FLB_ERROR_ARGUMENT);
}

/* Runs `code`, a chunk returning a function, as a new coroutine. */
static flb_ref coroutine_of(flb_state *S, const char *code) {
  flb_ref thread = 0;
  const flb_value *body = eval(S, code);
  OK(flb_thread_new(S, body->i, &thread));
  OK(flb_release(S, body->i));
  return thread;
}

static void test_yielding_host_functions(flb_state *S) {
  const flb_value *out = NULL;
  size_t count = 0;
  flb_ref thread;
  flb_value arguments[2];
  const char *code;

  set_host_function(S, "await", FN_AWAIT);
  set_host_function(S, "can_yield", FN_CAN_YIELD);
  set_host_function(S, "call_back", FN_CALL_BACK);

  /* The host function suspends the coroutine with its own values, and the
   * resume arguments become its results. */
  thread = coroutine_of(S, "return function(x)\n"
                           "  local a, b = await('request', x)\n"
                           "  return a .. b\n"
                           "end");
  arguments[0] = integer(7);
  CHECK(flb_resume(S, thread, arguments, 1, &out, &count) == FLB_YIELD);
  CHECK(count == 2 && is_string(&out[0], "request") && out[1].i == 7);
  arguments[0] = string("got ");
  arguments[1] = string("it");
  OK(flb_resume(S, thread, arguments, 2, &out, &count));
  CHECK(count == 1 && is_string(out, "got it"));
  OK(flb_release(S, thread));

  /* It can be suspended inside pcall, as the generated wrappers call it. */
  thread = coroutine_of(S, "return function()\n"
                           "  local ok, v = pcall(await, 'p')\n"
                           "  return tostring(ok) .. ':' .. v\n"
                           "end");
  CHECK(flb_resume(S, thread, NULL, 0, &out, &count) == FLB_YIELD);
  CHECK(count == 1 && is_string(out, "p"));
  arguments[0] = integer(5);
  OK(flb_resume(S, thread, arguments, 1, &out, &count));
  CHECK(is_string(out, "true:5"));
  OK(flb_release(S, thread));

  /* flb_resume_failure makes the host function raise, like flb_fail: with
   * its host id when Lua does not handle it... */
  thread = coroutine_of(S, "return function() return await('q') end");
  CHECK(flb_resume(S, thread, NULL, 0, NULL, NULL) == FLB_YIELD);
  CHECK(flb_resume_failure(S, thread, 777, "remote failed", 13, &out, &count) ==
        FLB_ERROR_HOST);
  CHECK(flb_error_host_id(S) == 777);
  CHECK(message_contains(S, "remote failed"));
  OK(flb_release(S, thread));

  /* ...and as an ordinary string error when it does. */
  thread = coroutine_of(S, "return function()\n"
                           "  local ok, e = pcall(await, 'q')\n"
                           "  return tostring(ok) .. ':' .. e\n"
                           "end");
  CHECK(flb_resume(S, thread, NULL, 0, NULL, NULL) == FLB_YIELD);
  OK(flb_resume_failure(S, thread, 778, "remote failed", 13, &out, &count));
  CHECK(is_string(out, "false:remote failed"));
  OK(flb_release(S, thread));

  /* Outside a coroutine the host function raises instead of yielding. */
  code = "return await('x')";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_RUNTIME);
  CHECK(message_contains(S, "outside a coroutine"));
  CHECK(is_string(eval(S, "return tostring(can_yield())"), "false"));

  /* Nor can a coroutine be suspended across a host function that called back
   * into Lua: that would unwind the host's stack frames. */
  out = eval(S, "return function(n) return can_yield() and 1 or 0 end");
  call_back_target = out->i;
  thread = coroutine_of(S, "return function()\n"
                           "  return (can_yield() and 1 or 0), call_back(0, 'kept')\n"
                           "end");
  OK(flb_resume(S, thread, NULL, 0, &out, &count));
  CHECK(count == 2 && out[0].i == 1 && out[1].i == 0);
  OK(flb_release(S, thread));
  OK(flb_release(S, call_back_target));

  /* A coroutine resumed by Lua passes the values to Lua's resume. */
  out = eval(S, "local co = coroutine.wrap(function() return await('in lua') .. '!' end)\n"
                "local first = co()\n"
                "return first .. '|' .. co('done')");
  CHECK(is_string(out, "in lua|done!"));

  /* flb_resume_failure needs a coroutine suspended in a host function. */
  thread = coroutine_of(S, "return function() coroutine.yield() end");
  CHECK(flb_resume(S, thread, NULL, 0, NULL, NULL) == FLB_YIELD);
  CHECK(flb_resume_failure(S, thread, 1, "x", 1, NULL, NULL) == FLB_ERROR_ARGUMENT);
  CHECK(message_contains(S, "not suspended in a host function"));
  OK(flb_resume(S, thread, NULL, 0, NULL, NULL));
  CHECK(flb_resume_failure(S, thread, 1, "x", 1, NULL, NULL) == FLB_ERROR_ARGUMENT);
  OK(flb_release(S, thread));

  /* flb_yield and flb_can_yield are only meaningful inside a host call. */
  CHECK(flb_yield(S, NULL, 0) == FLB_ERROR_ARGUMENT);
  CHECK(flb_can_yield(S) == 0);
}

static void test_tokens(flb_state *S) {
  const flb_value *out = eval(S, "probe = setmetatable({}, { __mode = 'v' })\n"
                                  "probe[1] = {} return probe[1]");
  void *token = flb_token_new(S, out->i);
  CHECK(token != NULL);
  OK(flb_gc(S, FLB_GC_COLLECT));
  CHECK(eval(S, "return probe[1] ~= nil")->i == 1);
  /* Released as if from a finalizer; applied on the next use of the state. */
  flb_token_release(token);
  OK(flb_gc(S, FLB_GC_COLLECT));
  CHECK(eval(S, "return probe[1] == nil")->i == 1);
}

static void test_sandbox(void) {
  flb_state *S = open(FLB_LIBS_SAFE, 0);
  flb_ref loader = 0, searcher = 0;
  const char *code;

  CHECK(eval(S, "return io == nil and os == nil and debug == nil")->i == 1);
  CHECK(eval(S, "return dofile == nil and loadfile == nil")->i == 1);
  CHECK(eval(S, "return package.loadlib == nil and #package.searchers")->i == 1);
  CHECK(eval(S, "return load('return 7')()")->i == 7);
  CHECK(eval(S, "local f = load(string.dump(function() end)) return f == nil")->i == 1);
  CHECK(eval(S, "local f = load(string.dump(function() end), 'x', 'b') return f == nil")->i == 1);

  code = "return require('nowhere')";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_RUNTIME);

  OK(flb_function_new(S, FN_LOADER, 0, &loader));
  OK(flb_preload(S, "host.module", loader));
  /* Parenthesised: from Lua 5.4 on `require` also returns the loader data. */
  CHECK(is_string(eval(S, "return (require('host.module'))"), "module value"));

  OK(flb_function_new(S, FN_SEARCHER, 0, &searcher));
  OK(flb_add_searcher(S, searcher));
  CHECK(is_string(eval(S, "return (require('dynamic'))"), "module value"));
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_RUNTIME);
  CHECK(message_contains(S, "no host module"));

  OK(flb_release(S, loader));
  OK(flb_release(S, searcher));
  flb_state_release(S);

  /* The full library set keeps the unrestricted functions. */
  S = open(FLB_LIBS_ALL, 0);
  CHECK(eval(S, "return io ~= nil and os ~= nil and dofile ~= nil")->i == 1);
  CHECK(eval(S, "return type(package.loadlib) == 'function' and #package.searchers > 1")->i == 1);
  flb_state_release(S);

  /* Without the require library there is nothing to preload into. */
  S = open(FLB_LIB_BASE, 0);
  OK(flb_function_new(S, FN_LOADER, 0, &loader));
  CHECK(flb_preload(S, "m", loader) == FLB_ERROR_ARGUMENT);
  flb_state_release(S);
}

static void test_memory_limit(void) {
  flb_state *S = open(FLB_LIBS_SAFE, 0);
  size_t baseline = flb_memory_used(S);
  const char *code = "local t = {} for i = 1, 1e7 do t[i] = tostring(i) end";
  CHECK(baseline > 0);
  flb_set_memory_limit(S, baseline + 256 * 1024);
  CHECK(flb_memory_limit(S) == baseline + 256 * 1024);
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_MEMORY);
  /* The state is still usable afterwards. */
  OK(flb_gc(S, FLB_GC_COLLECT));
  CHECK(eval(S, "return 1 + 1")->i == 2);
  CHECK(flb_memory_used(S) < baseline + 256 * 1024);
  flb_state_release(S);
}

static void test_interrupt(void) {
  flb_state *S = open(FLB_LIBS_SAFE, 0);
  const char *code = "interrupt() while true do end";
  set_host_function(S, "interrupt", FN_INTERRUPT);
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_INTERRUPTED);
  CHECK(message_contains(S, "interrupted"));

  /* Lua code cannot swallow the interruption with pcall. */
  code = "interrupt()\n"
         "while true do pcall(function() while true do end end) end";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_INTERRUPTED);

  /* Nor inside a coroutine. */
  code = "interrupt()\n"
         "local co = coroutine.wrap(function() while true do end end)\n"
         "while true do pcall(co) end";
  CHECK(flb_run(S, code, strlen(code), NULL, NULL, NULL) == FLB_ERROR_INTERRUPTED);

  /* The interruption is consumed: the state runs normally again. */
  CHECK(eval(S, "local n = 0 for i = 1, 100000 do n = n + i end return n")->i ==
        5000050000LL);
  flb_state_release(S);
}

static void test_lifecycle(void) {
  flb_state *S = open(FLB_LIBS_SAFE, 0);
  const flb_value *out = eval(S, "return {}");
  void *token = flb_token_new(S, out->i);
  int before = released_functions;
  int32_t type = 0;

  set_host_function(S, "add", FN_ADD);
  CHECK(!flb_is_closed(S));
  flb_close(S);
  CHECK(flb_is_closed(S));
  CHECK(released_functions == before + 1);
  flb_close(S);

  CHECK(flb_run(S, "return 1", 8, NULL, NULL, NULL) == FLB_ERROR_CLOSED);
  CHECK(flb_ref_type(S, 1, &type) == FLB_ERROR_CLOSED);
  CHECK(flb_gc(S, FLB_GC_COLLECT) == FLB_ERROR_CLOSED);

  /* A token may outlive both the VM and the owner's hold on the state. */
  flb_state_release(S);
  flb_token_release(token);

  /* Releasing without closing first does not call back into the host. */
  S = open(FLB_LIBS_SAFE, 0);
  set_host_function(S, "add", FN_ADD);
  before = released_functions;
  flb_state_release(S);
  CHECK(released_functions == before);

  /* Default options. */
  S = flb_open(NULL);
  CHECK(S != NULL);
  CHECK(eval(S, "return math.type(1)")->type == FLB_STRING);
  flb_state_release(S);
}

int main(void) {
  flb_state *S;
  test_library();
  S = open(FLB_LIBS_SAFE, 0);
  test_values(S);
  test_globals_and_calls(S);
  test_tables(S);
  test_errors(S);
  test_host_functions(S);
  test_by_value(S);
  test_host_objects(S);
  test_chunks(S);
  test_coroutines(S);
  test_yielding_host_functions(S);
  test_tokens(S);
  flb_state_release(S);
  test_sandbox();
  test_memory_limit();
  test_interrupt();
  test_lifecycle();
  printf("flb tests passed on %s (%d checks)\n", flb_lua_release(), checks);
  return 0;
}
