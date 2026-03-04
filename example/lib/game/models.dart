// 游戏数据模型
import 'dart:ffi';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart' as flb;

/// 伤害类型
enum DamageType { physical, magic, heal }

/// 技能配置
class Skill {
  String name;
  String description;
  final DamageType type;
  final double multiplier;
  final String target;
  final int cooldown;
  final double? ignoreDefense;
  final int? healBase;

  Skill({
    required this.name,
    required this.description,
    required this.type,
    required this.multiplier,
    required this.target,
    required this.cooldown,
    this.ignoreDefense,
    this.healBase,
  });

  factory Skill.fromLua(Map<String, dynamic> data) {
    return Skill(
      name: data['name']?.toString() ?? 'Unknown',
      description: data['description']?.toString() ?? '',
      type: _parseDamageType(data['type']?.toString()),
      multiplier: data['multiplier'] != null 
          ? (data['multiplier'] as num).toDouble() 
          : 1.0,
      target: data['target']?.toString() ?? 'SINGLE',
      cooldown: data['cooldown'] != null 
          ? (data['cooldown'] as num).toInt() 
          : 0,
      ignoreDefense: data['ignoreDefense'] != null 
          ? (data['ignoreDefense'] as num).toDouble() 
          : null,
      healBase: data['healBase'] != null 
          ? (data['healBase'] as num).toInt() 
          : null,
    );
  }

  static DamageType _parseDamageType(String? type) {
    switch (type) {
      case 'PHYSICAL':
        return DamageType.physical;
      case 'MAGIC':
        return DamageType.magic;
      case 'HEAL':
        return DamageType.heal;
      default:
        return DamageType.physical;
    }
  }
}

/// 怪物卡牌
class MonsterCard {
  final String id;
  String name;
  String description;
  final String rarity;
  
  // 基础属性
  int maxHp;
  int hp;
  int attack;
  int magicAttack;
  int physicalDefense;
  int magicDefense;
  int speed;
  double critRate;
  double critDamage;
  double magicCritRate;
  
  // 战斗状态
  int currentCooldown = 0;
  bool stunned = false;
  bool stealth = false;
  double damageReduction = 0.0;
  bool berserkActive = false;
  
  // 技能
  final Skill normalAttack;
  final Skill skill;
  
  // Lua 函数引用（用于被动技能）
  final Pointer<flb.lua_State>? luaState;
  final int? passiveRef;

  MonsterCard({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.maxHp,
    required this.hp,
    required this.attack,
    required this.magicAttack,
    required this.physicalDefense,
    required this.magicDefense,
    required this.speed,
    required this.critRate,
    required this.critDamage,
    required this.magicCritRate,
    required this.normalAttack,
    required this.skill,
    this.luaState,
    this.passiveRef,
  });

  /// 从 Lua 表创建怪物
  factory MonsterCard.fromLua(
    Map<String, dynamic> data,
    Pointer<flb.lua_State>? luaState,
    int? passiveRef,
  ) {
    final stats = data['baseStats'] as Map<String, dynamic>? ?? {};
    
    return MonsterCard(
      id: data['id']?.toString() ?? 'unknown',
      name: data['name']?.toString() ?? 'Unknown',
      description: data['description']?.toString() ?? '',
      rarity: data['rarity']?.toString() ?? 'N',
      maxHp: stats['hp'] != null ? (stats['hp'] as num).toInt() : 100,
      hp: stats['hp'] != null ? (stats['hp'] as num).toInt() : 100,
      attack: stats['attack'] != null ? (stats['attack'] as num).toInt() : 10,
      magicAttack: stats['magicAttack'] != null ? (stats['magicAttack'] as num).toInt() : 0,
      physicalDefense: stats['physicalDefense'] != null ? (stats['physicalDefense'] as num).toInt() : 0,
      magicDefense: stats['magicDefense'] != null ? (stats['magicDefense'] as num).toInt() : 0,
      speed: stats['speed'] != null ? (stats['speed'] as num).toInt() : 10,
      critRate: stats['critRate'] != null ? (stats['critRate'] as num).toDouble() : 0.0,
      critDamage: stats['critDamage'] != null ? (stats['critDamage'] as num).toDouble() : 1.5,
      magicCritRate: stats['magicCritRate'] != null ? (stats['magicCritRate'] as num).toDouble() : 0.0,
      normalAttack: Skill.fromLua((data['normalAttack'] as Map<String, dynamic>?) ?? {}),
      skill: Skill.fromLua((data['skill'] as Map<String, dynamic>?) ?? {}),
      luaState: luaState,
      passiveRef: passiveRef,
    );
  }

  /// 创建副本（用于战斗）
  MonsterCard copy() {
    return MonsterCard(
      id: id,
      name: name,
      description: description,
      rarity: rarity,
      maxHp: maxHp,
      hp: hp,
      attack: attack,
      magicAttack: magicAttack,
      physicalDefense: physicalDefense,
      magicDefense: magicDefense,
      speed: speed,
      critRate: critRate,
      critDamage: critDamage,
      magicCritRate: magicCritRate,
      normalAttack: normalAttack,
      skill: skill,
      luaState: luaState,
      passiveRef: passiveRef,
    );
  }

  /// 检查是否存活
  bool get isAlive => hp > 0;

  /// 获取当前血量百分比
  double get hpPercent => hp / maxHp;

  @override
  String toString() => '$name [HP: $hp/$maxHp]';
}

/// 战斗日志条目
class BattleLog {
  final int turn;
  final String actor;
  final String action;
  final String? target;
  final int? damage;
  final bool? isCrit;
  final String? specialEffect;

  BattleLog({
    required this.turn,
    required this.actor,
    required this.action,
    this.target,
    this.damage,
    this.isCrit,
    this.specialEffect,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('Turn $turn: $actor uses $action');
    if (target != null) {
      buffer.write(' on $target');
    }
    if (damage != null) {
      buffer.write(' dealing $damage damage');
      if (isCrit == true) buffer.write(' (CRIT!)');
    }
    if (specialEffect != null) {
      buffer.write(' [$specialEffect]');
    }
    return buffer.toString();
  }
}

/// 战斗结果
class BattleResult {
  final String winner;  // "TEAM_A", "TEAM_B", "DRAW"
  final int totalTurns;
  final List<BattleLog> logs;
  final List<MonsterCard> finalTeamA;
  final List<MonsterCard> finalTeamB;

  BattleResult({
    required this.winner,
    required this.totalTurns,
    required this.logs,
    required this.finalTeamA,
    required this.finalTeamB,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== BATTLE RESULT ===');
    buffer.writeln('Winner: $winner');
    buffer.writeln('Total Turns: $totalTurns');
    buffer.writeln('');
    buffer.writeln('--- Battle Log ---');
    for (final log in logs) {
      buffer.writeln(log.toString());
    }
    buffer.writeln('');
    buffer.writeln('--- Final Status ---');
    buffer.writeln('Team A:');
    for (final m in finalTeamA) {
      buffer.writeln('  ${m.name}: ${m.hp}/${m.maxHp} HP');
    }
    buffer.writeln('Team B:');
    for (final m in finalTeamB) {
      buffer.writeln('  ${m.name}: ${m.hp}/${m.maxHp} HP');
    }
    return buffer.toString();
  }
}
