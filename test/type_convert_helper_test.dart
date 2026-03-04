import 'dart:ffi';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';

void main() {
  group('PointCharX', () {
    test('toDartString should convert C string to Dart string', () {
      final ptr = 'hello'.toPointerChar();
      try {
        expect(ptr.cast<Utf8>().toDartString(), equals('hello'));
      } finally {
        calloc.free(ptr);
      }
    });

    test('toDartString should return empty string for null', () {
      expect(PointCharX(nullptr).toDartString(), equals(''));
    });

    test('toDartStringSafe should respect max length', () {
      final ptr = 'hello world'.toPointerChar();
      try {
        expect(ptr.toDartStringSafe(5), equals('hello'));
      } finally {
        calloc.free(ptr);
      }
    });
  });

  group('NativePointCharX', () {
    test('toPointerChar should convert Dart string to C string', () {
      final ptr = 'test'.toPointerChar();
      try {
        expect(ptr, isNotNull);
        expect(ptr.toDartString(), equals('test'));
      } finally {
        calloc.free(ptr);
      }
    });

    test('toUtf8Pointer should convert to Utf8 pointer', () {
      final ptr = 'test'.toUtf8Pointer();
      try {
        expect(ptr, isNotNull);
        expect(ptr.toDartString(), equals('test'));
      } finally {
        calloc.free(ptr);
      }
    });
  });

  group('StringPointerHelper', () {
    test('withPointerChar should auto-free pointer', () {
      Pointer<Char>? capturedPtr;
      'test'.withPointerChar((ptr) {
        capturedPtr = ptr;
        expect(ptr.toDartString(), equals('test'));
      });
      // 指针应该已被释放，但我们无法直接测试这一点
    });
  });

  group('StringBatch', () {
    test('should manage multiple pointers', () {
      final batch = StringBatch();

      final ptr1 = batch.add('hello');
      final ptr2 = batch.add('world');

      expect(ptr1.toDartString(), equals('hello'));
      expect(ptr2.toDartString(), equals('world'));

      batch.freeAll();
    });
  });

  group('LuaStateX', () {
    test('isValid should return correct value', () {
      LuaState.use((lua) {
        expect(lua.ptr.isValid, isTrue);
      });
    });

    test('should get and set top', () {
      LuaState.use((lua) {
        lua.pushInteger(1);
        lua.pushInteger(2);
        expect(lua.ptr.top, equals(2));

        lua.ptr.top = 1;
        expect(lua.ptr.top, equals(1));
      });
    });

    test('checkStack should verify stack space', () {
      LuaState.use((lua) {
        expect(lua.ptr.checkStack(10), isTrue);
        expect(lua.ptr.checkStack(1000), isTrue); // Lua 通常允许较大的栈
      });
    });

    test('should get type information', () {
      LuaState.use((lua) {
        lua.pushInteger(42);
        expect(lua.ptr.getType(-1), equals(LuaType.NUMBER));
        expect(lua.ptr.getTypeName(LuaType.NUMBER), equals('number'));
      });
    });

    test('should check value types', () {
      LuaState.use((lua) {
        lua.pushNil();
        expect(lua.ptr.isNil(-1), isTrue);
        lua.pop(1);

        lua.pushBoolean(true);
        expect(lua.ptr.isBoolean(-1), isTrue);
        lua.pop(1);

        lua.pushInteger(42);
        expect(lua.ptr.isNumber(-1), isTrue);
        expect(lua.ptr.isInteger(-1), isTrue);
        lua.pop(1);

        lua.pushString('test');
        expect(lua.ptr.isString(-1), isTrue);
        lua.pop(1);
      });
    });

    test('should convert to Dart types', () {
      LuaState.use((lua) {
        lua.pushInteger(42);
        expect(lua.ptr.toInteger(-1), equals(42));
        lua.pop(1);

        lua.pushNumber(3.14);
        expect(lua.ptr.toNumber(-1), closeTo(3.14, 0.001));
        lua.pop(1);

        lua.pushBoolean(true);
        expect(lua.ptr.toBoolean(-1), isTrue);
        lua.pop(1);

        lua.pushString('hello');
        expect(lua.ptr.toLuaString(-1), equals('hello'));
        lua.pop(1);
      });
    });

    test('should manage global variables', () {
      LuaState.use((lua) {
        lua.openLibs();
        lua.doString('testGlobal = 123');

        lua.ptr.getGlobal('testGlobal');
        expect(lua.ptr.toInteger(-1), equals(123));
        lua.pop(1);
      });
    });

    test('should do string with automatic memory management', () {
      LuaState.use((lua) {
        lua.openLibs();

        // 使用指针扩展执行代码
        final result = lua.ptr.doString('return 42');
        expect(result, equals(LuaStatus.OK));
        expect(lua.ptr.toInteger(-1), equals(42));
      });
    });

    test('should get error message', () {
      LuaState.use((lua) {
        lua.openLibs();
        final status = lua.ptr.doString('error("test error")');
        expect(status, isNot(equals(LuaStatus.OK)));

        final msg = lua.ptr.getErrorMessage();
        expect(msg, contains('test error'));
      });
    });
  });
}
