import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Misc Operations Tests', () {
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

    test('luaArith performs addition', () {
      luaPushinteger(L, 10);
      luaPushinteger(L, 5);
      luaArith(L, LuaArith.add);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(15));
    });

    test('luaArith performs subtraction', () {
      luaPushinteger(L, 10);
      luaPushinteger(L, 5);
      luaArith(L, LuaArith.sub);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(5));
    });

    test('luaArith performs multiplication', () {
      luaPushinteger(L, 6);
      luaPushinteger(L, 7);
      luaArith(L, LuaArith.mul);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(42));
    });

    test('luaArith performs division', () {
      luaPushinteger(L, 20);
      luaPushinteger(L, 4);
      luaArith(L, LuaArith.div);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(5));
    });

    test('luaArith performs modulo', () {
      luaPushinteger(L, 10);
      luaPushinteger(L, 3);
      luaArith(L, LuaArith.mod);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(1));
    });

    test('luaArith performs power', () {
      luaPushinteger(L, 2);
      luaPushinteger(L, 3);
      luaArith(L, LuaArith.pow);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(8));
    });

    test('luaArith performs unary minus', () {
      luaPushinteger(L, 5);
      luaArith(L, LuaArith.unm);
      expect(luaGettop(L), equals(1));
      expect(luaTointeger(L, 1), equals(-5));
    });

    test('luaCompare performs equal comparison', () {
      luaPushinteger(L, 5);
      luaPushinteger(L, 5);
      int result = luaCompare(L, 1, 2, LuaCompare.eq);
      expect(result, equals(1));
    });

    test('luaCompare performs less than comparison', () {
      luaPushinteger(L, 3);
      luaPushinteger(L, 5);
      int result = luaCompare(L, 1, 2, LuaCompare.lt);
      expect(result, equals(1));
    });

    test('luaCompare performs less than or equal comparison', () {
      luaPushinteger(L, 5);
      luaPushinteger(L, 5);
      int result = luaCompare(L, 1, 2, LuaCompare.le);
      expect(result, equals(1));
    });

    test('luaConcat concatenates values', () {
      // Skip this test as it requires string handling
    }, skip: 'luaConcat requires string handling');

    test('luaCopy copies value', () {
      luaPushinteger(L, 42);
      luaPushnil(L);
      luaCopy(L, 1, 2);

      expect(luaGettop(L), equals(2));
      expect(luaTointeger(L, 1), equals(42));
      expect(luaIsnil(L, 2), equals(1));
    });

    test('luaNewtable creates new table', () {
      luaNewtable(L);
      expect(luaGettop(L), equals(1));
      expect(luaIstable(L, 1), equals(1));
    });

    test('luaCreatetable creates table with pre-allocated size', () {
      luaCreatetable(L, 10, 5);
      expect(luaGettop(L), equals(1));
      expect(luaIstable(L, 1), equals(1));
    });

    test('luaLen returns length', () {
      luaNewtable(L);
      luaPushinteger(L, 1);
      luaRawseti(L, -2, 1);
      luaPushinteger(L, 2);
      luaRawseti(L, -2, 2);
      luaPushinteger(L, 3);
      luaRawseti(L, -2, 3);

      luaLen(L, 1);
      expect(luaTointeger(L, -1), equals(3));
    });

    test('luaLoad loads code', () {
      // Skip this test as it requires reader function
    }, skip: 'luaLoad requires reader function');

    test('luaDump dumps function', () {
      // Skip this test as it requires writer function
    }, skip: 'luaDump requires writer function');

    test('luaNumbertocstring converts number to string', () {
      // Skip this test as it requires string handling
    }, skip: 'luaNumbertocstring requires string handling');

    test('luaNumbertointeger converts number to integer', () {
      // Skip this test as it requires pointer output
    }, skip: 'luaNumbertointeger requires pointer output');

    test('luaRawequal compares values without metamethods', () {
      luaPushinteger(L, 42);
      luaPushinteger(L, 42);
      int result = luaRawequal(L, 1, 2);
      expect(result, equals(1));

      luaPushinteger(L, 42);
      luaPushinteger(L, 43);
      result = luaRawequal(L, 1, 2);
      expect(result, equals(0));
    });

    test('luaRegister registers function', () {
      // Skip this test as it requires C function
    }, skip: 'luaRegister requires C function');

    test('luaResetthread resets thread', () {
      // Skip this test as it requires coroutine setup
    }, skip: 'luaResetthread requires coroutine setup');

    test('luaSetwarnf sets warning function', () {
      // Skip this test as it requires warning function
    }, skip: 'luaSetwarnf requires warning function');

    test('luaStringtonumber converts string to number', () {
      // Skip this test as it requires string handling
    }, skip: 'luaStringtonumber requires string handling');

    test('luaToclose marks slot as to-be-closed', () {
      // Skip this test as it requires to-be-closed variable setup
    }, skip: 'luaToclose requires to-be-closed variable setup');

    test('luaWarning issues warning', () {
      // Skip this test as it requires warning handling
    }, skip: 'luaWarning requires warning handling');
  });
}
