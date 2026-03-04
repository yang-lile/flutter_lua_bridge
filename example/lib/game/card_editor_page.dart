// 卡牌编辑器页面
import 'package:flutter/material.dart';

import 'models.dart';

class CardEditorPage extends StatefulWidget {
  final MonsterCard card;
  final Function(MonsterCard) onSave;

  const CardEditorPage({
    super.key,
    required this.card,
    required this.onSave,
  });

  @override
  State<CardEditorPage> createState() => _CardEditorPageState();
}

class _CardEditorPageState extends State<CardEditorPage> {
  late MonsterCard _editableCard;
  final _formKey = GlobalKey<FormState>();

  // 文本控制器
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _hpController;
  late TextEditingController _attackController;
  late TextEditingController _magicAttackController;
  late TextEditingController _physicalDefController;
  late TextEditingController _magicDefController;
  late TextEditingController _speedController;
  late TextEditingController _critRateController;
  late TextEditingController _critDamageController;

  @override
  void initState() {
    super.initState();
    _editableCard = widget.card.copy();
    
    _nameController = TextEditingController(text: _editableCard.name);
    _descController = TextEditingController(text: _editableCard.description);
    _hpController = TextEditingController(text: _editableCard.maxHp.toString());
    _attackController = TextEditingController(text: _editableCard.attack.toString());
    _magicAttackController = TextEditingController(text: _editableCard.magicAttack.toString());
    _physicalDefController = TextEditingController(text: _editableCard.physicalDefense.toString());
    _magicDefController = TextEditingController(text: _editableCard.magicDefense.toString());
    _speedController = TextEditingController(text: _editableCard.speed.toString());
    _critRateController = TextEditingController(text: (_editableCard.critRate * 100).toStringAsFixed(0));
    _critDamageController = TextEditingController(text: _editableCard.critDamage.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _hpController.dispose();
    _attackController.dispose();
    _magicAttackController.dispose();
    _physicalDefController.dispose();
    _magicDefController.dispose();
    _speedController.dispose();
    _critRateController.dispose();
    _critDamageController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _editableCard.name = _nameController.text;
        _editableCard.description = _descController.text;
        _editableCard.maxHp = int.parse(_hpController.text);
        _editableCard.hp = int.parse(_hpController.text);
        _editableCard.attack = int.parse(_attackController.text);
        _editableCard.magicAttack = int.parse(_magicAttackController.text);
        _editableCard.physicalDefense = int.parse(_physicalDefController.text);
        _editableCard.magicDefense = int.parse(_magicDefController.text);
        _editableCard.speed = int.parse(_speedController.text);
        _editableCard.critRate = double.parse(_critRateController.text) / 100;
        _editableCard.critDamage = double.parse(_critDamageController.text);
      });
      
      widget.onSave(_editableCard);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_editableCard.name} 已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('编辑 ${widget.card.name}'),
        actions: [
          TextButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('保存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 卡牌预览
              _buildCardPreview(),
              const SizedBox(height: 24),
              
              // 基础信息
              _buildSectionTitle('基础信息'),
              _buildTextField('名称', _nameController, required: true),
              _buildTextField('描述', _descController, maxLines: 2),
              const SizedBox(height: 16),
              
              // 属性编辑
              _buildSectionTitle('基础属性'),
              _buildStatRow('生命值 (HP)', _hpController, '点'),
              _buildStatRow('物理攻击', _attackController, '点'),
              _buildStatRow('法术攻击', _magicAttackController, '点'),
              _buildStatRow('物理防御', _physicalDefController, '点'),
              _buildStatRow('法术防御', _magicDefController, '点'),
              _buildStatRow('速度', _speedController, '点'),
              const SizedBox(height: 16),
              
              // 暴击属性
              _buildSectionTitle('暴击属性'),
              _buildStatRow('暴击率', _critRateController, '%', isDouble: true),
              _buildStatRow('暴击伤害', _critDamageController, '倍', isDouble: true),
              const SizedBox(height: 24),
              
              // 技能展示
              _buildSkillSection(),
              const SizedBox(height: 32),
              
              // 战斗力评估
              _buildPowerEvaluation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    final rarityColor = {
      'N': Colors.grey,
      'R': Colors.blue,
      'SR': Colors.purple,
      'SSR': Colors.orange,
      'UR': Colors.red,
    }[_editableCard.rarity] ?? Colors.grey;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: rarityColor, width: 3),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rarityColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rarityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _editableCard.rarity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showResetDialog(),
                  icon: const Icon(Icons.restore, color: Colors.grey),
                  tooltip: '重置为默认值',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _nameController.text,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _descController.text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 24),
            _buildPreviewStatRow(Icons.favorite, Colors.red, 'HP', _hpController.text),
            _buildPreviewStatRow(Icons.flash_on, Colors.orange, '攻击', _attackController.text),
            _buildPreviewStatRow(Icons.shield, Colors.blue, '防御', _physicalDefController.text),
            _buildPreviewStatRow(Icons.speed, Colors.green, '速度', _speedController.text),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStatRow(IconData icon, Color color, String label, String value) {
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return '请输入$label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    TextEditingController controller,
    String unit, {
    bool isDouble = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: unit,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '必填';
                }
                if (isDouble) {
                  if (double.tryParse(value) == null) {
                    return '请输入数字';
                  }
                } else {
                  if (int.tryParse(value) == null) {
                    return '请输入整数';
                  }
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('技能'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sports_martial_arts, color: Colors.orange),
            title: Text(_editableCard.normalAttack.name),
            subtitle: Text(_editableCard.normalAttack.description),
            trailing: Chip(
              label: Text('${(_editableCard.normalAttack.multiplier * 100).toInt()}%'),
              backgroundColor: Colors.orange.withOpacity(0.2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.auto_fix_high, color: Colors.purple),
            title: Text(_editableCard.skill.name),
            subtitle: Text(
              '${_editableCard.skill.description}\n冷却: ${_editableCard.skill.cooldown}回合',
            ),
            trailing: Chip(
              label: Text('${(_editableCard.skill.multiplier * 100).toInt()}%'),
              backgroundColor: Colors.purple.withOpacity(0.2),
            ),
            isThreeLine: true,
          ),
        ),
      ],
    );
  }

  Widget _buildPowerEvaluation() {
    // 计算战斗力
    final hp = int.tryParse(_hpController.text) ?? 0;
    final attack = int.tryParse(_attackController.text) ?? 0;
    final magicAttack = int.tryParse(_magicAttackController.text) ?? 0;
    final physicalDef = int.tryParse(_physicalDefController.text) ?? 0;
    final magicDef = int.tryParse(_magicDefController.text) ?? 0;
    final speed = int.tryParse(_speedController.text) ?? 0;
    final critRate = (double.tryParse(_critRateController.text) ?? 0) / 100;
    final critDamage = double.tryParse(_critDamageController.text) ?? 1.5;

    final powerScore = (
      hp * 0.5 +
      (attack + magicAttack) * 1.5 +
      (physicalDef + magicDef) * 1.0 +
      speed * 0.8 +
      critRate * critDamage * 500
    ).toInt();

    String powerLevel;
    Color powerColor;
    if (powerScore < 1000) {
      powerLevel = '普通';
      powerColor = Colors.grey;
    } else if (powerScore < 2000) {
      powerLevel = '优秀';
      powerColor = Colors.blue;
    } else if (powerScore < 3500) {
      powerLevel = '稀有';
      powerColor = Colors.purple;
    } else if (powerScore < 5000) {
      powerLevel = '史诗';
      powerColor = Colors.orange;
    } else {
      powerLevel = '传说';
      powerColor = Colors.red;
    }

    return Card(
      color: powerColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '战斗力评估',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              powerScore.toString(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: powerColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: powerColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                powerLevel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置修改'),
        content: const Text('确定要重置所有修改吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToOriginal();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _resetToOriginal() {
    setState(() {
      _nameController.text = widget.card.name;
      _descController.text = widget.card.description;
      _hpController.text = widget.card.maxHp.toString();
      _attackController.text = widget.card.attack.toString();
      _magicAttackController.text = widget.card.magicAttack.toString();
      _physicalDefController.text = widget.card.physicalDefense.toString();
      _magicDefController.text = widget.card.magicDefense.toString();
      _speedController.text = widget.card.speed.toString();
      _critRateController.text = (widget.card.critRate * 100).toStringAsFixed(0);
      _critDamageController.text = widget.card.critDamage.toStringAsFixed(1);
    });
  }
}
