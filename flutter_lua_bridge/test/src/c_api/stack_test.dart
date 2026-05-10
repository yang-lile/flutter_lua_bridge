import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Stack Operations Tests', () {
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

    test('luaAbsindex converts pseudo-index to absolute index', () {
      luaPushinteger(L, 42);
      int absIdx = luaAbsindex(L, -1);
      expect(absIdx, equals(1));
    });

    test('luaAbsindex converts positive index correctly', () {
      luaPushinteger(L, 42);
      int absIdx = luaAbsindex(L, 1);
      expect(absIdx, equals(1));
    });

    test('luaGettop returns stack top index', () {
      expect(luaGettop(L), equals(0));
      luaPushnil(L);
      expect(luaGettop(L), equals(1));
      luaPushinteger(L, 42);
      expect(luaGettop(L), equals(2));
    });

    test('luaSettop sets stack top index', () {
      luaPushnil(L);
      luaPushnil(L);
      expect(luaGettop(L), equals(2));
      luaSettop(L, 0);
      expect(luaGettop(L), equals(0));
    });

    test('luaSettop with positive index adds nils', () {
      luaPushnil(L);
      expect(luaGettop(L), equals(1));
      luaSettop(L, 3);
      expect(luaGettop(L), equals(3));
      expect(luaIsnil(L, 2), equals(1));
      expect(luaIsnil(L, 3), equals(1));
    });

    test('luaPushvalue pushes a copy of value at index', () {
      luaPushinteger(L, 42);
      luaPushvalue(L, -1);
      expect(luaGettop(L), equals(2));
      expect(luaTointeger(L, 1), equals(42));
      expect(luaTointeger(L, 2), equals(42));
    });

    test('luaRemove removes element at index', () {
      luaPushinteger(L, 1);
      luaPushinteger(L, 2);
      luaPushinteger(L, 3);
      expect(luaGettop(L), equals(3));
      luaRemove(L, 2);
      expect(luaGettop(L), equals(2));
      expect(luaTointeger(L, 1), equals(1));
      expect(luaTointeger(L, 2), equals(3));
    });

    test('luaInsert inserts element at position', () {
      luaPushinteger(L, 1);
      luaPushinteger(L, 2);
      luaPushinteger(L, 3);
      luaInsert(L, 2);
      expect(luaGettop(L), equals(3));
      expect(luaTointeger(L, 1), equals(1));
      expect(luaTointeger(L, 2), equals(3));
      expect(luaTointeger(L, 3), equals(2));
    });

    test('luaReplace replaces element at index', () {
      luaPushinteger(L, 1);
      luaPushinteger(L, 2);
      luaPushinteger(L, 3);
      luaReplace(L, 1);
      expect(luaGettop(L), equals(2));
      expect(luaTointeger(L, 1), equals(3));
      expect(luaTointeger(L, 2), equals(2));
    });

    test('luaRotate rotates stack elements', () {
      luaPushinteger(L, 1);
      luaPushinteger(L, 2);
      luaPushinteger(L, 3);
      luaRotate(L, 1, 1);
      expect(luaGettop(L), equals(3));
      expect(luaTointeger(L, 1), equals(3));
      expect(luaTointeger(L, 2), equals(1));
      expect(luaTointeger(L, 3), equals(2));
    });

    test('luaPop pops n elements from stack', () {
      luaPushnil(L);
      luaPushnil(L);
      luaPushnil(L);
      expect(luaGettop(L), equals(3));
      luaPop(L, 2);
      expect(luaGettop(L), equals(1));
    });

    test('luaXmove moves values between states', () {
      late ffi.Pointer<gen.lua_State> L2;
      try {
        L2 = luaLibNewstate();
        luaPushinteger(L, 42);
        luaPushinteger(L, 100);
        expect(luaGettop(L), equals(2));
        expect(luaGettop(L2), equals(0));
        luaXmove(L, L2, 1);
        expect(luaGettop(L), equals(1));
        expect(luaGettop(L2), equals(1));
        expect(luaTointeger(L2, 1), equals(42));
      } finally {
        if (L2 != ffi.nullptr) {
          luaClose(L2);
        }
      }
    });
  });
}
