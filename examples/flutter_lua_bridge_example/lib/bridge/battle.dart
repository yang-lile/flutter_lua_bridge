import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'battle.g.dart';

// The contract between the card battle game and its Lua scripts.
//
// Card data, passives and skill effects live in `lua/src/cards.tl`; the
// combat formulas live in `lua/src/formulas.tl`. The game runs the formulas
// through one of three APIs that only differ in their safety level, so the
// same battle can be played, compared and benchmarked at O1, O2 and O3.

enum DamageType {
  @LuaName('PHYSICAL')
  physical,
  @LuaName('MAGIC')
  magic,
  @LuaName('HEAL')
  heal,
}

enum SkillTarget {
  @LuaName('SINGLE')
  single,
  @LuaName('ALL_ALLIES')
  allAllies,
}

enum Rarity {
  @LuaName('N')
  n,
  @LuaName('R')
  r,
  @LuaName('SR')
  sr,
  @LuaName('SSR')
  ssr,
  @LuaName('UR')
  ur,
}

enum PassiveTrigger {
  @LuaName('BATTLE_START')
  battleStart,
  @LuaName('TURN_START')
  turnStart,
  @LuaName('ALLY_LOW_HP')
  allyLowHp,
}

class CardStats {
  const CardStats({
    required this.hp,
    required this.attack,
    required this.magicAttack,
    required this.physicalDefense,
    required this.magicDefense,
    required this.speed,
    required this.critRate,
    required this.critDamage,
    required this.magicCritRate,
  });

  final int hp;
  final int attack;
  final int magicAttack;
  final int physicalDefense;
  final int magicDefense;
  final int speed;
  final double critRate;
  final double critDamage;
  final double magicCritRate;
}

class SkillSpec {
  const SkillSpec({
    required this.name,
    required this.description,
    required this.damageType,
    required this.multiplier,
    required this.target,
    required this.cooldown,
    required this.ignoreDefense,
    required this.healBase,
  });

  final String name;
  final String description;
  final DamageType damageType;
  final double multiplier;
  final SkillTarget target;
  final int cooldown;

  /// The share of the target's physical defense the skill ignores.
  final double? ignoreDefense;

  /// The base amount of a heal skill.
  final int? healBase;
}

class PassiveSpec {
  const PassiveSpec({
    required this.name,
    required this.description,
    required this.trigger,
  });

  final String name;
  final String description;
  final PassiveTrigger trigger;
}

class CardSpec {
  const CardSpec({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.stats,
    required this.normalAttack,
    required this.skill,
    required this.passive,
  });

  final String id;
  final String name;
  final String description;
  final Rarity rarity;
  final CardStats stats;
  final SkillSpec normalAttack;
  final SkillSpec skill;
  final PassiveSpec? passive;
}

/// A monster as the formulas see it during a battle.
class Fighter {
  const Fighter({
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.magicAttack,
    required this.physicalDefense,
    required this.magicDefense,
    required this.speed,
    required this.critRate,
    required this.critDamage,
    required this.magicCritRate,
  });

  final String name;
  final int hp;
  final int maxHp;
  final int attack;
  final int magicAttack;
  final int physicalDefense;
  final int magicDefense;
  final int speed;
  final double critRate;
  final double critDamage;
  final double magicCritRate;
}

/// Random numbers in [0, 1) drawn by the game, so that the formulas are pure
/// functions: the same battle gives the same result at every safety level.
class Roll {
  const Roll({required this.crit, required this.variance});

  final double crit;
  final double variance;
}

class Damage {
  const Damage({required this.amount, required this.critical});

  final int amount;
  final bool critical;
}

/// What a passive or a skill does to its target.
class Effect {
  const Effect({
    required this.note,
    required this.heal,
    required this.attackScale,
    required this.damageReduction,
    required this.stun,
    required this.once,
  });

  final String note;
  final int heal;
  final double attackScale;

  /// Replaces the target's damage reduction when greater than zero.
  final double damageReduction;
  final bool stun;

  /// The effect applies at most once per battle and card.
  final bool once;
}

@LuaApi(module: 'cards')
abstract class CardApi {
  List<CardSpec> catalog();

  /// The passive of [cardId] for [trigger], or null when it does not fire.
  /// [target] is the card itself, or the ally for [PassiveTrigger.allyLowHp].
  Effect? passive(
    String cardId,
    PassiveTrigger trigger,
    Fighter self,
    Fighter target,
  );

  /// The extra effect of the skill of [cardId] on the [target] it hit.
  Effect? skillEffect(String cardId, Fighter target, double roll);
}

/// The combat formulas, declared once. Each API below implements this
/// interface at one safety level; the game picks one at run time.
abstract interface class BattleFormulas {
  Damage physicalDamage(
    Fighter attacker,
    Fighter defender,
    double multiplier,
    Roll roll,
  );

  Damage magicDamage(
    Fighter attacker,
    Fighter defender,
    double multiplier,
    Roll roll,
  );

  int heal(Fighter caster, int base);

  /// Indices of the living [fighters], fastest first.
  List<int> actionOrder(List<Fighter> fighters);
}

/// Lua checks every argument and result, and `pcall` catches errors.
@LuaApi(module: 'formulas_o1', optimization: LuaOptimization.o1)
abstract class FormulasO1Api implements BattleFormulas {}

/// `pcall` catches errors; no Lua type checks.
@LuaApi(module: 'formulas_o2', optimization: LuaOptimization.o2)
abstract class FormulasO2Api implements BattleFormulas {}

/// Direct calls: errors are thrown as exceptions.
@LuaApi(module: 'formulas_o3', optimization: LuaOptimization.o3)
abstract class FormulasO3Api implements BattleFormulas {}
