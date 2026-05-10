import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('State Management Tests', () {
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

    test('luaNewstate creates new Lua state', () {
      late ffi.Pointer<gen.lua_State> L2;
      try {
        L2 = luaLibNewstate();
        expect(L2, isNot(equals(ffi.nullptr)));
        luaClose(L2);
      } finally {
        // L2 is closed in try block
      }
    });

    test('luaClose closes Lua state', () {
      late ffi.Pointer<gen.lua_State> L2;
      try {
        L2 = luaLibNewstate();
        expect(L2, isNot(equals(ffi.nullptr)));
        luaClose(L2);
        // After close, the state should no longer be valid
        // We can't really test this without causing a crash
      } finally {
        // L2 is closed in try block
      }
    });

    test('luaStatus returns status', () {
      int status = luaStatus(L);
      expect(status, equals(LuaStatus.ok.value));
    });

    test('luaVersion returns version', () {
      double version = luaVersion(L);
      expect(version, greaterThan(500)); // Lua 5.x
    });

    test('luaCheckstack checks stack space', () {
      int result = luaCheckstack(L, 100);
      expect(result, equals(1)); // Should have enough space
    });

    test('luaNewthread creates new thread', () {
      luaNewthread(L);
      expect(luaGettop(L), equals(1));
      expect(luaIsthread(L, 1), equals(1));
    });

    test('luaError throws error', () {
      // Skip this test as it will cause a longjmp
    }, skip: 'luaError causes longjmp which is not testable');
  });
}
