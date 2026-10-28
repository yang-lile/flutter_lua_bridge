import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/scenarios.g.dart';
import 'scenario_test_helpers.dart';

class ScenarioHost implements ScenarioHostApi {
  @override
  int clamp(int value, int minimum, int maximum) =>
      value.clamp(minimum, maximum).toInt();

  @override
  String label(String name) => 'host:$name';
}

void main() {
  testWidgets('Lua calls pre-registered Dart host functions', (tester) async {
    final lua = newRuntime();
    try {
      ScenarioHostApi.setUp(ScenarioHost(), runtime: lua);
      final api = DartHostLuaApi.load(
        runtime: lua,
        source: await source('dart_host.lua'),
      );
      expectResult(
        api.calculate(input()),
        value: 23,
        implementation: 'host:dart-host',
      );
      expectResult(
        api.calculate(input(base: 50)),
        value: 100,
        implementation: 'host:dart-host',
      );
    } finally {
      lua.close();
    }
  });
}
