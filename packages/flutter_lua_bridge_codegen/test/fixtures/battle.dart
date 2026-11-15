import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'battle.g.dart';

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

/// Implemented in Teal: `lua/src/battle.tl`.
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
