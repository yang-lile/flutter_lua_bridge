import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_example/scenarios.g.dart';

CalculationInput input({
  int base = 7,
  int multiplier = 3,
  int add = 2,
  String operation = 'affine',
}) => CalculationInput(
  base: base,
  multiplier: multiplier,
  add: add,
  operation: operation,
);

Future<String> source(String name) => rootBundle.loadString(
  name == 'pure_teal.lua'
      ? 'lua/build/pure_teal.lua'
      : 'assets/scenarios/$name',
);

LuaRuntime newRuntime() {
  TestWidgetsFlutterBinding.ensureInitialized();
  return LuaRuntime.create();
}

void expectResult(
  LuaCallResult<CalculationResult> result, {
  required int value,
  required String implementation,
}) {
  if (result is LuaFailure<CalculationResult>) {
    throw StateError('Lua call failed: ${result.kind} ${result.message}');
  }
  final actual = (result as LuaSuccess<CalculationResult>).value;
  if (actual.value != value || actual.implementation != implementation) {
    throw StateError(
      'Expected $value/$implementation, got '
      '${actual.value}/${actual.implementation}',
    );
  }
}
