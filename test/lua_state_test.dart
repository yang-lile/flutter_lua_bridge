import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart' as flb;
import 'package:test/test.dart';

void main() {
  group('LuaState', () {
    test('should create and close successfully', () {
      final lua = LuaState.create();
      expect(lua.isOpen, isTrue);
      lua.close();
      expect(lua.isOpen, isFalse);
    });

    test('should get Lua version', () {
      LuaState.use((lua) {
        expect(lua.version, equals(504));
        expect(lua.versionString, equals('Lua 504'));
      });
    });

    test('should open standard libraries', () {
      LuaState.use((lua) {
        expect(() => lua.openLibs(), returnsNormally);
      });
    });

    test('should execute Lua code with doString', () {
      LuaState.use((lua) {
        lua.openLibs();
        expect(() => lua.doString('return 42'), returnsNormally);
      });
    });

    test('should throw LuaException on syntax error', () {
      LuaState.use((lua) {
        expect(
          () => lua.doString('function end'), // 语法错误
          throwsA(isA<LuaException>()),
        );
      });
    });

    test('should throw LuaException on runtime error', () {
      LuaState.use((lua) {
        lua.openLibs();
        expect(
          () => lua.doString('error("test error")'),
          throwsA(isA<LuaException>()),
        );
      });
    });

    test('should push and retrieve nil', () {
      LuaState.use((lua) {
        lua.pushNil();
        expect(lua.isNil(-1), isTrue);
        expect(lua.getValue(-1), isNull);
      });
    });

    test('should push and retrieve boolean', () {
      LuaState.use((lua) {
        lua.pushBoolean(true);
        expect(lua.isBoolean(-1), isTrue);
        expect(lua.toBoolean(-1), isTrue);
        expect(lua.getValue(-1), isTrue);

        lua.pushBoolean(false);
        expect(lua.toBoolean(-1), isFalse);
        expect(lua.getValue(-1), isFalse);
      });
    });

    test('should push and retrieve integer', () {
      LuaState.use((lua) {
        lua.pushInteger(42);
        expect(lua.isNumber(-1), isTrue);
        expect(lua.isInteger(-1), isTrue);
        expect(lua.toInteger(-1), equals(42));
        expect(lua.getValue(-1), equals(42));
      });
    });

    test('should push and retrieve number', () {
      LuaState.use((lua) {
        lua.pushNumber(3.14);
        expect(lua.isNumber(-1), isTrue);
        expect(lua.toNumber(-1), closeTo(3.14, 0.001));
        expect(lua.getValue(-1), closeTo(3.14, 0.001));
      });
    });

    test('should push and retrieve string', () {
      LuaState.use((lua) {
        lua.pushString('hello');
        expect(lua.isString(-1), isTrue);
        expect(lua.toLuaString(-1), equals('hello'));
        expect(lua.getValue(-1), equals('hello'));
      });
    });

    test('should manage stack with push and pop', () {
      LuaState.use((lua) {
        expect(lua.top, equals(0));

        lua.pushInteger(1);
        expect(lua.top, equals(1));

        lua.pushInteger(2);
        expect(lua.top, equals(2));

        lua.pop(1);
        expect(lua.top, equals(1));

        lua.pop(1);
        expect(lua.top, equals(0));
      });
    });

    test('should get and set global variables', () {
      LuaState.use((lua) {
        lua.openLibs();
        lua.doString('x = 42');

        final value = lua.getGlobalValue('x');
        expect(value, equals(42));
      });
    });

    test('should create and manipulate tables', () {
      LuaState.use((lua) {
        lua.openLibs();
        lua.doString('t = {a = 1, b = 2}');

        final ptrT = 't'.toPointerChar();
        try {
          flb.lua_getglobal(lua.ptr, ptrT);

          final ptrA = 'a'.toPointerChar();
          try {
            lua.ptr.getField(-1, 'a');
            expect(lua.toInteger(-1), equals(1));
            lua.pop(1);
          } finally {
            calloc.free(ptrA);
          }

          final ptrB = 'b'.toPointerChar();
          try {
            lua.ptr.getField(-1, 'b');
            expect(lua.toInteger(-1), equals(2));
            lua.pop(2);
          } finally {
            calloc.free(ptrB);
          }
        } finally {
          calloc.free(ptrT);
        }
      });
    });

    test('should execute Lua function and get return values', () {
      LuaState.use((lua) {
        lua.openLibs();
        lua.doString('return 1, 2, 3');

        // 栈顶应该有 3 个返回值
        expect(lua.top, equals(3));
        expect(lua.toInteger(-3), equals(1));
        expect(lua.toInteger(-2), equals(2));
        expect(lua.toInteger(-1), equals(3));
      });
    });

    test('tryDoString should return result', () {
      LuaState.use((lua) {
        lua.openLibs();

        final success = lua.tryDoString('return 42');
        expect(success.success, isTrue);

        final failure = lua.tryDoString('error("test")');
        expect(failure.success, isFalse);
        expect(failure.error, isNotNull);
      });
    });

    test('should check gc status', () {
      LuaState.use((lua) {
        lua.openLibs();
        expect(lua.gcIsRunning(), isTrue);

        lua.gcStop();
        expect(lua.gcIsRunning(), isFalse);

        lua.gcRestart();
        expect(lua.gcIsRunning(), isTrue);
      });
    });
  });

  group('LuaResult', () {
    test('should handle success result', () {
      final result = LuaResult<int>.success(42);
      expect(result.success, isTrue);
      expect(result.value, equals(42));
      expect(result.error, isNull);
      expect(result.getOrThrow(), equals(42));
      expect(result.getOrElse(0), equals(42));
    });

    test('should handle failure result', () {
      final exception = LuaException('test error');
      final result = LuaResult<int>.failure(exception);
      expect(result.success, isFalse);
      expect(result.value, isNull);
      expect(result.error, equals(exception));
      expect(() => result.getOrThrow(), throwsA(isA<LuaException>()));
      expect(result.getOrElse(0), equals(0));
      expect(result.errorMessage, equals('test error'));
    });
  });
}
