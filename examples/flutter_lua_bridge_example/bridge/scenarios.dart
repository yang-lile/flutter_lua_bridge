import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

/// One DTO is shared by all four examples so the tests exercise the same
/// generated boundary with different implementation strategies.
class CalculationInput {
  const CalculationInput({
    required this.base,
    required this.multiplier,
    required this.add,
    required this.operation,
  });

  final int base;
  final int multiplier;
  final int add;
  final String operation;
}

class CalculationResult {
  const CalculationResult({required this.value, required this.implementation});

  final int value;
  final String implementation;
}

@ConfigureLuaBridge(
  dartOut: 'lib/scenarios.g.dart',
  luaOut: 'lua/src/scenarios_bridge.lua',
  tealOut: 'lua/src/scenarios_bridge.d.tl',
)
@LuaApi(module: 'pure_lua')
abstract class PureLuaApi {
  CalculationResult calculate(CalculationInput input);
}

@LuaApi(module: 'pure_teal')
abstract class PureTealApi {
  CalculationResult calculate(CalculationInput input);
}

@LuaApi(module: 'dynamic_lua')
abstract class DynamicLuaApi {
  CalculationResult calculate(CalculationInput input);
}

@LuaApi(module: 'dart_host')
abstract class DartHostLuaApi {
  CalculationResult calculate(CalculationInput input);
}

@DartApi(module: 'host')
abstract class ScenarioHostApi {
  int clamp(int value, int minimum, int maximum);
  String label(String name);
}
