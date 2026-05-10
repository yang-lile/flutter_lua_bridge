import 'package:flutter_lua_shim/flutter_lua_shim.dart';
import 'package:test/test.dart';

void main() {
  test('creates Lua state and runs basic script', () {
    final L = LuaState.newState();
    expect(L.top, equals(0));

    L.openLibs();

    final loadStatus = L.loadString('''
      function add(a, b)
        return a + b
      end
    ''');
    expect(loadStatus, equals(LuaStatus.LUA_SHIM_OK.value));

    final callStatus = L.pCall(0, 0);
    expect(callStatus, equals(LuaStatus.LUA_SHIM_OK.value));

    L.getGlobal('add');
    expect(L.typeName(L.type(-1)), equals('function'));

    L.pushInteger(10);
    L.pushInteger(20);
    expect(L.top, equals(3));

    final pcallStatus = L.pCall(2, 1);
    expect(pcallStatus, equals(LuaStatus.LUA_SHIM_OK.value));

    expect(L.typeName(L.type(-1)), equals('number'));
    expect(L.toIntegerX(-1), equals(30));
    L.pop(1);

    L.close();
  });

  test('pushes and reads different types', () {
    final L = LuaState.newState();

    L.pushNil();
    expect(L.isNil(-1), isTrue);

    L.pushBoolean(true);
    expect(L.isBoolean(-1), isTrue);
    expect(L.toBoolean(-1), isTrue);

    L.pushNumber(3.14);
    expect(L.isNumber(-1), isTrue);
    expect(L.toNumberX(-1), closeTo(3.14, 0.001));

    L.pushString('hello');
    expect(L.isString(-1), isTrue);
    expect(L.toLString(-1), equals('hello'));

    L.close();
  });
}
