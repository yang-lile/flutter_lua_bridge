import 'package:flutter_lua_shim/flutter_lua_shim.dart';
import 'package:test/test.dart';

void main() {
  group('Lua Source URL Test', () {
    late LuaState lua;

    setUp(() {
      lua = LuaState.newState();
    });

    tearDown(() {
      lua.close();
    });

    test('Lua state is created successfully', () {
      expect(lua.top, equals(0));
    });

    test('Can execute simple Lua code', () {
      final status = lua.loadString('return 42');
      expect(status, equals(0)); // LUA_OK = 0
      
      lua.pCall(0, 1);
      
      final result = lua.toIntegerX(-1);
      expect(result, equals(42));
    });

    test('Can define and call Lua function', () {
      final status = lua.loadString('''
        function add(a, b)
          return a + b
        end
      ''');
      expect(status, equals(0)); // LUA_OK = 0
      
      lua.pCall(0, 0);

      lua.getGlobal('add');
      lua.pushInteger(10);
      lua.pushInteger(20);
      lua.pCall(2, 1);

      final result = lua.toIntegerX(-1);
      expect(result, equals(30));
    });

    test('Can work with strings', () {
      final status = lua.loadString('return "Hello, Lua!"');
      expect(status, equals(0)); // LUA_OK = 0
      
      lua.pCall(0, 1);

      final result = lua.toLString(-1);
      expect(result, equals('Hello, Lua!'));
    });

    test('Can work with tables', () {
      final status = lua.loadString('''
        local t = {name = "test", value = 123}
        return t
      ''');
      expect(status, equals(0)); // LUA_OK = 0
      
      lua.pCall(0, 1);

      expect(lua.isTable(-1), isTrue);
      
      lua.getField(-1, 'name');
      expect(lua.toLString(-1), equals('test'));
      lua.pop(1);

      lua.getField(-1, 'value');
      expect(lua.toIntegerX(-1), equals(123));
      lua.pop(1);
    });

    test('Can handle multiple return values', () {
      final status = lua.loadString('return 1, 2, 3, 4, 5');
      expect(status, equals(0)); // LUA_OK = 0
      
      lua.pCall(0, 5);

      expect(lua.top, equals(5));
      expect(lua.toIntegerX(1), equals(1));
      expect(lua.toIntegerX(2), equals(2));
      expect(lua.toIntegerX(3), equals(3));
      expect(lua.toIntegerX(4), equals(4));
      expect(lua.toIntegerX(5), equals(5));
    });

    test('Can handle Lua errors', () {
      final status = lua.loadString('error("This is a test error")');
      expect(status, equals(0)); // LUA_OK = 0
      
      final callStatus = lua.pCall(0, 0);
      
      expect(callStatus, isNot(equals(0))); // Not LUA_OK
    });

    test('Can work with boolean values', () {
      final status = lua.loadString('return true, false');
      expect(status, equals(0)); // LUA_OK = 0
      
      lua.pCall(0, 2);

      expect(lua.toBoolean(-1), isFalse);
      expect(lua.toBoolean(-2), isTrue);
    });

    test('Can handle nil values', () {
      final status = lua.loadString('return nil');
      expect(status, equals(0)); // LUA_OK = 0
      
      lua.pCall(0, 1);

      expect(lua.isNil(-1), isTrue);
    });

    test('Can use stack operations', () {
      lua.pushInteger(1);
      lua.pushInteger(2);
      lua.pushInteger(3);
      expect(lua.top, equals(3));

      lua.pop(1);
      expect(lua.top, equals(2));

      lua.pushValue(-1);
      expect(lua.top, equals(3));
      expect(lua.toIntegerX(-1), equals(2));
    });
  });
}
