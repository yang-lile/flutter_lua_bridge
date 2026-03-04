import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:test/test.dart';

void main() {
  group('LuaType', () {
    test('should have correct type values', () {
      expect(LuaType.NONE, equals(-1));
      expect(LuaType.NIL, equals(0));
      expect(LuaType.BOOLEAN, equals(1));
      expect(LuaType.NUMBER, equals(3));
      expect(LuaType.STRING, equals(4));
      expect(LuaType.TABLE, equals(5));
      expect(LuaType.FUNCTION, equals(6));
    });

    test('getName should return correct type names', () {
      expect(LuaType.getName(LuaType.NIL), equals('nil'));
      expect(LuaType.getName(LuaType.BOOLEAN), equals('boolean'));
      expect(LuaType.getName(LuaType.NUMBER), equals('number'));
      expect(LuaType.getName(LuaType.STRING), equals('string'));
      expect(LuaType.getName(LuaType.TABLE), equals('table'));
      expect(LuaType.getName(LuaType.FUNCTION), equals('function'));
    });

    test('getName should return unknown for invalid type', () {
      expect(LuaType.getName(999), equals('unknown'));
    });
  });

  group('LuaStatus', () {
    test('should have correct status values', () {
      expect(LuaStatus.OK, equals(0));
      expect(LuaStatus.YIELD, equals(1));
      expect(LuaStatus.ERRRUN, equals(2));
      expect(LuaStatus.ERRSYNTAX, equals(3));
      expect(LuaStatus.ERRMEM, equals(4));
    });

    test('getDescription should return correct descriptions', () {
      expect(LuaStatus.getDescription(LuaStatus.OK), equals('OK'));
      expect(LuaStatus.getDescription(LuaStatus.YIELD), equals('YIELD'));
      expect(LuaStatus.getDescription(LuaStatus.ERRRUN), contains('Runtime'));
      expect(LuaStatus.getDescription(LuaStatus.ERRSYNTAX), contains('Syntax'));
      expect(LuaStatus.getDescription(LuaStatus.ERRMEM), contains('Memory'));
    });
  });

  group('LuaGC', () {
    test('should have correct GC operation values', () {
      expect(LuaGC.STOP, equals(0));
      expect(LuaGC.RESTART, equals(1));
      expect(LuaGC.COLLECT, equals(2));
      expect(LuaGC.COUNT, equals(3));
      expect(LuaGC.ISRUNNING, equals(9));
    });
  });

  group('Constants', () {
    test('LUA_MULTRET should be -1', () {
      expect(LUA_MULTRET, equals(-1));
    });

    test('LUA_NOREF and LUA_REFNIL should have correct values', () {
      expect(LUA_NOREF, equals(-2));
      expect(LUA_REFNIL, equals(-1));
    });

    test('lua_upvalueindex should calculate correct index', () {
      expect(lua_upvalueindex(1), equals(LuaRegistryIndex.REGISTRYINDEX - 1));
      expect(lua_upvalueindex(2), equals(LuaRegistryIndex.REGISTRYINDEX - 2));
    });
  });

  group('LuaRegistryIndex', () {
    test('should have correct registry index values', () {
      expect(LuaRegistryIndex.REGISTRYINDEX, equals(-1001000));
      expect(LuaRegistryIndex.RIDX_MAINTHREAD, equals(1));
      expect(LuaRegistryIndex.RIDX_GLOBALS, equals(2));
    });
  });
}
