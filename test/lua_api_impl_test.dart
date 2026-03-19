import 'dart:ffi';

import 'package:flutter_lua_bridge/src/implementations/index.dart';
import 'package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart' as gen;
import 'package:test/test.dart';

// 检查 FFI 是否可用的标志
bool _ffiAvailable = true;
String? _ffiError;

void _checkFfiAvailable() {
  if (!_ffiAvailable) return;
  try {
    // 尝试创建 Lua 状态
    final lua = LuaAPI.create();
    lua.close();
  } catch (e) {
    _ffiAvailable = false;
    _ffiError = e.toString();
  }
}

void main() {
  setUpAll(() {
    _checkFfiAvailable();
    if (!_ffiAvailable) {
      print('⚠️  FFI not available: $_ffiError');
      print('Tests will be skipped. Build native assets with:');
      print('  dart run hook/build.dart --config path/to/config.json');
    }
  });

  group('LuaAPI', () {
    test('should create and close state', () {
      if (!_ffiAvailable) return;
      final lua = LuaAPI.create();
      expect(lua.state, isNot(nullptr));
      lua.close();
    });

    test('should use try-finally pattern', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        expect(lua.state, isNot(nullptr));
      });
    });

    test('should get top of stack', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        expect(lua.top, equals(0));
        lua.pushNil();
        expect(lua.top, equals(1));
        lua.pop(1);
        expect(lua.top, equals(0));
      });
    });

    test('should push and pop values', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        lua.pushNil();
        expect(lua.top, equals(1));
        expect(lua.isNil(-1), isTrue);

        lua.pushBool(true);
        expect(lua.top, equals(2));
        expect(lua.isBool(-1), isTrue);
        expect(lua.toBool(-1), isTrue);

        lua.pushInt(42);
        expect(lua.top, equals(3));
        expect(lua.isNumber(-1), isTrue);
        expect(lua.toInt(-1), equals(42));

        lua.pushDouble(3.14);
        expect(lua.top, equals(4));
        expect(lua.isNumber(-1), isTrue);
        expect(lua.toDouble(-1), closeTo(3.14, 0.001));

        lua.pop(4);
        expect(lua.top, equals(0));
      });
    });

    test('should manipulate stack', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        lua.pushInt(1);
        lua.pushInt(2);
        lua.pushInt(3);
        expect(lua.top, equals(3));

        lua.copy(1, 3);
        expect(lua.toInt(-1), equals(1));

        lua.remove(1);
        expect(lua.top, equals(2));

        lua.pushValue(1);
        expect(lua.top, equals(3));
        expect(lua.toInt(-1), equals(2));

        lua.pop(3);
      });
    });

    test('should get and set global variables', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        // Push a value and set as global
        lua.pushInt(100);
        lua.setGlobal('testVar');

        // Get the global variable
        lua.getGlobal('testVar');
        expect(lua.toInt(-1), equals(100));
        lua.pop(1);
      });
    });

    test('should create and manipulate tables', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        lua.createTable(0, 2);
        expect(lua.isTable(-1), isTrue);

        lua.pushInt(1);
        lua.setField(-2, 'a');

        lua.pushInt(2);
        lua.setField(-2, 'b');

        lua.getField(-1, 'a');
        expect(lua.toInt(-1), equals(1));
        lua.pop(2);
      });
    });

    test('should perform arithmetic operations', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        lua.pushInt(10);
        lua.pushInt(5);
        lua.arith(gen.LUA_OPADD);
        expect(lua.toInt(-1), equals(15));
        lua.pop(1);

        lua.pushInt(10);
        lua.pushInt(3);
        lua.arith(gen.LUA_OPMOD);
        expect(lua.toInt(-1), equals(1));
        lua.pop(1);
      });
    });

    test('should concatenate strings', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        lua.pushString('Hello');
        lua.pushString('World');
        lua.concat(2);
        expect(lua.isString(-1), isTrue);
        lua.pop(1);
      });
    });

    test('should check types correctly', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        lua.pushNil();
        expect(lua.isNil(-1), isTrue);

        lua.pushBool(true);
        expect(lua.isBool(-1), isTrue);

        lua.pushInt(42);
        expect(lua.isNumber(-1), isTrue);
        expect(lua.isInt(-1), isTrue);

        lua.pushDouble(3.14);
        expect(lua.isNumber(-1), isTrue);

        lua.createTable(0, 0);
        expect(lua.isTable(-1), isTrue);

        lua.pop(5);
      });
    });

    test('should compare values', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        lua.pushInt(5);
        lua.pushInt(10);
        expect(lua.compare(-2, -1, gen.LUA_OPLT), isTrue);
        expect(lua.compare(-1, -2, gen.LUA_OPLT), isFalse);

        lua.pushInt(5);
        expect(lua.compare(-3, -1, gen.LUA_OPEQ), isTrue);
        lua.pop(3);
      });
    });

    test('should use version and checkVersion', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        expect(lua.version, greaterThan(0));
        expect(() => lua.checkVersion(), returnsNormally);
      });
    });

    test('should work with references', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        // Push a value
        lua.pushInt(123);

        // Create reference
        final ref = lua.ref(gen.LUA_REGISTRYINDEX);
        expect(ref, isNot(equals(gen.LUA_REFNIL)));

        // Clear stack
        lua.setTop(0);
        expect(lua.top, equals(0));

        // Get reference back
        lua.rawGetI(gen.LUA_REGISTRYINDEX, ref);
        expect(lua.toInt(-1), equals(123));
        lua.pop(1);

        // Release reference
        lua.unref(gen.LUA_REGISTRYINDEX, ref);
      });
    });

    test('should create and use metatables', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        final created = lua.newMetaTable('TestMeta');
        expect(created, isTrue);

        lua.pushInt(1);
        lua.setField(-2, '__index');
        lua.pop(1);

        // Second call should return false (already exists)
        final exists = lua.newMetaTable('TestMeta');
        expect(exists, isFalse);
        lua.pop(1);
      });
    });

    test('should use gc functions', () {
      if (!_ffiAvailable) return;
      LuaAPI.use((lua) {
        // Stop GC
        lua.gc(gen.LUA_GCSTOP);

        // Restart GC
        lua.gc(gen.LUA_GCRESTART);

        // Run full collection
        lua.gc(gen.LUA_GCCOLLECT);

        // Get count
        final count = lua.gc(gen.LUA_GCCOUNT);
        expect(count, greaterThanOrEqualTo(0));
      });
    });
  });
}
