import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Type Conversion Tests', () {
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

    test('luaLibLen returns length', () {
      luaNewtable(L);
      luaPushinteger(L, 1);
      luaRawseti(L, -2, 1);
      luaPushinteger(L, 2);
      luaRawseti(L, -2, 2);
      luaPushinteger(L, 3);
      luaRawseti(L, -2, 3);

      int len = luaLibLen(L, 1);
      expect(len, equals(3));
    });

    test('luaLibTolstring converts to string', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibTolstring requires string handling');

    test('luaLibTypename returns type name', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibTypename requires string handling');
  });
}
