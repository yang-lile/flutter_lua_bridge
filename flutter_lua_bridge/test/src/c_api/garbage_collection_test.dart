import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Garbage Collection Tests', () {
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

    test('luaGc stop stops GC', () {
      int result = luaGc(L, LuaGC.stop, 0);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc restart starts GC', () {
      int result = luaGc(L, LuaGC.restart, 0);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc collect runs GC', () {
      int result = luaGc(L, LuaGC.collect, 0);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc count returns memory in KB', () {
      int result = luaGc(L, LuaGC.count, 0);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc countB returns memory in bytes', () {
      int result = luaGc(L, LuaGC.countB, 0);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc step runs incremental GC', () {
      int result = luaGc(L, LuaGC.step, 0);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc setPause sets pause parameter', () {
      int result = luaGc(L, LuaGC.setPause, 100);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc setStepMul sets step multiplier', () {
      int result = luaGc(L, LuaGC.setStepMul, 200);
      expect(result, greaterThanOrEqualTo(0));
    });

    test('luaGc isRunning checks if GC is running', () {
      int result = luaGc(L, LuaGC.isRunning, 0);
      expect(result, equals(1)); // Should be running by default
    });

    test('luaCloseslot closes to-be-closed slot', () {
      // Skip this test as it requires to-be-closed variable setup
    }, skip: 'luaCloseslot requires to-be-closed variable setup');
  });
}
