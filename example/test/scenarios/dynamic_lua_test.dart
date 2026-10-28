import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_example/scenarios.g.dart';
import 'scenario_test_helpers.dart';

void main() {
  testWidgets('Lua selects a dynamic formula through typed data', (
    tester,
  ) async {
    final lua = newRuntime();
    try {
      final api = DynamicLuaApi.load(
        runtime: lua,
        source: await source('dynamic_lua.lua'),
      );
      expectResult(
        api.calculate(input(operation: 'double')),
        value: 14,
        implementation: 'dynamic:double',
      );
      expectResult(
        api.calculate(input(operation: 'affine')),
        value: 23,
        implementation: 'dynamic:affine',
      );
      expect(
        api.calculate(input(operation: 'missing')),
        isA<LuaFailure<CalculationResult>>(),
      );
    } finally {
      lua.close();
    }
  });
}
