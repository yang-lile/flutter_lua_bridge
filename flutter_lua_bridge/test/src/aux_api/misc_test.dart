import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Misc Tests', () {
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

    test('luaLibMakeseed generates seed', () {
      int seed = luaLibMakeseed(L);
      expect(seed, greaterThan(0));
    });

    test('luaLibPushfail pushes fail value', () {
      luaLibPushfail(L);
      expect(luaGettop(L), equals(1));
    });

    test('luaLibRef creates reference', () {
      // Push a value onto the stack
      luaPushinteger(L, 42);
      
      // Create a reference to the value at the top of the stack
      // luaL_ref pops the value and stores it in the registry
      int ref = luaLibRef(L, kLuaRegistryIndex);
      expect(ref, greaterThan(0));
    });

    test('luaLibUnref releases reference', () {
      // Push a value onto the stack
      luaPushinteger(L, 42);
      
      // Create a reference to the value at the top of the stack
      int ref = luaLibRef(L, kLuaRegistryIndex);
      expect(ref, greaterThan(0));
      
      // Release the reference
      luaLibUnref(L, kLuaRegistryIndex, ref);
    });

    test('luaLibTestudata tests userdata', () {
      // Skip this test as it requires userdata handling
    }, skip: 'luaLibTestudata requires userdata handling');

    test('luaLibAlloc allocates memory', () {
      // Skip this test as it requires complex allocator handling
    }, skip: 'luaLibAlloc requires complex allocator handling');
  });
}
