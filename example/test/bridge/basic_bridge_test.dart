import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_example/bridge/basic_bridge_demo.dart';
import 'package:flutter_lua_bridge_example/bridge/basic_api.g.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('BasicBridgeDemo Tests', () {
    test('should return valid Lua version and random values', () async {
      final result = await BasicBridgeDemo.run();
      expect(result, isA<LuaSuccess<RandomResult>>());
      final value = (result as LuaSuccess<RandomResult>).value;

      // Lua version should be a positive number (e.g. 504 for Lua 5.4)
      expect(value.luaVersion, greaterThan(0));

      // Random values should be within 1-1024
      expect(value.a, greaterThanOrEqualTo(1));
      expect(value.a, lessThanOrEqualTo(1024));
      expect(value.b, greaterThanOrEqualTo(1));
      expect(value.b, lessThanOrEqualTo(1024));
    });

    test('should return consistent Lua version across calls', () async {
      final result1 = await BasicBridgeDemo.run();
      final result2 = await BasicBridgeDemo.run();

      expect(result1, isA<LuaSuccess<RandomResult>>());
      expect(result2, isA<LuaSuccess<RandomResult>>());
      expect(
        (result1 as LuaSuccess<RandomResult>).value.luaVersion,
        equals((result2 as LuaSuccess<RandomResult>).value.luaVersion),
      );
    });

    test('should return integer values for a and b', () async {
      final result = await BasicBridgeDemo.run();
      expect(result, isA<LuaSuccess<RandomResult>>());
      final value = (result as LuaSuccess<RandomResult>).value;

      expect(value.a, isA<int>());
      expect(value.b, isA<int>());
    });
  });
}
