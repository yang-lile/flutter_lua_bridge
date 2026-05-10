import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Memory Management Tests', () {
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

    test('luaNewuserdata creates userdata', () {
      final ud = luaNewuserdata(L, 16);
      expect(ud, isNot(equals(ffi.nullptr)));
      expect(luaGettop(L), equals(1));
      expect(luaType(L, 1), equals(LuaType.userdata.value));
    });

    test('luaNewuserdatauv creates userdata with values', () {
      final ud = luaNewuserdatauv(L, 16, 2);
      expect(ud, isNot(equals(ffi.nullptr)));
      expect(luaGettop(L), equals(1));
      expect(luaType(L, 1), equals(LuaType.userdata.value));
    });

    test('luaGetuservalue gets user value', () {
      final ud = luaNewuserdatauv(L, 16, 1);
      luaPushinteger(L, 42);
      luaSetuservalue(L, 1);

      luaGetuservalue(L, 1);
      expect(luaTointeger(L, -1), equals(42));
    });

    test('luaSetuservalue sets user value', () {
      final ud = luaNewuserdatauv(L, 16, 1);
      luaPushinteger(L, 100);
      luaSetuservalue(L, 1);

      luaGetuservalue(L, 1);
      expect(luaTointeger(L, -1), equals(100));
    });

    test('luaGetiuservalue gets user value by index', () {
      final ud = luaNewuserdatauv(L, 16, 2);
      luaPushinteger(L, 42);
      luaSetiuservalue(L, 1, 1);
      luaPushinteger(L, 99);
      luaSetiuservalue(L, 1, 2);

      luaGetiuservalue(L, 1, 1);
      expect(luaTointeger(L, -1), equals(42));
      luaPop(L, 1);
      luaGetiuservalue(L, 1, 2);
      expect(luaTointeger(L, -1), equals(99));
    });

    test('luaSetiuservalue sets user value by index', () {
      final ud = luaNewuserdatauv(L, 16, 1);
      luaPushinteger(L, 123);
      luaSetiuservalue(L, 1, 1);

      luaGetiuservalue(L, 1, 1);
      expect(luaTointeger(L, -1), equals(123));
    });

    test('luaGetextraspace returns extra space', () {
      final space = luaGetextraspace(L);
      expect(space, isNot(equals(ffi.nullptr)));
    });

    test('luaClosethread closes thread', () {
      // Skip this test as it requires coroutine setup
    }, skip: 'luaClosethread requires coroutine setup');

    test('luaGetallocf gets allocator function', () {
      // Skip this test as it requires complex allocator handling
    }, skip: 'luaGetallocf requires complex allocator handling');

    test('luaSetallocf sets allocator function', () {
      // Skip this test as it requires complex allocator handling
    }, skip: 'luaSetallocf requires complex allocator handling');
  });
}
