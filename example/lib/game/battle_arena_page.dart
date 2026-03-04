// 战斗竞技场页面 - 带动画效果
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'battle_simulator.dart';
import 'models.dart';

class BattleArenaPage extends StatefulWidget {
  final List<MonsterCard> teamA;
  final List<MonsterCard> teamB;

  const BattleArenaPage({
    super.key,
    required this.teamA,
    required this.teamB,
  });

  @override
  State<BattleArenaPage> createState() => _BattleArenaPageState();
}

class _BattleArenaPageState extends State<BattleArenaPage>
    with TickerProviderStateMixin {
  late List<MonsterCard> _teamA;
  late List<MonsterCard> _teamB;
  
  // 战斗状态
  bool _isBattleRunning = false;
  bool _isPaused = false;
  int _currentTurn = 0;
  String _battleStatus = '准备战斗';
  
  // 动画状态
  int? _activeAttacker;
  int? _activeTarget;
  bool _isAttacking = false;
  int? _damageDealt;
  bool _isCritical = false;
  String? _actionText;
  
  // 战斗日志
  final List<BattleRound> _rounds = [];
  final ScrollController _logScrollController = ScrollController();
  
  // 速度控制
  double _speed = 1.0;
  Timer? _battleTimer;

  @override
  void initState() {
    super.initState();
    _teamA = widget.teamA.map((m) => m.copy()).toList();
    _teamB = widget.teamB.map((m) => m.copy()).toList();
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _startBattle() {
    setState(() {
      _isBattleRunning = true;
      _isPaused = false;
      _currentTurn = 1;
      _rounds.clear();
      _battleStatus = '第 1 回合';
    });
    
    // 使用微任务确保状态更新后再开始
    Future.microtask(() => _runBattleStep());
  }

  void _pauseBattle() {
    setState(() {
      _isPaused = !_isPaused;
      _battleStatus = _isPaused ? '战斗暂停' : '战斗继续';
    });
  }

  void _resetBattle() {
    _battleTimer?.cancel();
    setState(() {
      _teamA = widget.teamA.map((m) => m.copy()).toList();
      _teamB = widget.teamB.map((m) => m.copy()).toList();
      _isBattleRunning = false;
      _isPaused = false;
      _currentTurn = 0;
      _battleStatus = '准备战斗';
      _rounds.clear();
      _activeAttacker = null;
      _activeTarget = null;
      _isAttacking = false;
    });
  }

  void _runBattleStep() {
    if (!_isBattleRunning || _isPaused) return;

    // 检查战斗是否结束
    final result = _checkBattleResult();
    if (result != null) {
      setState(() {
        _battleStatus = result;
        _isBattleRunning = false;
      });
      return;
    }

    // 获取行动顺序
    final allMonsters = [..._teamA, ..._teamB];
    final actionOrder = _getActionOrder(allMonsters);
    
    if (actionOrder.isEmpty) {
      setState(() {
        _battleStatus = '战斗结束 - 无行动单位';
        _isBattleRunning = false;
      });
      return;
    }

    _executeTurn(actionOrder, allMonsters);
  }

  Future<void> _executeTurn(List<_ActionOrder> actionOrder, List<MonsterCard> allMonsters) async {
    for (final action in actionOrder) {
      if (!_isBattleRunning || _isPaused) return;

      final attacker = allMonsters[action.index];
      if (!attacker.isAlive) continue;

      // 跳过眩晕
      if (attacker.stunned) {
        setState(() {
          attacker.stunned = false;
          _actionText = '${attacker.name} 眩晕中，无法行动';
        });
        await _delay(1000);
        continue;
      }

      // 选择目标
      final isTeamA = action.index < _teamA.length;
      final enemies = isTeamA ? _teamB : _teamA;
      final target = _selectTarget(enemies);
      
      if (target == null) continue;

      // 执行攻击动画
      await _performAttack(attacker, target, action.index, 
          isTeamA ? _teamA.length + enemies.indexOf(target) : enemies.indexOf(target));

      // 检查目标死亡
      if (!target.isAlive) {
        await _performDeath(target);
      }

      // 检查战斗结束
      final result = _checkBattleResult();
      if (result != null) {
        setState(() {
          _battleStatus = result;
          _isBattleRunning = false;
        });
        return;
      }

      await _delay(500 ~/ _speed);
    }

    // 下一回合
    if (!_isBattleRunning || _isPaused) return;
    
    setState(() {
      _currentTurn++;
      _battleStatus = '第 $_currentTurn 回合';
    });

    // 延迟后执行下一回合
    await Future.delayed(Duration(milliseconds: (1000 ~/ _speed).toInt()));
    if (mounted && _isBattleRunning && !_isPaused) {
      _runBattleStep();
    }
  }

  Future<void> _performAttack(MonsterCard attacker, MonsterCard target, 
      int attackerIndex, int targetIndex) async {
    // 显示攻击者
    setState(() {
      _activeAttacker = attackerIndex;
      _actionText = '${attacker.name} 准备攻击';
    });
    await _delay(300);

    // 移动到目标
    setState(() {
      _activeTarget = targetIndex;
      _isAttacking = true;
      _actionText = '${attacker.name} → ${target.name}';
    });
    await _delay(200);

    // 计算伤害（简化版）
    final isSkill = attacker.currentCooldown == 0 && _randomBool();
    final skill = isSkill ? attacker.skill : attacker.normalAttack;
    
    if (isSkill) {
      attacker.currentCooldown = skill.cooldown;
    }

    // 计算伤害值
    final damage = _calculateDamage(attacker, target, skill);
    final isCrit = _randomCrit(attacker.critRate);
    final finalDamage = isCrit ? (damage * attacker.critDamage).toInt() : damage;

    // 应用伤害
    target.hp = (target.hp - finalDamage).clamp(0, target.maxHp);

    // 显示伤害
    setState(() {
      _damageDealt = finalDamage;
      _isCritical = isCrit;
      _actionText = isSkill ? '${attacker.name} 使用 ${skill.name}!' 
                            : '${attacker.name} 普通攻击';
    });

    // 添加战斗记录
    _rounds.add(BattleRound(
      turn: _currentTurn,
      attacker: attacker.name,
      target: target.name,
      action: skill.name,
      damage: finalDamage,
      isCrit: isCrit,
      targetHpLeft: target.hp,
    ));

    // 滚动日志
    _scrollToBottom();

    await _delay(800);

    // 重置动画状态
    setState(() {
      _isAttacking = false;
      _activeAttacker = null;
      _activeTarget = null;
      _damageDealt = null;
      _isCritical = false;
    });

    // 减少冷却
    if (attacker.currentCooldown > 0) {
      attacker.currentCooldown--;
    }
  }

  Future<void> _performDeath(MonsterCard monster) async {
    setState(() {
      _actionText = '${monster.name} 倒下了！';
    });
    await _delay(1000);
  }

  Future<void> _delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: (milliseconds / _speed).toInt()));
  }

  int _calculateDamage(MonsterCard attacker, MonsterCard defender, Skill skill) {
    final isPhysical = skill.type == DamageType.physical;
    final attack = isPhysical ? attacker.attack : attacker.magicAttack;
    final defense = isPhysical ? defender.physicalDefense : defender.magicDefense;
    
    final baseDamage = attack * skill.multiplier;
    final damageReduction = defense / (defense + 100);
    final damage = baseDamage * (1 - damageReduction);
    
    // 随机波动
    final variance = 0.9 + Random().nextDouble() * 0.2;
    return (damage * variance).toInt().clamp(1, 9999);
  }

  bool _randomCrit(double critRate) {
    return Random().nextDouble() < critRate;
  }

  bool _randomBool() {
    return Random().nextBool();
  }

  String? _checkBattleResult() {
    final teamAAlive = _teamA.any((m) => m.isAlive);
    final teamBAlive = _teamB.any((m) => m.isAlive);
    
    if (teamAAlive && !teamBAlive) return '蓝方胜利！';
    if (teamBAlive && !teamAAlive) return '红方胜利！';
    if (!teamAAlive && !teamBAlive) return '平局！';
    return null;
  }

  MonsterCard? _selectTarget(List<MonsterCard> enemies) {
    final aliveEnemies = enemies.where((m) => m.isAlive).toList();
    if (aliveEnemies.isEmpty) return null;
    aliveEnemies.sort((a, b) => a.hp.compareTo(b.hp));
    return aliveEnemies.first;
  }

  List<_ActionOrder> _getActionOrder(List<MonsterCard> monsters) {
    final order = <_ActionOrder>[];
    for (int i = 0; i < monsters.length; i++) {
      if (monsters[i].isAlive) {
        order.add(_ActionOrder(index: i, speed: monsters[i].speed));
      }
    }
    order.sort((a, b) => b.speed.compareTo(a.speed));
    return order;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('战斗竞技场'),
        actions: [
          // 战斗开始后才显示暂停/继续按钮
          if (_isBattleRunning)
            TextButton.icon(
              onPressed: _pauseBattle,
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, 
                  color: Colors.white),
              label: Text(_isPaused ? '继续' : '暂停', 
                  style: const TextStyle(color: Colors.white)),
            ),
          // 重置按钮始终显示
          IconButton(
            onPressed: _resetBattle,
            icon: const Icon(Icons.refresh),
            tooltip: '重置',
          ),
        ],
      ),
      body: Column(
        children: [
          // 状态栏
          _buildStatusBar(),
          
          // 战斗场地
          Expanded(
            child: Row(
              children: [
                // 蓝方队伍
                Expanded(child: _buildTeamColumn(_teamA, true)),
                
                // 中间战斗区域
                SizedBox(
                  width: 120,
                  child: Center(child: _buildBattleEffects()),
                ),
                
                // 红方队伍
                Expanded(child: _buildTeamColumn(_teamB, false)),
              ],
            ),
          ),
          
          // 战斗日志
          _buildBattleLog(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[900],
      child: Row(
        children: [
          // 回合数
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '回合 $_currentTurn',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // 战斗状态
          Expanded(
            child: Text(
              _battleStatus,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // 速度控制
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.white70),
              SizedBox(
                width: 120,
                child: Slider(
                  value: _speed,
                  min: 0.5,
                  max: 3.0,
                  divisions: 5,
                  label: '${_speed}x',
                  onChanged: (value) {
                    setState(() {
                      _speed = value;
                    });
                  },
                ),
              ),
              Text('${_speed}x', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamColumn(List<MonsterCard> team, bool isTeamA) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      color: isTeamA ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      child: Column(
        children: [
          // 队伍标识
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isTeamA ? Colors.blue : Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isTeamA ? '蓝方' : '红方',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 队员列表
          Expanded(
            child: ListView.builder(
              itemCount: team.length,
              itemBuilder: (context, index) {
                final monster = team[index];
                final globalIndex = isTeamA ? index : _teamA.length + index;
                final isActive = _activeAttacker == globalIndex || 
                                _activeTarget == globalIndex;
                final isAttacking = _activeAttacker == globalIndex && _isAttacking;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: isAttacking 
                      ? (Matrix4.identity()..translate(isTeamA ? 30.0 : -30.0))
                      : Matrix4.identity(),
                  child: _buildMonsterCard(
                    monster, 
                    isActive,
                    _activeTarget == globalIndex && _damageDealt != null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterCard(MonsterCard monster, bool isActive, bool showDamage) {
    final hpPercent = monster.hp / monster.maxHp;
    Color hpColor;
    if (hpPercent > 0.6) {
      hpColor = Colors.green;
    } else if (hpPercent > 0.3) {
      hpColor = Colors.orange;
    } else {
      hpColor = Colors.red;
    }

    return Card(
      elevation: isActive ? 8 : 2,
      color: monster.isAlive 
          ? (isActive ? Colors.yellow.withOpacity(0.2) : null)
          : Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    monster.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: monster.isAlive ? null : TextDecoration.lineThrough,
                      color: monster.isAlive ? null : Colors.grey,
                    ),
                  ),
                ),
                if (showDamage)
                  _buildDamagePopup(),
              ],
            ),
            const SizedBox(height: 8),
            
            // HP条
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // 背景
                    Container(
                      height: 20,
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    // 血量前景 - 使用 FractionallySizedBox 确保按比例填充
                    FractionallySizedBox(
                      widthFactor: hpPercent.clamp(0.0, 1.0),
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: hpColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    // 文字
                    Center(
                      child: Text(
                        '${monster.hp}/${monster.maxHp}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }
            ),
            const SizedBox(height: 8),
            
            // 关键属性
            Wrap(
              spacing: 8,
              children: [
                _buildMiniStat(Icons.flash_on, Colors.orange, monster.attack.toString()),
                _buildMiniStat(Icons.shield, Colors.blue, monster.physicalDefense.toString()),
                _buildMiniStat(Icons.speed, Colors.green, monster.speed.toString()),
              ],
            ),
            
            // 冷却指示
            if (monster.currentCooldown > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text('冷却 ${monster.currentCooldown}'),
                  backgroundColor: Colors.purple.withOpacity(0.2),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamagePopup() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * value),
          child: Opacity(
            opacity: 1 - value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isCritical ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${_isCritical ? '暴击! ' : ''}-$_damageDealt',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(IconData icon, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startBattle,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green, Colors.greenAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow,
              size: 40,
              color: Colors.white,
            ),
            Text(
              '开始',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleEffects() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 如果战斗未开始，显示开始按钮；否则显示 VS 标志
        if (!_isBattleRunning)
          _buildStartButton()
        else
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        
        // 行动文字
        if (_actionText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _actionText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildBattleLog() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: const Row(
              children: [
                Icon(Icons.history, size: 16),
                SizedBox(width: 4),
                Text(
                  '战斗记录',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _logScrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _rounds.length,
              itemBuilder: (context, index) {
                final round = _rounds[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          'T${round.turn}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${round.attacker} ${round.action} → ${round.target}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '-${round.damage}${round.isCrit ? " ⚡" : ""}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: round.isCrit ? Colors.red : Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${round.targetHpLeft}HP)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BattleRound {
  final int turn;
  final String attacker;
  final String target;
  final String action;
  final int damage;
  final bool isCrit;
  final int targetHpLeft;

  BattleRound({
    required this.turn,
    required this.attacker,
    required this.target,
    required this.action,
    required this.damage,
    required this.isCrit,
    required this.targetHpLeft,
  });
}

class _ActionOrder {
  final int index;
  final int speed;
  
  _ActionOrder({required this.index, required this.speed});
}
