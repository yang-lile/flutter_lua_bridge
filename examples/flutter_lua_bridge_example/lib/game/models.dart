// 游戏数据模型
//
// 卡牌数据来自 Lua（lua/src/cards.tl），通过生成的 CardApi 以 CardSpec 的
// 形式传到 Dart；MonsterCard 是它在一场战斗里的可变状态。
import '../bridge/battle.dart';

export '../bridge/battle.dart'
    show CardSpec, DamageType, PassiveSpec, Rarity, SkillSpec, SkillTarget;

extension RarityLabel on Rarity {
  String get label => switch (this) {
    Rarity.n => 'N',
    Rarity.r => 'R',
    Rarity.sr => 'SR',
    Rarity.ssr => 'SSR',
    Rarity.ur => 'UR',
  };
}

/// 怪物卡牌
class MonsterCard {
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
    required this.passive,
  });

  /// 由 Lua 卡牌定义创建
  factory MonsterCard.fromSpec(CardSpec spec) {
    final stats = spec.stats;
    return MonsterCard(
      id: spec.id,
      name: spec.name,
      description: spec.description,
      rarity: spec.rarity,
      maxHp: stats.hp,
      hp: stats.hp,
      attack: stats.attack,
      magicAttack: stats.magicAttack,
      physicalDefense: stats.physicalDefense,
      magicDefense: stats.magicDefense,
      speed: stats.speed,
      critRate: stats.critRate,
      critDamage: stats.critDamage,
      magicCritRate: stats.magicCritRate,
      normalAttack: spec.normalAttack,
      skill: spec.skill,
      passive: spec.passive,
    );
  }

  final String id;
  String name;
  String description;
  final Rarity rarity;

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

  // 技能
  final SkillSpec normalAttack;
  final SkillSpec skill;
  final PassiveSpec? passive;

  // 战斗状态
  int currentCooldown = 0;
  bool stunned = false;
  double damageReduction = 0.0;

  /// 已触发过的一次性效果（如狂暴、救赎）
  final Set<String> spentEffects = {};

  /// 创建副本（用于战斗；战斗状态不复制）
  MonsterCard copy() => MonsterCard(
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
    passive: passive,
  );

  /// 传给 Lua 公式的快照
  Fighter toFighter({int? physicalDefense}) => Fighter(
    name: name,
    hp: hp,
    maxHp: maxHp,
    attack: attack,
    magicAttack: magicAttack,
    physicalDefense: physicalDefense ?? this.physicalDefense,
    magicDefense: magicDefense,
    speed: speed,
    critRate: critRate,
    critDamage: critDamage,
    magicCritRate: magicCritRate,
  );

  bool get isAlive => hp > 0;

  double get hpPercent => hp / maxHp;

  @override
  String toString() => '$name [HP: $hp/$maxHp]';
}

enum BattleEventKind { attack, skill, heal, effect, stunned, defeated }

/// 战斗中的一步。下标指向 `[...teamA, ...teamB]`。
class BattleEvent {
  const BattleEvent({
    required this.turn,
    required this.kind,
    required this.actor,
    this.target,
    this.action,
    this.amount,
    this.critical = false,
    this.note,
  });

  final int turn;
  final BattleEventKind kind;
  final int actor;
  final int? target;

  /// 技能名
  final String? action;

  /// 伤害或治疗量
  final int? amount;
  final bool critical;

  /// 被动、特效等说明
  final String? note;

  @override
  String toString() =>
      'T$turn ${kind.name} $actor'
      '${target == null ? '' : '->$target'}'
      '${action == null ? '' : ' $action'}'
      '${amount == null ? '' : ' $amount'}'
      '${critical ? ' crit' : ''}'
      '${note == null ? '' : ' [$note]'}';
}

enum BattleOutcome { teamA, teamB, draw }

/// 战斗结果
class BattleResult {
  const BattleResult({
    required this.outcome,
    required this.turns,
    required this.events,
  });

  final BattleOutcome outcome;
  final int turns;
  final List<BattleEvent> events;
}
