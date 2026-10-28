import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

class Fighter {
  const Fighter({required this.attack, required this.defense});
  final int attack;
  final int defense;
}

class DamageResult {
  const DamageResult({required this.damage, required this.critical});
  final int damage;
  final bool critical;
}

@ConfigureLuaBridge(
  dartOut: 'lib/battle.g.dart',
  luaOut: 'lua/src/battle_bridge.lua',
  tealOut: 'lua/src/battle_bridge.d.tl',
)
@LuaApi(module: 'battle')
abstract class BattleApi {
  @LuaName('calculate_damage')
  DamageResult calculateDamage(Fighter attacker, Fighter defender);
}

@DartApi(module: 'host')
abstract class HostApi {
  void log(String message);
  int bonus(int damage);
}
