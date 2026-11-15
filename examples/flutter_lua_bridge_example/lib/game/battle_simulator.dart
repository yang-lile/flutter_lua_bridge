// 战斗模拟器
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import 'models.dart';

/// 战斗模拟器
class BattleSimulator {
  final LuaRuntime lua;
  int _turn = 0;
  final List<BattleLog> _logs = [];

  BattleSimulator(this.lua);

  /// 模拟一场战斗
  BattleResult simulate(List<MonsterCard> teamA, List<MonsterCard> teamB, {int maxTurns = 100}) {
    _turn = 0;
    _logs.clear();

    // 创建怪物副本（避免修改原始数据）
    final monstersA = teamA.map((m) => m.copy()).toList();
    final monstersB = teamB.map((m) => m.copy()).toList();

    // 触发战斗开始时的被动技能
    _triggerBattleStartPassives(monstersA);
    _triggerBattleStartPassives(monstersB);

    // 战斗主循环
    while (_turn < maxTurns) {
      _turn++;

      // 获取行动顺序
      final allMonsters = [...monstersA, ...monstersB];
      final actionOrder = _getActionOrder(allMonsters);

      for (final action in actionOrder) {
        final monster = allMonsters[action.index];

        // 跳过已死亡的怪物
        if (!monster.isAlive) continue;

        // 跳过眩晕的怪物
        if (monster.stunned) {
          _logs.add(BattleLog(turn: _turn, actor: monster.name, action: 'stunned', specialEffect: 'Cannot act'));
          monster.stunned = false; // 眩晕结束
          continue;
        }

        // 触发回合开始被动
        _triggerTurnStartPassives(monster);

        // 确定敌友
        final isTeamA = action.index < monstersA.length;
        final allies = isTeamA ? monstersA : monstersB;
        final enemies = isTeamA ? monstersB : monstersA;

        // 选择目标和行动
        final target = _selectTarget(enemies);
        if (target == null) continue; // 没有可攻击的目标

        // 决定使用普攻还是技能
        final useSkill = monster.currentCooldown == 0 && _shouldUseSkill(monster, target);

        if (useSkill) {
          _executeSkill(monster, target, allies, enemies);
          monster.currentCooldown = monster.skill.cooldown;
        } else {
          _executeNormalAttack(monster, target);
        }

        // 减少冷却
        if (monster.currentCooldown > 0) {
          monster.currentCooldown--;
        }

        // 检查战斗结果
        final result = _checkBattleResult(monstersA, monstersB);
        if (result != 'ONGOING') {
          return BattleResult(
            winner: result,
            totalTurns: _turn,
            logs: List.unmodifiable(_logs),
            finalTeamA: monstersA,
            finalTeamB: monstersB,
          );
        }
      }
    }

    // 达到最大回合数，判定为平局
    return BattleResult(
      winner: 'DRAW',
      totalTurns: _turn,
      logs: List.unmodifiable(_logs),
      finalTeamA: monstersA,
      finalTeamB: monstersB,
    );
  }

  /// 获取行动顺序
  List<_ActionOrder> _getActionOrder(List<MonsterCard> monsters) {
    final order = <_ActionOrder>[];

    for (int i = 0; i < monsters.length; i++) {
      if (monsters[i].isAlive) {
        order.add(_ActionOrder(index: i, speed: monsters[i].speed));
      }
    }

    // 按速度降序排序
    order.sort((a, b) => b.speed.compareTo(a.speed));
    return order;
  }

  /// 选择目标（优先选择血量最少的）
  MonsterCard? _selectTarget(List<MonsterCard> enemies) {
    final aliveEnemies = enemies.where((m) => m.isAlive).toList();
    if (aliveEnemies.isEmpty) return null;

    // 简单策略：选择血量最少的
    aliveEnemies.sort((a, b) => a.hp.compareTo(b.hp));
    return aliveEnemies.first;
  }

  /// 决定是否使用技能（简单策略：血量低于50%或有冷却好的强力技能）
  bool _shouldUseSkill(MonsterCard monster, MonsterCard target) {
    // 如果是治疗技能且队友血量低，优先使用
    if (monster.skill.type == DamageType.heal) {
      return true;
    }

    // 如果目标血量低，使用技能收割
    if (target.hpPercent < 0.3) {
      return true;
    }

    // 随机决定是否使用技能
    return DateTime.now().millisecond % 2 == 0;
  }

  /// 执行普通攻击
  void _executeNormalAttack(MonsterCard attacker, MonsterCard defender) {
    final skill = attacker.normalAttack;

    // 调用 Lua 计算伤害
    final damage = _calculateDamage(attacker, defender, skill);

    // 应用伤害
    _applyDamage(defender, damage.damage);

    _logs.add(
      BattleLog(
        turn: _turn,
        actor: attacker.name,
        action: skill.name,
        target: defender.name,
        damage: damage.damage,
        isCrit: damage.isCrit,
      ),
    );

    // 检查死亡
    if (!defender.isAlive) {
      _logs.add(BattleLog(turn: _turn, actor: defender.name, action: 'defeated', specialEffect: 'K.O.'));
    }
  }

  /// 执行技能
  void _executeSkill(MonsterCard caster, MonsterCard target, List<MonsterCard> allies, List<MonsterCard> enemies) {
    final skill = caster.skill;

    if (skill.type == DamageType.heal) {
      // 治疗技能
      _executeHealSkill(caster, allies, skill);
    } else {
      // 伤害技能
      final damage = _calculateDamage(caster, target, skill);

      // 处理无视防御
      int finalDamage = damage.damage;
      if (skill.ignoreDefense != null && skill.type == DamageType.physical) {
        // 重新计算，无视部分防御
        finalDamage = _calculateDamageWithIgnoreDefense(caster, target, skill, skill.ignoreDefense!);
      }

      _applyDamage(target, finalDamage);

      _logs.add(
        BattleLog(
          turn: _turn,
          actor: caster.name,
          action: skill.name,
          target: target.name,
          damage: finalDamage,
          isCrit: damage.isCrit,
        ),
      );

      if (!target.isAlive) {
        _logs.add(BattleLog(turn: _turn, actor: target.name, action: 'defeated', specialEffect: 'K.O.'));
      }
    }
  }

  /// 执行治疗技能
  void _executeHealSkill(MonsterCard caster, List<MonsterCard> allies, Skill skill) {
    if (skill.target == 'ALL_ALLY') {
      // 群体治疗
      for (final ally in allies.where((m) => m.isAlive)) {
        final healAmount = _calculateHeal(caster, skill);
        final oldHp = ally.hp;
        ally.hp = (ally.hp + healAmount).clamp(0, ally.maxHp);
        final actualHeal = ally.hp - oldHp;

        _logs.add(
          BattleLog(
            turn: _turn,
            actor: caster.name,
            action: skill.name,
            target: ally.name,
            specialEffect: 'Heal $actualHeal',
          ),
        );
      }
    }
  }

  /// 调用 formulas.lua 中的公式函数
  List<Object?> _callFormula(String name, List<Object?> arguments) {
    final formulas = lua['_FORMULAS'];
    if (formulas is! LuaTable) {
      throw LuaBridgeException('formulas are not loaded');
    }
    try {
      return formulas.call(name, arguments);
    } finally {
      formulas.release();
    }
  }

  /// 计算伤害
  _DamageResult _calculateDamage(MonsterCard attacker, MonsterCard defender, Skill skill) {
    final funcName = skill.type == DamageType.physical ? 'calculatePhysicalDamage' : 'calculateMagicDamage';
    try {
      // 参数: attacker, defender, multiplier；返回值: damage, isCrit
      final results = _callFormula(funcName, [
        _monsterTable(attacker),
        _monsterTable(defender),
        skill.multiplier,
      ]);
      final damage = results.isNotEmpty ? results[0] : null;
      return _DamageResult(
        damage: damage is num ? damage.toInt() : 0,
        isCrit: results.length > 1 && results[1] == true,
      );
    } on LuaBridgeException {
      // 公式调用失败，使用默认计算
      return _DamageResult(
        damage: _defaultDamageCalculation(attacker, defender, skill),
        isCrit: false,
      );
    }
  }

  /// 带无视防御的伤害计算
  int _calculateDamageWithIgnoreDefense(MonsterCard attacker, MonsterCard defender, Skill skill, double ignorePercent) {
    // 临时修改防御值
    final originalDefense = defender.physicalDefense;
    defender.physicalDefense = (defender.physicalDefense * (1 - ignorePercent)).toInt();

    final result = _calculateDamage(attacker, defender, skill);

    // 恢复防御值
    defender.physicalDefense = originalDefense;

    return result.damage;
  }

  /// 计算治疗量
  int _calculateHeal(MonsterCard caster, Skill skill) {
    final base = skill.healBase ?? 100;
    try {
      final results = _callFormula('calculateHeal', [
        _monsterTable(caster),
        base.toDouble(),
      ]);
      final heal = results.isNotEmpty ? results[0] : null;
      return heal is num ? heal.toInt() : base;
    } on LuaBridgeException {
      return base;
    }
  }

  /// 默认伤害计算（当 Lua 调用失败时）
  int _defaultDamageCalculation(MonsterCard attacker, MonsterCard defender, Skill skill) {
    final isPhysical = skill.type == DamageType.physical;
    final attack = isPhysical ? attacker.attack : attacker.magicAttack;
    final defense = isPhysical ? defender.physicalDefense : defender.magicDefense;

    final baseDamage = attack * skill.multiplier;
    final damageReduction = defense / (defense + (isPhysical ? 100 : 80));
    final damage = baseDamage * (1 - damageReduction);

    return damage.toInt();
  }

  /// 应用伤害
  void _applyDamage(MonsterCard target, int damage) {
    // 应用伤害减免
    final actualDamage = (damage * (1 - target.damageReduction)).toInt();
    target.hp = (target.hp - actualDamage).clamp(0, target.maxHp);
  }

  /// 怪物属性；作为参数传给 Lua 时会成为一张新表
  Map<String, Object> _monsterTable(MonsterCard monster) => {
    'name': monster.name,
    'hp': monster.hp.toDouble(),
    'maxHp': monster.maxHp.toDouble(),
    'attack': monster.attack.toDouble(),
    'magicAttack': monster.magicAttack.toDouble(),
    'physicalDefense': monster.physicalDefense.toDouble(),
    'magicDefense': monster.magicDefense.toDouble(),
    'speed': monster.speed.toDouble(),
    'critRate': monster.critRate,
    'critDamage': monster.critDamage,
    'magicCritRate': monster.magicCritRate,
  };

  /// 检查战斗结果
  String _checkBattleResult(List<MonsterCard> teamA, List<MonsterCard> teamB) {
    final teamAAlive = teamA.any((m) => m.isAlive);
    final teamBAlive = teamB.any((m) => m.isAlive);

    if (teamAAlive && !teamBAlive) return 'TEAM_A';
    if (teamBAlive && !teamAAlive) return 'TEAM_B';
    if (!teamAAlive && !teamBAlive) return 'DRAW';
    return 'ONGOING';
  }

  /// 触发战斗开始时的被动
  void _triggerBattleStartPassives(List<MonsterCard> team) {
    for (final monster in team) {
      // 这里简化处理，实际应该调用 Lua 中的被动函数
      if (monster.name == '暗影刺客') {
        monster.stealth = true;
        monster.damageReduction = 0.5;
        _logs.add(BattleLog(turn: 0, actor: monster.name, action: 'passive', specialEffect: 'Stealth activated'));
      }
    }
  }

  /// 触发回合开始时的被动
  void _triggerTurnStartPassives(MonsterCard monster) {
    // 牧师被动：每回合回血
    if (monster.name == '圣光牧师') {
      final heal = (monster.maxHp * 0.05).toInt();
      monster.hp = (monster.hp + heal).clamp(0, monster.maxHp);
      _logs.add(BattleLog(turn: _turn, actor: monster.name, action: 'passive', specialEffect: 'Heal $heal'));
    }

    // 战士被动：低血量狂暴
    if (monster.name == '狂暴战士' && !monster.berserkActive && monster.hpPercent < 0.3) {
      monster.attack = (monster.attack * 1.5).toInt();
      monster.berserkActive = true;
      _logs.add(BattleLog(turn: _turn, actor: monster.name, action: 'passive', specialEffect: 'Berserk activated!'));
    }
  }
}

class _ActionOrder {
  final int index;
  final int speed;

  _ActionOrder({required this.index, required this.speed});
}

class _DamageResult {
  final int damage;
  final bool isCrit;

  _DamageResult({required this.damage, required this.isCrit});
}
