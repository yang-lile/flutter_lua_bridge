import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/bridge/scenarios.dart';

import 'scenario_test_helpers.dart';

void main() {
  testWidgets('compiled Teal implements a generated Dart API', (tester) async {
    final lua = newRuntime();
    try {
      final api = PureTealApiClient.load(
        runtime: lua,
        source: await source('pure_teal.lua'),
      );
      expectResult(
        api.calculate(input()),
        value: 23,
        implementation: 'pure-teal',
      );
    } finally {
      lua.close();
    }
  });
}
