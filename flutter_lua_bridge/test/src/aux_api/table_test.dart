import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Table Tests', () {
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

    test('luaLibNewmetatable creates new metatable', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibNewmetatable requires string handling');

    test('luaLibGetmetatable gets metatable', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibGetmetatable requires string handling');

    test('luaLibSetmetatable sets metatable', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibSetmetatable requires string handling');

    test('luaLibCallmeta calls metamethod', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibCallmeta requires string handling');

    test('luaLibGetmetafield gets metatable field', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibGetmetafield requires string handling');

    test('luaLibGetsubtable gets subtable', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibGetsubtable requires string handling');

    test('luaLibGsub performs global substitution', () {
      // Skip this test as it requires string handling
    }, skip: 'luaLibGsub requires string handling');
  });
}
