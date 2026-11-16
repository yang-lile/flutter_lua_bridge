// 游戏演示页面
//
// 卡牌、被动和技能特效来自 Lua（CardApi），伤害等公式由 BattleFormulas
// 计算；页面上的开关在 Dart 参考实现与 Lua 的 O1/O2/O3 三档绑定之间切换。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'battle_arena_page.dart';
import 'battle_simulator.dart';
import 'battle_text.dart';
import 'card_editor_page.dart';
import 'formulas.dart';
import 'game_scripts.dart';
import 'models.dart';
import 'safety_levels_page.dart';

class GameDemoPage extends StatefulWidget {
  const GameDemoPage({super.key});

  @override
  State<GameDemoPage> createState() => _GameDemoPageState();
}

class _GameDemoPageState extends State<GameDemoPage> {
  GameScripts? _scripts;
  FormulaBackend _backend = FormulaBackend.o1;
  bool _animate = true;
  bool _isLoading = true;

  // 最近一次瞬时模拟
  BattleResult? _lastResult;
  List<MonsterCard> _lastFighters = const [];
  int _lastTeamASize = 0;
  String _lastSummary = '';
  late String _status;
  bool _didInit = false;

  // 预加载的卡牌模板
  final Map<String, MonsterCard> _cardTemplates = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    if (!_didInit) {
      _status = l10n.initializing;
      _didInit = true;
      _initGame();
    }
  }

  @override
  void dispose() {
    _scripts?.close();
    super.dispose();
  }

  Future<void> _initGame() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      setState(() => _status = l10n.loadingLua);
      _scripts?.close();
      final scripts = _scripts = await GameScripts.load(rootBundle);
      if (!mounted) return;

      setState(() => _status = l10n.loadingCards);
      // 卡牌目录由 Lua 的 CardApi 提供，键为 id 的前缀（warrior_001 → warrior）
      final catalog = scripts.catalog();

      setState(() {
        _cardTemplates
          ..clear()
          ..addAll({
            for (final card in catalog) card.id.split('_').first: card,
          });
        _isLoading = false;
        _status = l10n.ready;
      });
    } catch (e, stack) {
      debugPrint('Error loading game: $e');
      debugPrint('Stack: $stack');
      setState(() {
        _status = '${l10n.errorPrefix}$e';
        _isLoading = false;
      });
    }
  }

  void _runBattle(String type) {
    debugPrint('Battle button clicked: $type');
    if (_cardTemplates.isEmpty) {
      debugPrint('Card templates is empty!');
      return;
    }

    List<MonsterCard> teamA;
    List<MonsterCard> teamB;

    switch (type) {
      case 'balanced':
        // 平衡对战：战士+法师 vs 战士+法师
        teamA = [
          _cardTemplates['warrior']!.copy(),
          _cardTemplates['mage']!.copy(),
        ];
        teamB = [
          _cardTemplates['warrior']!.copy(),
          _cardTemplates['mage']!.copy(),
        ];
        break;
      case 'healer_test':
        // 治疗测试：战士+治疗 vs 刺客+法师
        teamA = [
          _cardTemplates['warrior']!.copy(),
          _cardTemplates['healer']!.copy(),
        ];
        teamB = [
          _cardTemplates['assassin']!.copy(),
          _cardTemplates['mage']!.copy(),
        ];
        break;
      case 'speed_test':
        // 速度测试：双刺客 vs 双法师
        teamA = [
          _cardTemplates['assassin']!.copy(),
          _cardTemplates['assassin']!.copy(),
        ];
        teamB = [
          _cardTemplates['mage']!.copy(),
          _cardTemplates['mage']!.copy(),
        ];
        break;
      case 'tank_test':
        // 坦克测试：双战士 vs 双刺客
        teamA = [
          _cardTemplates['warrior']!.copy(),
          _cardTemplates['warrior']!.copy(),
          _cardTemplates['healer']!.copy(),
        ];
        teamB = [
          _cardTemplates['assassin']!.copy(),
          _cardTemplates['assassin']!.copy(),
        ];
        break;
      default:
        teamA = [_cardTemplates['warrior']!.copy()];
        teamB = [_cardTemplates['mage']!.copy()];
    }

    final scripts = _scripts!;
    final seed = DateTime.now().microsecondsSinceEpoch;
    if (_animate) {
      // 导航到战斗竞技场页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BattleArenaPage(
            scripts: scripts,
            backend: _backend,
            teamA: teamA,
            teamB: teamB,
            seed: seed,
          ),
        ),
      );
      return;
    }
    // 瞬时模拟：直接跑完整场，显示结果和耗时
    final l10n = AppLocalizations.of(context)!;
    final simulator = BattleSimulator(
      scripts: scripts,
      formulas: scripts.formulas(_backend),
      teamA: teamA,
      teamB: teamB,
      seed: seed,
    );
    final watch = Stopwatch()..start();
    try {
      final result = simulator.run();
      watch.stop();
      setState(() {
        _lastResult = result;
        _lastFighters = simulator.fighters;
        _lastTeamASize = teamA.length;
        _lastSummary = l10n.simulatedIn(
          _backend.label,
          (watch.elapsedMicroseconds / 1000).toStringAsFixed(2),
        );
      });
    } on Exception catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.formulaFailed('$error'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameDemoTitle)),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status),
                ],
              ),
            )
          : _status.startsWith(AppLocalizations.of(context)!.errorPrefix)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loadFailed,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _status = l10n.initializing;
                      });
                      _initGame();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.retry),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 可用卡牌展示
                      _buildCardSection(),
                      const SizedBox(height: 24),

                      // 公式实现开关
                      _buildBackendSection(),
                      const SizedBox(height: 24),

                      // 战斗场景选择
                      _buildBattleSection(),
                      const SizedBox(height: 24),

                      // 战斗结果
                      if (_lastResult != null) _buildResultSection(),

                      // 底部留白确保可滚动
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCardSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.availableCards,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cardTemplates.entries.map((entry) {
                final card = entry.value;
                return _buildCardChip(card);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardChip(MonsterCard card) {
    final rarityColor =
        {
          'N': Colors.grey,
          'R': Colors.blue,
          'SR': Colors.purple,
          'SSR': Colors.orange,
          'UR': Colors.red,
        }[card.rarity.label] ??
        Colors.grey;

    return GestureDetector(
      onTap: () => _showCardDetailDialog(card),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: rarityColor.withValues(alpha: 0.5), width: 2),
        ),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 稀有度标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rarityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  card.rarity.label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 名称
              Text(
                card.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 关键属性
              _buildMiniStat(Icons.favorite, Colors.red, card.maxHp.toString()),
              _buildMiniStat(
                Icons.flash_on,
                Colors.orange,
                card.attack.toString(),
              ),
              _buildMiniStat(Icons.speed, Colors.green, card.speed.toString()),
              const SizedBox(height: 8),
              // 编辑按钮
              SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  onPressed: () => _editCard(card),
                  icon: const Icon(Icons.edit, size: 14),
                  label: Text(
                    AppLocalizations.of(context)!.edit,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, Color color, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCardDetailDialog(MonsterCard card) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 稀有度
              Chip(
                label: Text(card.rarity.label),
                backgroundColor: {
                  'N': Colors.grey,
                  'R': Colors.blue,
                  'SR': Colors.purple,
                  'SSR': Colors.orange,
                  'UR': Colors.red,
                }[card.rarity.label]?.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
              // 描述
              Text(card.description),
              const Divider(),
              // 属性
              _buildDetailStat(
                l10n.hp,
                card.maxHp.toString(),
                Icons.favorite,
                Colors.red,
              ),
              _buildDetailStat(
                l10n.attack,
                card.attack.toString(),
                Icons.flash_on,
                Colors.orange,
              ),
              _buildDetailStat(
                l10n.magicAttack,
                card.magicAttack.toString(),
                Icons.auto_fix_high,
                Colors.purple,
              ),
              _buildDetailStat(
                l10n.physicalDefense,
                card.physicalDefense.toString(),
                Icons.shield,
                Colors.blue,
              ),
              _buildDetailStat(
                l10n.magicDefense,
                card.magicDefense.toString(),
                Icons.shield_moon,
                Colors.indigo,
              ),
              _buildDetailStat(
                l10n.speed,
                card.speed.toString(),
                Icons.speed,
                Colors.green,
              ),
              _buildDetailStat(
                l10n.critRate,
                '${(card.critRate * 100).toInt()}%',
                Icons.add_alert,
                Colors.yellow.shade700,
              ),
              _buildDetailStat(
                l10n.critDamage,
                '${card.critDamage}x',
                Icons.trending_up,
                Colors.redAccent,
              ),
              const Divider(),
              // 技能
              Text(
                l10n.skills,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(
                  Icons.sports_martial_arts,
                  color: Colors.orange,
                ),
                title: Text(card.normalAttack.name),
                subtitle: Text(card.normalAttack.description),
                trailing: Text(
                  '${(card.normalAttack.multiplier * 100).toInt()}%',
                ),
                dense: true,
              ),
              ListTile(
                leading: const Icon(Icons.auto_fix_high, color: Colors.purple),
                title: Text(card.skill.name),
                subtitle: Text(
                  '${card.skill.description}\n${l10n.cooldownTurns(card.skill.cooldown)}',
                ),
                trailing: Text('${(card.skill.multiplier * 100).toInt()}%'),
                dense: true,
                isThreeLine: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editCard(card);
            },
            icon: const Icon(Icons.edit),
            label: Text(l10n.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _editCard(MonsterCard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardEditorPage(
          card: card,
          onSave: (updatedCard) {
            setState(() {
              // 更新卡牌模板
              for (final entry in _cardTemplates.entries) {
                if (entry.value.id == card.id) {
                  _cardTemplates[entry.key] = updatedCard;
                  break;
                }
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildBackendSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.formulaBackend,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.formulaBackendHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<FormulaBackend>(
              segments: [
                for (final backend in FormulaBackend.values)
                  ButtonSegment(
                    value: backend,
                    label: Text(backend.label),
                    tooltip: backend.description,
                  ),
              ],
              selected: {_backend},
              onSelectionChanged: (selection) =>
                  setState(() => _backend = selection.single),
            ),
            const SizedBox(height: 8),
            Text(_backend.description),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.animateBattle),
              subtitle: Text(l10n.instantBattleHint),
              value: _animate,
              onChanged: (value) => setState(() => _animate = value),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.speed),
              title: Text(l10n.safetyLevels),
              subtitle: Text(l10n.safetyLevelsSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafetyLevelsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleSection() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectBattleScene,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBattleButton(
                  l10n.balancedBattle,
                  'balanced',
                  Colors.blue,
                ),
                _buildBattleButton(
                  l10n.healerTest,
                  'healer_test',
                  Colors.green,
                ),
                _buildBattleButton(l10n.speedTest, 'speed_test', Colors.orange),
                _buildBattleButton(l10n.tankTest, 'tank_test', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleButton(String label, String type, Color color) {
    return Material(
      child: InkWell(
        onTap: () {
          debugPrint('Button tapped: $type');
          _runBattle(type);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_kabaddi, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final l10n = AppLocalizations.of(context)!;
    final result = _lastResult!;
    final (color, label) = switch (result.outcome) {
      BattleOutcome.teamA => (Colors.blue, l10n.teamAWins),
      BattleOutcome.teamB => (Colors.red, l10n.teamBWins),
      BattleOutcome.draw => (Colors.grey, l10n.draw),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.battleResult,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.totalTurns(result.turns)),
            Text(_lastSummary),
            const SizedBox(height: 16),

            // 最终状态
            Row(
              children: [
                Expanded(
                  child: _buildTeamStatus(
                    l10n.teamA,
                    _lastFighters.sublist(0, _lastTeamASize),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamStatus(
                    l10n.teamB,
                    _lastFighters.sublist(_lastTeamASize),
                    Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 战斗日志
            ExpansionTile(
              title: Text(l10n.battleLogs),
              children: [
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: result.events.length,
                    itemBuilder: (context, index) {
                      final event = result.events[index];
                      final defeated = event.kind == BattleEventKind.defeated;
                      return ListTile(
                        dense: true,
                        title: Text(
                          'T${event.turn} '
                          '${describeEvent(l10n, event, _lastFighters)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: defeated
                                ? Colors.red
                                : event.critical
                                ? Colors.orange
                                : null,
                            fontWeight: defeated ? FontWeight.bold : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamStatus(String title, List<MonsterCard> team, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 8),
        ...team.map((m) {
          final isAlive = m.isAlive;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  isAlive ? Icons.favorite : Icons.favorite_border,
                  color: isAlive ? Colors.red : Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    m.name,
                    style: TextStyle(
                      decoration: isAlive ? null : TextDecoration.lineThrough,
                      color: isAlive ? null : Colors.grey,
                    ),
                  ),
                ),
                Text(
                  '${m.hp}/${m.maxHp}',
                  style: TextStyle(
                    fontSize: 12,
                    color: m.hpPercent < 0.3 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
