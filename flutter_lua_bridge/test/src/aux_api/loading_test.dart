import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Loading Tests', () {
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

    test('luaLibDostring executes string', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibDostring requires string handling');

    test('luaLibDofile executes file', () {
      // Skip this test as it requires file handling
    }, skip: 'luaLibDofile requires file handling');

    test('luaLibLoadstring loads string', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibLoadstring requires string handling');

    test('luaLibLoadfile loads file', () {
      // Skip this test as it requires file handling
    }, skip: 'luaLibLoadfile requires file handling');

    test('luaLibLoadbuffer loads buffer', () {
      // Skip this test as it requires buffer handling
    }, skip: 'luaLibLoadbuffer requires buffer handling');

    test('luaLibLoadbufferx loads buffer with mode', () {
      // Skip this test as it requires buffer handling
    }, skip: 'luaLibLoadbufferx requires buffer handling');

    test('luaLibLoadfilex loads file with mode', () {
      // Skip this test as it requires file handling
    }, skip: 'luaLibLoadfilex requires file handling');
  });
}
