// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Flutter Lua Bridge Demo';

  @override
  String get testListTitle => 'Flutter Lua Bridge - 测试列表';

  @override
  String get testListSubtitle => '点击下方列表项运行对应测试';

  @override
  String get bridgeBasicTest => 'Bridge 基础测试';

  @override
  String get luaVersion => 'Lua version';

  @override
  String get randomValueA => 'Random value A';

  @override
  String get randomValueB => 'Random value B';

  @override
  String get runBridgeTest => '运行 Bridge 测试';

  @override
  String get gameDemoTest => '抽卡战斗游戏测试';

  @override
  String get gameDemoSubtitle => '加载 Lua 卡牌配置并运行战斗模拟';

  @override
  String get gameDemo => '游戏Demo';

  @override
  String get gameDemoTitle => '抽卡战斗游戏 Demo';

  @override
  String get availableCards => '可用卡牌';

  @override
  String get selectBattleScene => '选择战斗场景';

  @override
  String get balancedBattle => '平衡对战';

  @override
  String get healerTest => '治疗测试';

  @override
  String get speedTest => '速度测试';

  @override
  String get tankTest => '坦克测试';

  @override
  String get initializing => 'Initializing...';

  @override
  String get loadingLua => 'Loading Lua...';

  @override
  String get loadingCards => 'Loading cards...';

  @override
  String get ready => 'Ready!';

  @override
  String get loadFailed => '加载失败';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get reset => '重置';

  @override
  String get skills => '技能';

  @override
  String get hp => '生命值';

  @override
  String get attack => '物理攻击';

  @override
  String get magicAttack => '法术攻击';

  @override
  String get physicalDefense => '物理防御';

  @override
  String get magicDefense => '法术防御';

  @override
  String get speed => '速度';

  @override
  String get critRate => '暴击率';

  @override
  String get critDamage => '暴击伤害';

  @override
  String cooldownTurns(int cd) {
    return '冷却: $cd回合';
  }

  @override
  String get battleResult => '战斗结果';

  @override
  String get teamAWins => '蓝方胜利';

  @override
  String get teamBWins => '红方胜利';

  @override
  String get draw => '平局';

  @override
  String totalTurns(int turns) {
    return '总回合数: $turns';
  }

  @override
  String get battleLogs => '战斗日志';

  @override
  String get teamA => '蓝方 (Team A)';

  @override
  String get teamB => '红方 (Team B)';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get battleArenaTitle => '战斗竞技场';

  @override
  String get continueLabel => '继续';

  @override
  String get pauseLabel => '暂停';

  @override
  String get preparingForBattle => '准备战斗';

  @override
  String turnNumber(int turn) {
    return '第 $turn 回合';
  }

  @override
  String get battlePaused => '战斗暂停';

  @override
  String get battleResumed => '战斗继续';

  @override
  String get battleEndedNoAction => '战斗结束 - 无行动单位';

  @override
  String stunnedCannotAct(String name) {
    return '$name 眩晕中，无法行动';
  }

  @override
  String preparingAttack(String name) {
    return '$name 准备攻击';
  }

  @override
  String attackArrow(String attacker, String target) {
    return '$attacker → $target';
  }

  @override
  String usesSkill(String name, String skill) {
    return '$name 使用 $skill!';
  }

  @override
  String normalAttackAction(String name) {
    return '$name 普通攻击';
  }

  @override
  String fallenDown(String name) {
    return '$name 倒下了！';
  }

  @override
  String get teamBlue => '蓝方';

  @override
  String get teamRed => '红方';

  @override
  String get startBattle => '开始';

  @override
  String get vsLabel => 'VS';

  @override
  String get critLabel => '暴击! ';

  @override
  String get battleRecord => '战斗记录';

  @override
  String turnLabel(int turn) {
    return 'T$turn';
  }

  @override
  String battleLogEntry(String attacker, String action, String target) {
    return '$attacker $action → $target';
  }

  @override
  String damageLabel(int damage, String crit) {
    return '-$damage$crit';
  }

  @override
  String hpLeftLabel(int hp) {
    return '(${hp}HP)';
  }

  @override
  String cooldownTurnsShort(int cd) {
    return '冷却 $cd';
  }

  @override
  String editCardTitle(String name) {
    return '编辑 $name';
  }

  @override
  String get saveChanges => '保存';

  @override
  String get resetToDefault => '重置为默认值';

  @override
  String get basicInfo => '基础信息';

  @override
  String get nameLabel => '名称';

  @override
  String get descriptionLabel => '描述';

  @override
  String get basicAttributes => '基础属性';

  @override
  String get hpFull => '生命值 (HP)';

  @override
  String get physicalAttack => '物理攻击';

  @override
  String get magicAttackLabel => '法术攻击';

  @override
  String get physicalDefenseLabel => '物理防御';

  @override
  String get magicDefenseLabel => '法术防御';

  @override
  String get speedLabelFull => '速度';

  @override
  String get critAttributes => '暴击属性';

  @override
  String get critRateLabel => '暴击率';

  @override
  String get critDamageLabel => '暴击伤害';

  @override
  String get unitPoint => '点';

  @override
  String get unitPercent => '%';

  @override
  String get unitMultiplier => '倍';

  @override
  String get powerEvaluation => '战斗力评估';

  @override
  String get powerLevelCommon => '普通';

  @override
  String get powerLevelExcellent => '优秀';

  @override
  String get powerLevelRare => '稀有';

  @override
  String get powerLevelEpic => '史诗';

  @override
  String get powerLevelLegendary => '传说';

  @override
  String get resetChangesTitle => '重置修改';

  @override
  String get resetChangesMessage => '确定要重置所有修改吗？此操作不可撤销。';

  @override
  String cardSavedMessage(String name) {
    return '$name 已保存';
  }

  @override
  String pleaseEnter(String field) {
    return '请输入$field';
  }

  @override
  String get requiredField => '必填';

  @override
  String get pleaseEnterNumber => '请输入数字';

  @override
  String get pleaseEnterInteger => '请输入整数';

  @override
  String get switchLanguage => '切换语言';
}
