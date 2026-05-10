import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Function Calls Tests', () {
    late ffi.Pointer<gen.lua_State> L;

    setUp(() {
      L = luaLibNewstate();
      luaLibOpenlibs(L);
    });

    tearDown(() {
      if (L != ffi.nullptr) {
        luaClose(L);
      }
    });

    test('luaCall calls function', () {
      // Skip this test as it requires Lua function setup
    }, skip: 'luaCall requires Lua function setup');

    test('luaCallk calls function with yield support', () {
      // Skip this test as it requires Lua function setup
    }, skip: 'luaCallk requires Lua function setup');

    test('luaPcall calls function with error handling', () {
      // Skip this test as it requires Lua function setup
    }, skip: 'luaPcall requires Lua function setup');

    test('luaPcallk calls function with error handling and yield support', () {
      // Skip this test as it requires Lua function setup
    }, skip: 'luaPcallk requires Lua function setup');

    test('luaResume resumes coroutine', () {
      // Skip this test as it requires coroutine setup
    }, skip: 'luaResume requires coroutine setup');

    test('luaYield yields from coroutine', () {
      // Skip this test as it requires coroutine context
    }, skip: 'luaYield requires coroutine context');

    test('luaYieldk yields from coroutine with continuation', () {
      // Skip this test as it requires coroutine context
    }, skip: 'luaYieldk requires coroutine context');
  });
}
