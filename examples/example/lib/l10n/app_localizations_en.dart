// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Lua Bridge Demo';

  @override
  String get testListTitle => 'Flutter Lua Bridge - Test List';

  @override
  String get testListSubtitle =>
      'Tap an item below to run the corresponding test';

  @override
  String get bridgeBasicTest => 'Bridge Basic Test';

  @override
  String get luaVersion => 'Lua version';

  @override
  String get randomValueA => 'Random value A';

  @override
  String get randomValueB => 'Random value B';

  @override
  String get runBridgeTest => 'Run Bridge Test';

  @override
  String get gameDemoTest => 'Card Battle Game Test';

  @override
  String get gameDemoSubtitle =>
      'Load Lua card configs and run battle simulation';

  @override
  String get gameDemo => 'Game Demo';

  @override
  String get gameDemoTitle => 'Card Battle Game Demo';

  @override
  String get availableCards => 'Available Cards';

  @override
  String get selectBattleScene => 'Select Battle Scene';

  @override
  String get balancedBattle => 'Balanced Battle';

  @override
  String get healerTest => 'Healer Test';

  @override
  String get speedTest => 'Speed Test';

  @override
  String get tankTest => 'Tank Test';

  @override
  String get initializing => 'Initializing...';

  @override
  String get loadingLua => 'Loading Lua...';

  @override
  String get loadingCards => 'Loading cards...';

  @override
  String get ready => 'Ready!';

  @override
  String get loadFailed => 'Load Failed';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get skills => 'Skills';

  @override
  String get hp => 'HP';

  @override
  String get attack => 'Attack';

  @override
  String get magicAttack => 'Magic Attack';

  @override
  String get physicalDefense => 'Physical Defense';

  @override
  String get magicDefense => 'Magic Defense';

  @override
  String get speed => 'Speed';

  @override
  String get critRate => 'Crit Rate';

  @override
  String get critDamage => 'Crit Damage';

  @override
  String cooldownTurns(int cd) {
    return 'Cooldown: $cd turns';
  }

  @override
  String get battleResult => 'Battle Result';

  @override
  String get teamAWins => 'Team A Wins';

  @override
  String get teamBWins => 'Team B Wins';

  @override
  String get draw => 'Draw';

  @override
  String totalTurns(int turns) {
    return 'Total Turns: $turns';
  }

  @override
  String get battleLogs => 'Battle Logs';

  @override
  String get teamA => 'Team A';

  @override
  String get teamB => 'Team B';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get battleArenaTitle => 'Battle Arena';

  @override
  String get continueLabel => 'Continue';

  @override
  String get pauseLabel => 'Pause';

  @override
  String get preparingForBattle => 'Preparing for battle';

  @override
  String turnNumber(int turn) {
    return 'Turn $turn';
  }

  @override
  String get battlePaused => 'Battle Paused';

  @override
  String get battleResumed => 'Battle Resumed';

  @override
  String get battleEndedNoAction => 'Battle Ended - No Action Units';

  @override
  String stunnedCannotAct(String name) {
    return '$name is stunned and cannot act';
  }

  @override
  String preparingAttack(String name) {
    return '$name is preparing to attack';
  }

  @override
  String attackArrow(String attacker, String target) {
    return '$attacker → $target';
  }

  @override
  String usesSkill(String name, String skill) {
    return '$name uses $skill!';
  }

  @override
  String normalAttackAction(String name) {
    return '$name Normal Attack';
  }

  @override
  String fallenDown(String name) {
    return '$name has fallen!';
  }

  @override
  String get teamBlue => 'Blue Team';

  @override
  String get teamRed => 'Red Team';

  @override
  String get startBattle => 'Start';

  @override
  String get vsLabel => 'VS';

  @override
  String get critLabel => 'CRIT! ';

  @override
  String get battleRecord => 'Battle Record';

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
    return 'CD $cd';
  }

  @override
  String editCardTitle(String name) {
    return 'Edit $name';
  }

  @override
  String get saveChanges => 'Save';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get nameLabel => 'Name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get basicAttributes => 'Basic Attributes';

  @override
  String get hpFull => 'HP (Health)';

  @override
  String get physicalAttack => 'Physical Attack';

  @override
  String get magicAttackLabel => 'Magic Attack';

  @override
  String get physicalDefenseLabel => 'Physical Defense';

  @override
  String get magicDefenseLabel => 'Magic Defense';

  @override
  String get speedLabelFull => 'Speed';

  @override
  String get critAttributes => 'Critical Attributes';

  @override
  String get critRateLabel => 'Crit Rate';

  @override
  String get critDamageLabel => 'Crit Damage';

  @override
  String get unitPoint => 'pts';

  @override
  String get unitPercent => '%';

  @override
  String get unitMultiplier => 'x';

  @override
  String get powerEvaluation => 'Power Evaluation';

  @override
  String get powerLevelCommon => 'Common';

  @override
  String get powerLevelExcellent => 'Excellent';

  @override
  String get powerLevelRare => 'Rare';

  @override
  String get powerLevelEpic => 'Epic';

  @override
  String get powerLevelLegendary => 'Legendary';

  @override
  String get resetChangesTitle => 'Reset Changes';

  @override
  String get resetChangesMessage =>
      'Are you sure you want to reset all changes? This action cannot be undone.';

  @override
  String cardSavedMessage(String name) {
    return '$name saved';
  }

  @override
  String pleaseEnter(String field) {
    return 'Please enter $field';
  }

  @override
  String get requiredField => 'Required';

  @override
  String get pleaseEnterNumber => 'Please enter a number';

  @override
  String get pleaseEnterInteger => 'Please enter an integer';

  @override
  String get switchLanguage => 'Switch Language';
}
