import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/bridge/basic_bridge_demo.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('BasicBridgeDemo Tests', () {
    test('should return valid Lua version and random values', () {
      final result = BasicBridgeDemo.run();

      // Lua version should be a positive number (e.g. 504 for Lua 5.4)
      expect(result.luaVersion, greaterThan(0));

      // Random values should be within 1-1024
      expect(result.a, greaterThanOrEqualTo(1));
      expect(result.a, lessThanOrEqualTo(1024));
      expect(result.b, greaterThanOrEqualTo(1));
      expect(result.b, lessThanOrEqualTo(1024));
    });

    test('should return consistent Lua version across calls', () {
      final result1 = BasicBridgeDemo.run();
      final result2 = BasicBridgeDemo.run();

      expect(result1.luaVersion, equals(result2.luaVersion));
    });

    test('should return integer values for a and b', () {
      final result = BasicBridgeDemo.run();

      expect(result.a, isA<int>());
      expect(result.b, isA<int>());
    });
  });
}
