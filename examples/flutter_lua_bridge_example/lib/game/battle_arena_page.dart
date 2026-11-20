// 战斗竞技场页面 - 带动画效果
//
// 每一步由 BattleSimulator 计算（公式来自所选的 BattleFormulas，被动和
// 技能特效来自 Lua 的 CardApi），页面只负责把事件播放成动画。
import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'battle_simulator.dart';
import 'battle_text.dart';
import 'formulas.dart';
import 'game_scripts.dart';
import 'models.dart';

class BattleArenaPage extends StatefulWidget {
  const BattleArenaPage({
    super.key,
    required this.scripts,
    required this.backend,
    required this.teamA,
    required this.teamB,
    required this.seed,
  });

  final GameScripts scripts;
  final FormulaBackend backend;
  final List<MonsterCard> teamA;
  final List<MonsterCard> teamB;

  /// 同一个种子重放同一场战斗（重置后也一样）
  final int seed;

  @override
  State<BattleArenaPage> createState() => _BattleArenaPageState();
}

class _BattleArenaPageState extends State<BattleArenaPage>
    with TickerProviderStateMixin {
  late BattleSimulator _simulator;
  List<MonsterCard> get _teamA => _simulator.teamA;
  List<MonsterCard> get _teamB => _simulator.teamB;

  // 战斗状态
  bool _isBattleRunning = false;
  bool _isPaused = false;
  bool _isLooping = false;
  int _currentTurn = 0;
  String _battleStatus = '';

  // 动画状态
  int? _activeAttacker;
  int? _activeTarget;
  bool _isAttacking = false;
  int? _damageDealt;
  bool _isCritical = false;
  String? _actionText;

  // 战斗日志
  final List<_LogLine> _rounds = [];
  final ScrollController _logScrollController = ScrollController();

  // 速度控制
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _simulator = _newSimulator();
  }

  BattleSimulator _newSimulator() => BattleSimulator(
    scripts: widget.scripts,
    formulas: widget.scripts.formulas(widget.backend),
    teamA: widget.teamA.map((m) => m.copy()).toList(),
    teamB: widget.teamB.map((m) => m.copy()).toList(),
    seed: widget.seed,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    if (_battleStatus.isEmpty) {
      _battleStatus = l10n.preparingForBattle;
    }
  }

  @override
  void dispose() {
    _isBattleRunning = false;
    _logScrollController.dispose();
    super.dispose();
  }

  void _startBattle() {
    if (_simulator.outcome != null) _resetBattle();
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isBattleRunning = true;
      _isPaused = false;
      _battleStatus = l10n.turnNumber(_simulator.turn);
    });
    _runBattle();
  }

  void _pauseBattle() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isPaused = !_isPaused;
      _battleStatus = _isPaused ? l10n.battlePaused : l10n.battleResumed;
    });
    if (!_isPaused) _runBattle();
  }

  void _resetBattle() {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _simulator = _newSimulator();
      _isBattleRunning = false;
      _isPaused = false;
      _currentTurn = 0;
      _battleStatus = l10n.preparingForBattle;
      _rounds.clear();
      _activeAttacker = null;
      _activeTarget = null;
      _isAttacking = false;
      _damageDealt = null;
      _actionText = null;
    });
  }

  /// 逐步执行模拟器并播放每个事件，直到结束、暂停或离开页面
  Future<void> _runBattle() async {
    if (_isLooping) return;
    _isLooping = true;
    final l10n = AppLocalizations.of(context)!;
    final simulator = _simulator;
    try {
      while (mounted &&
          _isBattleRunning &&
          !_isPaused &&
          identical(simulator, _simulator)) {
        final List<BattleEvent>? events;
        try {
          events = simulator.step();
        } on Exception catch (error) {
          setState(() {
            _battleStatus = l10n.formulaFailed('$error');
            _isBattleRunning = false;
          });
          return;
        }
        if (events == null) {
          setState(() {
            _battleStatus = switch (simulator.outcome!) {
              BattleOutcome.teamA => l10n.teamAWins,
              BattleOutcome.teamB => l10n.teamBWins,
              BattleOutcome.draw => l10n.draw,
            };
            _isBattleRunning = false;
            _actionText = null;
          });
          return;
        }
        if (simulator.turn != _currentTurn) {
          setState(() {
            _currentTurn = simulator.turn;
            _battleStatus = l10n.turnNumber(_currentTurn);
          });
        }
        for (final event in events) {
          if (!mounted || !identical(simulator, _simulator)) return;
          await _play(event);
        }
        await _delay(300);
      }
    } finally {
      _isLooping = false;
    }
  }

  Future<void> _play(BattleEvent event) async {
    final l10n = AppLocalizations.of(context)!;
    final fighters = _simulator.fighters;
    final actor = fighters[event.actor];
    _rounds.add(
      _LogLine(
        event.turn,
        describeEvent(l10n, event, fighters),
        damage:
            event.kind == BattleEventKind.attack ||
            event.kind == BattleEventKind.skill,
        critical: event.critical,
      ),
    );
    _scrollToBottom();
    switch (event.kind) {
      case BattleEventKind.attack || BattleEventKind.skill:
        final target = fighters[event.target!];
        setState(() {
          _activeAttacker = event.actor;
          _actionText = l10n.preparingAttack(actor.name);
        });
        await _delay(300);
        if (!mounted) return;
        setState(() {
          _activeTarget = event.target;
          _isAttacking = true;
          _actionText = l10n.attackArrow(actor.name, target.name);
        });
        await _delay(200);
        if (!mounted) return;
        setState(() {
          _damageDealt = event.amount;
          _isCritical = event.critical;
          _actionText = event.kind == BattleEventKind.skill
              ? l10n.usesSkill(actor.name, event.action ?? '')
              : l10n.normalAttackAction(actor.name);
        });
        await _delay(800);
      case BattleEventKind.heal || BattleEventKind.effect:
        setState(() {
          _activeAttacker = event.actor;
          _activeTarget = event.target;
          _actionText = describeEvent(l10n, event, fighters);
        });
        await _delay(700);
      case BattleEventKind.stunned || BattleEventKind.defeated:
        setState(() {
          _activeAttacker = event.actor;
          _actionText = describeEvent(l10n, event, fighters);
        });
        await _delay(800);
    }
    if (!mounted) return;
    setState(() {
      _isAttacking = false;
      _activeAttacker = null;
      _activeTarget = null;
      _damageDealt = null;
      _isCritical = false;
    });
  }

  Future<void> _delay(int milliseconds) async {
    await Future.delayed(
      Duration(milliseconds: (milliseconds / _speed).toInt()),
    );
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.battleArenaTitle} · ${widget.backend.label}'),
        actions: [
          // 战斗开始后才显示暂停/继续按钮
          if (_isBattleRunning)
            TextButton.icon(
              onPressed: _pauseBattle,
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              label: Text(
                _isPaused ? l10n.continueLabel : l10n.pauseLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          // 重置按钮始终显示
          IconButton(
            onPressed: _resetBattle,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.reset,
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
    final l10n = AppLocalizations.of(context)!;
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
              l10n.turnLabel(_currentTurn),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      color: isTeamA
          ? Colors.blue.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
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
              isTeamA ? l10n.teamBlue : l10n.teamRed,
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
                final isActive =
                    _activeAttacker == globalIndex ||
                    _activeTarget == globalIndex;
                final isAttacking =
                    _activeAttacker == globalIndex && _isAttacking;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: isAttacking
                      ? (Matrix4.identity()
                          ..translateByDouble(isTeamA ? 30.0 : -30.0, 0, 0, 1))
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

  Widget _buildMonsterCard(
    MonsterCard monster,
    bool isActive,
    bool showDamage,
  ) {
    final l10n = AppLocalizations.of(context)!;
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
          ? (isActive ? Colors.yellow.withValues(alpha: 0.2) : null)
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
                      decoration: monster.isAlive
                          ? null
                          : TextDecoration.lineThrough,
                      color: monster.isAlive ? null : Colors.grey,
                    ),
                  ),
                ),
                if (showDamage) _buildDamagePopup(),
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
              },
            ),
            const SizedBox(height: 8),

            // 关键属性
            Wrap(
              spacing: 8,
              children: [
                _buildMiniStat(
                  Icons.flash_on,
                  Colors.orange,
                  monster.attack.toString(),
                ),
                _buildMiniStat(
                  Icons.shield,
                  Colors.blue,
                  monster.physicalDefense.toString(),
                ),
                _buildMiniStat(
                  Icons.speed,
                  Colors.green,
                  monster.speed.toString(),
                ),
              ],
            ),

            // 冷却指示
            if (monster.currentCooldown > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Chip(
                  label: Text(l10n.cooldownTurnsShort(monster.currentCooldown)),
                  backgroundColor: Colors.purple.withValues(alpha: 0.2),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                '${_isCritical ? AppLocalizations.of(context)!.critLabel : ''}-$_damageDealt',
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
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    final l10n = AppLocalizations.of(context)!;
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
              color: Colors.green.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow, size: 40, color: Colors.white),
            Text(
              l10n.startBattle,
              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
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
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                l10n.vsLabel,
                style: const TextStyle(
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
    final l10n = AppLocalizations.of(context)!;
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
            child: Row(
              children: [
                const Icon(Icons.history, size: 16),
                const SizedBox(width: 4),
                Text(
                  l10n.battleRecord,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                          l10n.turnLabel(round.turn),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          round.text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: round.damage ? FontWeight.bold : null,
                            color: round.critical ? Colors.red : null,
                          ),
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

class _LogLine {
  const _LogLine(
    this.turn,
    this.text, {
    required this.damage,
    required this.critical,
  });

  final int turn;
  final String text;
  final bool damage;
  final bool critical;
}
