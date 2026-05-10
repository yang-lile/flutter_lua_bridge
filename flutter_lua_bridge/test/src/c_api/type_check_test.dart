import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Type Check Tests', () {
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

    test('luaIsnil checks for nil', () {
      luaPushnil(L);
      expect(luaIsnil(L, 1), equals(1));
      expect(luaIsnil(L, 2), equals(0));
    });

    test('luaIsboolean checks for boolean', () {
      luaPushboolean(L, 1);
      expect(luaIsboolean(L, 1), equals(1));
      luaPushinteger(L, 42);
      expect(luaIsboolean(L, 2), equals(0));
    });

    test('luaIsnumber checks for number', () {
      luaPushnumber(L, 3.14);
      expect(luaIsnumber(L, 1), equals(1));
      luaPushboolean(L, 1);
      expect(luaIsnumber(L, 2), equals(0));
    });

    test('luaIsinteger checks for integer', () {
      luaPushinteger(L, 42);
      expect(luaIsinteger(L, 1), equals(1));
      luaPushnumber(L, 3.14);
      expect(luaIsinteger(L, 2), equals(0));
    });

    test('luaIsstring checks for string', () {
      // Skip this test as it requires string handling
    }, skip: 'luaIsstring requires string handling');

    test('luaIstable checks for table', () {
      luaNewtable(L);
      expect(luaIstable(L, 1), equals(1));
      luaPushinteger(L, 42);
      expect(luaIstable(L, 2), equals(0));
    });

    test('luaIsfunction checks for function', () {
      // Skip this test as it requires function handling
    }, skip: 'luaIsfunction requires function handling');

    test('luaIscfunction checks for C function', () {
      // Skip this test as it requires C function handling
    }, skip: 'luaIscfunction requires C function handling');

    test('luaIsuserdata checks for userdata', () {
      // Skip this test as it requires userdata handling
    }, skip: 'luaIsuserdata requires userdata handling');

    test('luaIslightuserdata checks for light userdata', () {
      // Skip this test as it requires pointer handling
    }, skip: 'luaIslightuserdata requires pointer handling');

    test('luaIsthread checks for thread', () {
      luaPushthread(L);
      expect(luaIsthread(L, 1), equals(1));
      luaPushinteger(L, 42);
      expect(luaIsthread(L, 2), equals(0));
    });

    test('luaIsnone checks for invalid index', () {
      expect(luaIsnone(L, 1), equals(1));
      luaPushinteger(L, 42);
      expect(luaIsnone(L, 1), equals(0));
    });

    test('luaIsnoneornil checks for invalid or nil index', () {
      expect(luaIsnoneornil(L, 1), equals(1));
      luaPushnil(L);
      expect(luaIsnoneornil(L, 1), equals(1));
      luaPushinteger(L, 42);
      expect(luaIsnoneornil(L, 1), equals(0));
    });

    test('luaIsyieldable checks if yieldable', () {
      // Skip this test as it requires coroutine context
    }, skip: 'luaIsyieldable requires coroutine context');
  });
}
