import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/bridge/scenarios.dart';
import 'scenario_test_helpers.dart';

void main() {
  testWidgets('pure Lua implements a generated Dart API', (tester) async {
    final lua = newRuntime();
    try {
      final api = PureLuaApiClient.load(
        runtime: lua,
        source: await source('pure_lua.lua'),
      );
      expectResult(
        api.calculate(input()),
        value: 23,
        implementation: 'pure-lua',
      );
    } finally {
      lua.close();
    }
  });
}
