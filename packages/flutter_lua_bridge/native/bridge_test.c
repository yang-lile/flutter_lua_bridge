#include "bridge.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int callback_count;
static flb_result *callback(int64_t id, const flb_value *arguments) {
  assert(id == 1 && arguments->kind == 5 && arguments->length == 1);
  flb_result *result = flb_result_new();
  assert(result);
  callback_count++;
  if (arguments->children[1].integer < 0) {
    flb_value *error = flb_value_new(4, 11);
    assert(error);
    memcpy(error->bytes, "host failed", 11);
    flb_value_move(&result->value, error);
    result->failed = 1;
  } else {
    result->value.kind = 2;
    result->value.integer = arguments->children[1].integer + 1;
  }
  return result;
}
static void ok(flb_result *result) {
  assert(result);
  if (result->failed) fprintf(stderr, "%.*s\n", (int)result->value.length, result->value.bytes);
  assert(!result->failed);
  flb_result_free(result);
}
static void failed(flb_result *result) {
  assert(result && result->failed);
  flb_result_free(result);
}
static flb_value *array(void) {
  flb_value *value = flb_value_new(5, 1);
  assert(value);
  value->children[0].kind = 2; value->children[0].integer = 1;
  value->children[1].kind = 2; value->children[1].integer = 41;
  return value;
}
int main(void) {
  flb_runtime *runtime = flb_create(callback, 1);
  assert(runtime);
  flb_value *methods = flb_value_new(5, 1);
  assert(methods);
  flb_value *name = flb_value_new(4, 4);
  assert(name);
  memcpy(name->bytes, "echo", 4);
  flb_value_move(&methods->children[0], name);
  methods->children[1].kind = 2; methods->children[1].integer = 1;
  ok(flb_register(runtime, "host", "test", methods));
  flb_value_free(methods);
  const char *source =
    "local host = require('host'); return { __flb_contract = 'test', "
    "echo = function(value) return host.echo(value) end, "
    "loop = function(value) for i=1,10000 do host.echo(value) end; return value end, "
    "caught = function(value) for i=1,1000 do pcall(host.echo, -1) end; return value end, "
    "bad = function(value) for i=1,1000 do pcall(host.echo, function() end) end; return value end, "
    "cycle = function(value) local x={}; x.self=x; return x end, "
    "unsupported = function(value) return function() end end }";
  ok(flb_load(runtime, "test", source, strlen(source)));
  flb_value *args = array();
  for (int i = 0; i < 1000; i++) {
    flb_result *result = flb_call(runtime, "test", "test", "echo", args, 0);
    assert(result && !result->failed && result->value.integer == 42);
    flb_result_free(result);
  }
  ok(flb_call(runtime, "test", "test", "loop", args, 0));
  ok(flb_call(runtime, "test", "test", "caught", args, 0));
  ok(flb_call(runtime, "test", "test", "bad", args, 0));
  assert(callback_count == 12000);
  for (int i = 0; i < 100; i++) {
    failed(flb_call(runtime, "test", "test", "cycle", args, 0));
    failed(flb_call(runtime, "test", "test", "unsupported", args, 0));
    failed(flb_call(runtime, "test", "wrong", "echo", args, 0));
  }
  args->children[1].integer = -1;
  failed(flb_call(runtime, "test", "test", "echo", args, 0));
  flb_value_free(args);
  flb_close(runtime);
  puts("native bridge tests passed");
  return 0;
}
