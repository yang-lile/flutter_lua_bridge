import 'package:test/test.dart';
import 'dart:ffi' as ffi;
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;

void main() {
  group('Metatable Operations Tests', () {
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

    test('luaGetmetatable gets metatable', () {
      luaNewtable(L);
      luaPushinteger(L, 42);
      luaSetmetatable(L, -2);

      luaGetmetatable(L, 1);
      expect(luaGettop(L), equals(2));
      expect(luaIstable(L, 2), equals(1));
    });

    test('luaGetmetatable returns 0 when no metatable', () {
      luaNewtable(L);
      int result = luaGetmetatable(L, 1);
      expect(result, equals(0));
      expect(luaGettop(L), equals(1));
    });

    test('luaSetmetatable sets metatable', () {
      luaNewtable(L);
      luaNewtable(L);
      luaSetmetatable(L, -2);

      luaGetmetatable(L, 1);
      expect(luaGettop(L), equals(2));
      expect(luaIstable(L, 2), equals(1));
    });

    test('luaSetmetatable clears metatable when set to nil', () {
      luaNewtable(L);
      luaNewtable(L);
      luaSetmetatable(L, -2);

      luaGetmetatable(L, 1);
      expect(luaIstable(L, 2), equals(1));

      luaPushnil(L);
      luaSetmetatable(L, 1);

      luaGetmetatable(L, 1);
      expect(luaIstable(L, 2), equals(0));
    });
  });
}
