// 战斗模拟器
//
// 回合流程在 Dart；伤害、治疗和出手顺序交给 BattleFormulas（Lua 的三档
// 绑定之一，或 Dart 参考实现），卡牌被动和技能特效交给 Lua 的 CardApi。
// 所有随机数都由带种子的 Random 产生并作为参数传进去，所以同一个种子在
// 任何一种公式实现下都打出完全相同的战斗。
import 'dart:math';

import '../bridge/battle.dart';
import 'game_scripts.dart';
import 'models.dart';

class BattleSimulator {
  BattleSimulator({
    required this.scripts,
    required this.formulas,
    required this.teamA,
    required this.teamB,
    int seed = 0,
    this.maxTurns = 100,
  }) : _random = Random(seed);

  final GameScripts scripts;
  final BattleFormulas formulas;

  /// 双方队伍；战斗直接修改这些对象。
  final List<MonsterCard> teamA;
  final List<MonsterCard> teamB;
  final int maxTurns;
  final Random _random;

  int turn = 0;
  BattleOutcome? outcome;

  var _started = false;
  var _order = const <int>[];
  var _cursor = 0;

  List<MonsterCard> get fighters => [...teamA, ...teamB];

  /// 执行下一个出手者的整个行动，返回它产生的事件（跳过时为空）。
  /// 战斗结束后返回 null。
  List<BattleEvent>? step() {
    if (!_started) {
      _started = true;
      final events = <BattleEvent>[];
      for (final card in fighters) {
        if (card.passive?.trigger == PassiveTrigger.battleStart) {
          _apply(
            scripts.passive(card, PassiveTrigger.battleStart),
            card,
            card,
            events,
          );
        }
      }
      return events;
    }
    if (outcome != null) return null;
    final all = fighters;
    if (_cursor >= _order.length) {
      if (turn >= maxTurns) {
        outcome = BattleOutcome.draw;
        return null;
      }
      turn++;
      _order = formulas.actionOrder([for (final m in all) m.toFighter()]);
      _cursor = 0;
    }
    final actor = all[_order[_cursor++]];
    final events = <BattleEvent>[];
    if (!actor.isAlive) return events;
    if (actor.stunned) {
      actor.stunned = false;
      events.add(
        BattleEvent(
          turn: turn,
          kind: BattleEventKind.stunned,
          actor: all.indexOf(actor),
        ),
      );
      return events;
    }
    if (actor.passive?.trigger == PassiveTrigger.turnStart) {
      _apply(
        scripts.passive(actor, PassiveTrigger.turnStart),
        actor,
        actor,
        events,
      );
    }

    final onTeamA = teamA.contains(actor);
    final allies = onTeamA ? teamA : teamB;
    final enemies = onTeamA ? teamB : teamA;
    final target = _lowestHp(enemies);
    if (target != null) {
      final skill = actor.skill;
      final useSkill =
          actor.currentCooldown == 0 &&
          (skill.damageType == DamageType.heal ||
              target.hpPercent < 0.3 ||
              _random.nextBool());
      if (!useSkill) {
        _hit(actor, target, actor.normalAttack, isSkill: false, events);
      } else if (skill.damageType == DamageType.heal) {
        _heal(actor, allies, skill, events);
      } else {
        _hit(actor, target, skill, isSkill: true, events);
      }
      if (useSkill) actor.currentCooldown = skill.cooldown;
      if (actor.currentCooldown > 0) actor.currentCooldown--;
    }

    final aAlive = teamA.any((m) => m.isAlive);
    final bAlive = teamB.any((m) => m.isAlive);
    if (!aAlive || !bAlive) {
      outcome = aAlive
          ? BattleOutcome.teamA
          : bAlive
          ? BattleOutcome.teamB
          : BattleOutcome.draw;
    }
    return events;
  }

  /// 一次跑完整场战斗
  BattleResult run() {
    final events = <BattleEvent>[];
    for (var step = this.step(); step != null; step = this.step()) {
      events.addAll(step);
    }
    return BattleResult(outcome: outcome!, turns: turn, events: events);
  }

  MonsterCard? _lowestHp(List<MonsterCard> team) {
    MonsterCard? lowest;
    for (final card in team) {
      if (card.isAlive && (lowest == null || card.hp < lowest.hp)) {
        lowest = card;
      }
    }
    return lowest;
  }

  void _hit(
    MonsterCard actor,
    MonsterCard target,
    SkillSpec spec,
    List<BattleEvent> events, {
    required bool isSkill,
  }) {
    final all = fighters;
    final roll = Roll(
      crit: _random.nextDouble(),
      variance: _random.nextDouble(),
    );
    final ignore = spec.ignoreDefense;
    final defender = spec.damageType == DamageType.physical && ignore != null
        ? target.toFighter(
            physicalDefense: (target.physicalDefense * (1 - ignore)).toInt(),
          )
        : target.toFighter();
    final damage = spec.damageType == DamageType.physical
        ? formulas.physicalDamage(
            actor.toFighter(),
            defender,
            spec.multiplier,
            roll,
          )
        : formulas.magicDamage(
            actor.toFighter(),
            defender,
            spec.multiplier,
            roll,
          );
    final dealt = (damage.amount * (1 - target.damageReduction)).toInt();
    target.hp = (target.hp - dealt).clamp(0, target.maxHp);
    events.add(
      BattleEvent(
        turn: turn,
        kind: isSkill ? BattleEventKind.skill : BattleEventKind.attack,
        actor: all.indexOf(actor),
        target: all.indexOf(target),
        action: spec.name,
        amount: dealt,
        critical: damage.critical,
      ),
    );
    if (isSkill) {
      final effectRoll = _random.nextDouble();
      if (target.isAlive) {
        _apply(
          scripts.skillEffect(actor, target, effectRoll),
          actor,
          target,
          events,
        );
      }
    }
    if (!target.isAlive) {
      events.add(
        BattleEvent(
          turn: turn,
          kind: BattleEventKind.defeated,
          actor: all.indexOf(target),
        ),
      );
      return;
    }
    // 队友生命过低时触发的被动（圣光牧师的救赎）
    final team = teamA.contains(target) ? teamA : teamB;
    for (final ally in team) {
      if (ally.isAlive && ally.passive?.trigger == PassiveTrigger.allyLowHp) {
        _apply(
          scripts.passive(ally, PassiveTrigger.allyLowHp, target: target),
          ally,
          target,
          events,
        );
      }
    }
  }

  void _heal(
    MonsterCard actor,
    List<MonsterCard> allies,
    SkillSpec skill,
    List<BattleEvent> events,
  ) {
    final all = fighters;
    for (final ally in allies) {
      if (!ally.isAlive) continue;
      final amount = formulas.heal(actor.toFighter(), skill.healBase ?? 100);
      final before = ally.hp;
      ally.hp = (ally.hp + amount).clamp(0, ally.maxHp);
      events.add(
        BattleEvent(
          turn: turn,
          kind: BattleEventKind.heal,
          actor: all.indexOf(actor),
          target: all.indexOf(ally),
          action: skill.name,
          amount: ally.hp - before,
        ),
      );
    }
  }

  void _apply(
    Effect? effect,
    MonsterCard owner,
    MonsterCard target,
    List<BattleEvent> events,
  ) {
    if (effect == null) return;
    if (effect.once && !owner.spentEffects.add(effect.note)) return;
    if (effect.heal > 0) {
      target.hp = (target.hp + effect.heal).clamp(0, target.maxHp);
    }
    if (effect.attackScale != 1.0) {
      target.attack = (target.attack * effect.attackScale).toInt();
    }
    if (effect.damageReduction > 0) {
      target.damageReduction = effect.damageReduction;
    }
    if (effect.stun) target.stunned = true;
    final all = fighters;
    events.add(
      BattleEvent(
        turn: turn,
        kind: BattleEventKind.effect,
        actor: all.indexOf(owner),
        target: all.indexOf(target),
        amount: effect.heal > 0 ? effect.heal : null,
        note: effect.note,
      ),
    );
  }
}
