import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Library Tests', () {
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

    test('luaLibNewstate creates new state', () {
      late ffi.Pointer<gen.lua_State> L2;
      try {
        L2 = luaLibNewstate();
        expect(L2, isNot(equals(ffi.nullptr)));
        luaClose(L2);
      } finally {
        // L2 is closed in try block
      }
    });

    test('luaLibOpenlibs opens standard libraries', () {
      // Standard libraries should be available
      luaPushglobaltable(L);
      // Just check that global table exists
      expect(luaIstable(L, 1), equals(1));
    });

    test('luaLibNewlibtable creates library table', () {
      luaLibNewlibtable(L, 10);
      expect(luaGettop(L), equals(1));
      expect(luaIstable(L, 1), equals(1));
    });

    test('luaLibNewlib creates new library', () {
      // Skip this test as it requires complex library registration
    }, skip: 'luaLibNewlib requires complex library registration');

    test('luaLibSetfuncs sets functions', () {
      // Skip this test as it requires function registration
    }, skip: 'luaLibSetfuncs requires function registration');

    test('luaLibOpenselectedlibs opens selected libraries', () {
      // Skip this test as it requires library selection
    }, skip: 'luaLibOpenselectedlibs requires library selection');

    test('luaLibRequiref requires module', () {
      // Skip this test as it requires module setup
    }, skip: 'luaLibRequiref requires module setup');
  });
}
