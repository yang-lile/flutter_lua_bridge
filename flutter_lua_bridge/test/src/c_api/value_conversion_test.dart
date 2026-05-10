import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Value Conversion Tests', () {
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

    test('luaToboolean converts to boolean', () {
      luaPushboolean(L, 1);
      expect(luaToboolean(L, 1), equals(1));
      luaPushboolean(L, 0);
      expect(luaToboolean(L, 2), equals(0));
      luaPushnil(L);
      expect(luaToboolean(L, 3), equals(0));
    });

    test('luaTointeger converts to integer', () {
      luaPushinteger(L, 42);
      expect(luaTointeger(L, 1), equals(42));
      luaPushnumber(L, 3.14);
      expect(luaTointeger(L, 2), equals(3));
    });

    test('luaTonumber converts to number', () {
      luaPushnumber(L, 3.14);
      expect(luaTonumber(L, 1), closeTo(3.14, 0.001));
      luaPushinteger(L, 42);
      expect(luaTonumber(L, 2), equals(42.0));
    });

    test('luaType returns type', () {
      luaPushnil(L);
      expect(luaType(L, 1), equals(LuaType.nil.value));
      luaPushboolean(L, 1);
      expect(luaType(L, 2), equals(LuaType.boolean.value));
      luaPushnumber(L, 3.14);
      expect(luaType(L, 3), equals(LuaType.number.value));
      luaNewtable(L);
      expect(luaType(L, 4), equals(LuaType.table.value));
    });

    test('luaTothread converts to thread', () {
      luaPushthread(L);
      final thread = luaTothread(L, 1);
      expect(thread, isNot(equals(ffi.nullptr)));
    });

    test('luaTointegerx converts to integer with status', () {
      // Skip this test as it requires pointer allocation
    }, skip: 'luaTointegerx requires pointer allocation');

    test('luaTonumberx converts to number with status', () {
      // Skip this test as it requires pointer allocation
    }, skip: 'luaTonumberx requires pointer allocation');

    test('luaTocfunction converts to C function', () {
      // Skip this test as it requires C function
    }, skip: 'luaTocfunction requires C function');

    test('luaTolstring converts to string', () {
      // Skip this test as it requires string handling
    }, skip: 'luaTolstring requires string handling');

    test('luaTostring converts to string', () {
      // Skip this test as it requires string handling
    }, skip: 'luaTostring requires string handling');

    test('luaTouserdata converts to userdata', () {
      // Skip this test as it requires userdata handling
    }, skip: 'luaTouserdata requires userdata handling');

    test('luaTopointer converts to pointer', () {
      // Skip this test as it requires pointer handling
    }, skip: 'luaTopointer requires pointer handling');

    test('luaTypename returns type name', () {
      // Skip this test as it requires string handling
    }, skip: 'luaTypename requires string handling');
  });
}
