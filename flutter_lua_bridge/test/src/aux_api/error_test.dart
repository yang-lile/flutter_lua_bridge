import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Error Tests', () {
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

    test('luaLibError throws error', () {
      // Skip this test as it will cause a longjmp
    }, skip: 'luaLibError causes longjmp which is not testable');

    test('luaLibExecresult returns execution result', () {
      // Skip this test as it requires execution context
    }, skip: 'luaLibExecresult requires execution context');

    test('luaLibFileresult returns file operation result', () {
      // Skip this test as it requires file operation
    }, skip: 'luaLibFileresult requires file operation');

    test('luaLibTraceback generates traceback', () {
      // Skip this test as it requires error context
    }, skip: 'luaLibTraceback requires error context');

    test('luaLibWhere generates error location', () {
      // Skip this test as it requires error context
    }, skip: 'luaLibWhere requires error context');

    test('luaLibTypeerror throws type error', () {
      // Skip this test as it will cause a longjmp
    }, skip: 'luaLibTypeerror causes longjmp which is not testable');
  });
}
