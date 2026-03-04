// 游戏演示页面
import 'package:flutter/material.dart';


import 'card_loader.dart';
import 'battle_simulator.dart';
import 'card_editor_page.dart';
import 'battle_arena_page.dart';
import 'models.dart';

class GameDemoPage extends StatefulWidget {
  const GameDemoPage({super.key});

  @override
  State<GameDemoPage> createState() => _GameDemoPageState();
}

class _GameDemoPageState extends State<GameDemoPage> {
  final CardLoader _loader = CardLoader();
  BattleResult? _lastResult;
  bool _isLoading = true;
  String _status = 'Initializing...';
  
  // 预加载的卡牌模板
  final Map<String, MonsterCard> _cardTemplates = {};

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  Future<void> _initGame() async {
    try {
      setState(() => _status = 'Loading Lua...');
      _loader.init();

      setState(() => _status = 'Loading cards...');
      
      // 加载所有卡牌
      final warrior = await _loader.loadCard('assets/game/cards/warrior.lua');
      final mage = await _loader.loadCard('assets/game/cards/mage.lua');
      final healer = await _loader.loadCard('assets/game/cards/healer.lua');
      final assassin = await _loader.loadCard('assets/game/cards/assassin.lua');
      
      setState(() {
        _cardTemplates['warrior'] = warrior;
        _cardTemplates['mage'] = mage;
        _cardTemplates['healer'] = healer;
        _cardTemplates['assassin'] = assassin;
        _isLoading = false;
        _status = 'Ready!';
      });
    } catch (e, stack) {
      debugPrint('Error loading game: $e');
      debugPrint('Stack: $stack');
      setState(() {
        _status = 'Error: $e';
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

    // 导航到战斗竞技场页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BattleArenaPage(
          teamA: teamA,
          teamB: teamB,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('抽卡战斗游戏 Demo'),
      ),
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
          : _status.startsWith('Error')
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        '加载失败',
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
                            _status = 'Retrying...';
                          });
                          _initGame();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '可用卡牌',
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
    final rarityColor = {
      'N': Colors.grey,
      'R': Colors.blue,
      'SR': Colors.purple,
      'SSR': Colors.orange,
      'UR': Colors.red,
    }[card.rarity] ?? Colors.grey;

    return GestureDetector(
      onTap: () => _showCardDetailDialog(card),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: rarityColor.withOpacity(0.5), width: 2),
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
                  card.rarity,
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
              _buildMiniStat(Icons.flash_on, Colors.orange, card.attack.toString()),
              _buildMiniStat(Icons.speed, Colors.green, card.speed.toString()),
              const SizedBox(height: 8),
              // 编辑按钮
              SizedBox(
                height: 28,
                child: ElevatedButton.icon(
                  onPressed: () => _editCard(card),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('编辑', style: TextStyle(fontSize: 12)),
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
                label: Text(card.rarity),
                backgroundColor: {
                  'N': Colors.grey,
                  'R': Colors.blue,
                  'SR': Colors.purple,
                  'SSR': Colors.orange,
                  'UR': Colors.red,
                }[card.rarity]?.withOpacity(0.2),
              ),
              const SizedBox(height: 8),
              // 描述
              Text(card.description),
              const Divider(),
              // 属性
              _buildDetailStat('生命值', card.maxHp.toString(), Icons.favorite, Colors.red),
              _buildDetailStat('物理攻击', card.attack.toString(), Icons.flash_on, Colors.orange),
              _buildDetailStat('法术攻击', card.magicAttack.toString(), Icons.auto_fix_high, Colors.purple),
              _buildDetailStat('物理防御', card.physicalDefense.toString(), Icons.shield, Colors.blue),
              _buildDetailStat('法术防御', card.magicDefense.toString(), Icons.shield_moon, Colors.indigo),
              _buildDetailStat('速度', card.speed.toString(), Icons.speed, Colors.green),
              _buildDetailStat('暴击率', '${(card.critRate * 100).toInt()}%', Icons.add_alert, Colors.yellow.shade700),
              _buildDetailStat('暴击伤害', '${card.critDamage}x', Icons.trending_up, Colors.redAccent),
              const Divider(),
              // 技能
              const Text(
                '技能',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.sports_martial_arts, color: Colors.orange),
                title: Text(card.normalAttack.name),
                subtitle: Text(card.normalAttack.description),
                trailing: Text('${(card.normalAttack.multiplier * 100).toInt()}%'),
                dense: true,
              ),
              ListTile(
                leading: const Icon(Icons.auto_fix_high, color: Colors.purple),
                title: Text(card.skill.name),
                subtitle: Text('${card.skill.description}\n冷却: ${card.skill.cooldown}回合'),
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
            child: const Text('关闭'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editCard(card);
            },
            icon: const Icon(Icons.edit),
            label: const Text('编辑'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, IconData icon, Color color) {
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

  Widget _buildBattleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择战斗场景',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBattleButton('平衡对战', 'balanced', Colors.blue),
                _buildBattleButton('治疗测试', 'healer_test', Colors.green),
                _buildBattleButton('速度测试', 'speed_test', Colors.orange),
                _buildBattleButton('坦克测试', 'tank_test', Colors.purple),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    final result = _lastResult!;
    
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
                    '战斗结果',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: result.winner == 'TEAM_A'
                        ? Colors.blue
                        : result.winner == 'TEAM_B'
                            ? Colors.red
                            : Colors.grey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    result.winner == 'TEAM_A'
                        ? '蓝方胜利'
                        : result.winner == 'TEAM_B'
                            ? '红方胜利'
                            : '平局',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('总回合数: ${result.totalTurns}'),
            const SizedBox(height: 16),
            
            // 最终状态
            Row(
              children: [
                Expanded(
                  child: _buildTeamStatus('蓝方 (Team A)', result.finalTeamA, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTeamStatus('红方 (Team B)', result.finalTeamB, Colors.red),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 战斗日志
            ExpansionTile(
              title: const Text('战斗日志'),
              children: [
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: result.logs.length,
                    itemBuilder: (context, index) {
                      final log = result.logs[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          log.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: log.specialEffect == 'K.O.'
                                ? Colors.red
                                : log.isCrit == true
                                    ? Colors.orange
                                    : null,
                            fontWeight: log.specialEffect == 'K.O.'
                                ? FontWeight.bold
                                : null,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
