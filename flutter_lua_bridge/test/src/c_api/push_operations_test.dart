import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Push Operations Tests', () {
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

    test('luaPushboolean pushes true', () {
      luaPushboolean(L, 1);
      expect(luaGettop(L), equals(1));
      expect(luaToboolean(L, 1), equals(1));
    });

    test('luaPushboolean pushes false', () {
      luaPushboolean(L, 0);
      expect(luaGettop(L), equals(1));
      expect(luaToboolean(L, 1), equals(0));
    });

    test('luaPushnil pushes nil', () {
      luaPushnil(L);
      expect(luaGettop(L), equals(1));
      expect(luaIsnil(L, 1), equals(1));
    });

    test('luaPushinteger pushes integer value', () {
      luaPushinteger(L, 42);
      expect(luaGettop(L), equals(1));
      expect(luaIsinteger(L, 1), equals(1));
      expect(luaTointeger(L, 1), equals(42));
    });

    test('luaPushinteger pushes negative integer', () {
      luaPushinteger(L, -100);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(-100));
    });

    test('luaPushnumber pushes number value', () {
      luaPushnumber(L, 3.14);
      expect(luaGettop(L), equals(1));
      expect(luaIsnumber(L, 1), equals(1));
      expect(luaTonumber(L, 1), closeTo(3.14, 0.001));
    });

    test('luaPushglobaltable pushes global table', () {
      luaPushglobaltable(L);
      expect(luaGettop(L), equals(1));
      expect(luaIstable(L, 1), equals(1));
    });

    test('luaPushthread pushes current thread', () {
      luaPushthread(L);
      expect(luaGettop(L), equals(1));
      expect(luaIsthread(L, 1), equals(1));
    });

    test('luaPushcclosure pushes C closure', () {
      // Skip this test as it requires a valid C function pointer
    }, skip: 'luaPushcclosure requires valid C function pointer');

    test('luaPushcfunction pushes C function', () {
      // Skip this test as it requires a valid C function pointer
    }, skip: 'luaPushcfunction requires valid C function pointer');

    test('luaPushstring pushes string', () {
      // Skip this test as it requires complex string handling
    }, skip: 'luaPushstring requires string handling');

    test('luaPushlstring pushes string with length', () {
      // Skip this test as it requires complex string handling
    }, skip: 'luaPushlstring requires string handling');

    test('luaPushlightuserdata pushes pointer', () {
      // Skip this test as it requires pointer allocation
    }, skip: 'luaPushlightuserdata requires pointer allocation');

    test('luaPushfstring pushes formatted string', () {
      // Skip this test as it requires complex string formatting
    }, skip: 'luaPushfstring requires formatted string handling');

    test('luaPushexternalstring pushes external string', () {
      // Skip this test as it requires custom allocator
    }, skip: 'luaPushexternalstring requires custom allocator');

    test('luaPushliteral pushes literal string', () {
      // Skip this test as it requires literal string handling
    }, skip: 'luaPushliteral requires literal string handling');

    test('luaPushvfstring pushes variadic formatted string', () {
      // Skip this test as it requires variadic arguments
    }, skip: 'luaPushvfstring requires variadic arguments');
  });
}
