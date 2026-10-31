import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Flutter Lua Bridge Demo'**
  String get appTitle;

  /// No description provided for @testListTitle.
  ///
  /// In en, this message translates to:
  /// **'Flutter Lua Bridge - Test List'**
  String get testListTitle;

  /// No description provided for @testListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap an item below to run the corresponding test'**
  String get testListSubtitle;

  /// No description provided for @bridgeBasicTest.
  ///
  /// In en, this message translates to:
  /// **'Bridge Basic Test'**
  String get bridgeBasicTest;

  /// No description provided for @luaVersion.
  ///
  /// In en, this message translates to:
  /// **'Lua version'**
  String get luaVersion;

  /// No description provided for @randomValueA.
  ///
  /// In en, this message translates to:
  /// **'Random value A'**
  String get randomValueA;

  /// No description provided for @randomValueB.
  ///
  /// In en, this message translates to:
  /// **'Random value B'**
  String get randomValueB;

  /// No description provided for @runBridgeTest.
  ///
  /// In en, this message translates to:
  /// **'Run Bridge Test'**
  String get runBridgeTest;

  /// No description provided for @gameDemoTest.
  ///
  /// In en, this message translates to:
  /// **'Card Battle Game Test'**
  String get gameDemoTest;

  /// No description provided for @gameDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load Lua card configs and run battle simulation'**
  String get gameDemoSubtitle;

  /// No description provided for @gameDemo.
  ///
  /// In en, this message translates to:
  /// **'Game Demo'**
  String get gameDemo;

  /// No description provided for @gameDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Card Battle Game Demo'**
  String get gameDemoTitle;

  /// No description provided for @availableCards.
  ///
  /// In en, this message translates to:
  /// **'Available Cards'**
  String get availableCards;

  /// No description provided for @selectBattleScene.
  ///
  /// In en, this message translates to:
  /// **'Select Battle Scene'**
  String get selectBattleScene;

  /// No description provided for @balancedBattle.
  ///
  /// In en, this message translates to:
  /// **'Balanced Battle'**
  String get balancedBattle;

  /// No description provided for @healerTest.
  ///
  /// In en, this message translates to:
  /// **'Healer Test'**
  String get healerTest;

  /// No description provided for @speedTest.
  ///
  /// In en, this message translates to:
  /// **'Speed Test'**
  String get speedTest;

  /// No description provided for @tankTest.
  ///
  /// In en, this message translates to:
  /// **'Tank Test'**
  String get tankTest;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get initializing;

  /// No description provided for @loadingLua.
  ///
  /// In en, this message translates to:
  /// **'Loading Lua...'**
  String get loadingLua;

  /// No description provided for @loadingCards.
  ///
  /// In en, this message translates to:
  /// **'Loading cards...'**
  String get loadingCards;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready!'**
  String get ready;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load Failed'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @hp.
  ///
  /// In en, this message translates to:
  /// **'HP'**
  String get hp;

  /// No description provided for @attack.
  ///
  /// In en, this message translates to:
  /// **'Attack'**
  String get attack;

  /// No description provided for @magicAttack.
  ///
  /// In en, this message translates to:
  /// **'Magic Attack'**
  String get magicAttack;

  /// No description provided for @physicalDefense.
  ///
  /// In en, this message translates to:
  /// **'Physical Defense'**
  String get physicalDefense;

  /// No description provided for @magicDefense.
  ///
  /// In en, this message translates to:
  /// **'Magic Defense'**
  String get magicDefense;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @critRate.
  ///
  /// In en, this message translates to:
  /// **'Crit Rate'**
  String get critRate;

  /// No description provided for @critDamage.
  ///
  /// In en, this message translates to:
  /// **'Crit Damage'**
  String get critDamage;

  /// Skill cooldown in turns
  ///
  /// In en, this message translates to:
  /// **'Cooldown: {cd} turns'**
  String cooldownTurns(int cd);

  /// No description provided for @battleResult.
  ///
  /// In en, this message translates to:
  /// **'Battle Result'**
  String get battleResult;

  /// No description provided for @teamAWins.
  ///
  /// In en, this message translates to:
  /// **'Team A Wins'**
  String get teamAWins;

  /// No description provided for @teamBWins.
  ///
  /// In en, this message translates to:
  /// **'Team B Wins'**
  String get teamBWins;

  /// No description provided for @draw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get draw;

  /// Total battle turns
  ///
  /// In en, this message translates to:
  /// **'Total Turns: {turns}'**
  String totalTurns(int turns);

  /// No description provided for @battleLogs.
  ///
  /// In en, this message translates to:
  /// **'Battle Logs'**
  String get battleLogs;

  /// No description provided for @teamA.
  ///
  /// In en, this message translates to:
  /// **'Team A'**
  String get teamA;

  /// No description provided for @teamB.
  ///
  /// In en, this message translates to:
  /// **'Team B'**
  String get teamB;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @battleArenaTitle.
  ///
  /// In en, this message translates to:
  /// **'Battle Arena'**
  String get battleArenaTitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @pauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseLabel;

  /// No description provided for @preparingForBattle.
  ///
  /// In en, this message translates to:
  /// **'Preparing for battle'**
  String get preparingForBattle;

  /// No description provided for @turnNumber.
  ///
  /// In en, this message translates to:
  /// **'Turn {turn}'**
  String turnNumber(int turn);

  /// No description provided for @battlePaused.
  ///
  /// In en, this message translates to:
  /// **'Battle Paused'**
  String get battlePaused;

  /// No description provided for @battleResumed.
  ///
  /// In en, this message translates to:
  /// **'Battle Resumed'**
  String get battleResumed;

  /// No description provided for @battleEndedNoAction.
  ///
  /// In en, this message translates to:
  /// **'Battle Ended - No Action Units'**
  String get battleEndedNoAction;

  /// No description provided for @stunnedCannotAct.
  ///
  /// In en, this message translates to:
  /// **'{name} is stunned and cannot act'**
  String stunnedCannotAct(String name);

  /// No description provided for @preparingAttack.
  ///
  /// In en, this message translates to:
  /// **'{name} is preparing to attack'**
  String preparingAttack(String name);

  /// No description provided for @attackArrow.
  ///
  /// In en, this message translates to:
  /// **'{attacker} → {target}'**
  String attackArrow(String attacker, String target);

  /// No description provided for @usesSkill.
  ///
  /// In en, this message translates to:
  /// **'{name} uses {skill}!'**
  String usesSkill(String name, String skill);

  /// No description provided for @normalAttackAction.
  ///
  /// In en, this message translates to:
  /// **'{name} Normal Attack'**
  String normalAttackAction(String name);

  /// No description provided for @fallenDown.
  ///
  /// In en, this message translates to:
  /// **'{name} has fallen!'**
  String fallenDown(String name);

  /// No description provided for @teamBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue Team'**
  String get teamBlue;

  /// No description provided for @teamRed.
  ///
  /// In en, this message translates to:
  /// **'Red Team'**
  String get teamRed;

  /// No description provided for @startBattle.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startBattle;

  /// No description provided for @vsLabel.
  ///
  /// In en, this message translates to:
  /// **'VS'**
  String get vsLabel;

  /// No description provided for @critLabel.
  ///
  /// In en, this message translates to:
  /// **'CRIT! '**
  String get critLabel;

  /// No description provided for @battleRecord.
  ///
  /// In en, this message translates to:
  /// **'Battle Record'**
  String get battleRecord;

  /// No description provided for @turnLabel.
  ///
  /// In en, this message translates to:
  /// **'T{turn}'**
  String turnLabel(int turn);

  /// No description provided for @battleLogEntry.
  ///
  /// In en, this message translates to:
  /// **'{attacker} {action} → {target}'**
  String battleLogEntry(String attacker, String action, String target);

  /// No description provided for @damageLabel.
  ///
  /// In en, this message translates to:
  /// **'-{damage}{crit}'**
  String damageLabel(int damage, String crit);

  /// No description provided for @hpLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'({hp}HP)'**
  String hpLeftLabel(int hp);

  /// No description provided for @cooldownTurnsShort.
  ///
  /// In en, this message translates to:
  /// **'CD {cd}'**
  String cooldownTurnsShort(int cd);

  /// No description provided for @editCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editCardTitle(String name);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveChanges;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @basicAttributes.
  ///
  /// In en, this message translates to:
  /// **'Basic Attributes'**
  String get basicAttributes;

  /// No description provided for @hpFull.
  ///
  /// In en, this message translates to:
  /// **'HP (Health)'**
  String get hpFull;

  /// No description provided for @physicalAttack.
  ///
  /// In en, this message translates to:
  /// **'Physical Attack'**
  String get physicalAttack;

  /// No description provided for @magicAttackLabel.
  ///
  /// In en, this message translates to:
  /// **'Magic Attack'**
  String get magicAttackLabel;

  /// No description provided for @physicalDefenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Physical Defense'**
  String get physicalDefenseLabel;

  /// No description provided for @magicDefenseLabel.
  ///
  /// In en, this message translates to:
  /// **'Magic Defense'**
  String get magicDefenseLabel;

  /// No description provided for @speedLabelFull.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedLabelFull;

  /// No description provided for @critAttributes.
  ///
  /// In en, this message translates to:
  /// **'Critical Attributes'**
  String get critAttributes;

  /// No description provided for @critRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Crit Rate'**
  String get critRateLabel;

  /// No description provided for @critDamageLabel.
  ///
  /// In en, this message translates to:
  /// **'Crit Damage'**
  String get critDamageLabel;

  /// No description provided for @unitPoint.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get unitPoint;

  /// No description provided for @unitPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get unitPercent;

  /// No description provided for @unitMultiplier.
  ///
  /// In en, this message translates to:
  /// **'x'**
  String get unitMultiplier;

  /// No description provided for @powerEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Power Evaluation'**
  String get powerEvaluation;

  /// No description provided for @powerLevelCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get powerLevelCommon;

  /// No description provided for @powerLevelExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get powerLevelExcellent;

  /// No description provided for @powerLevelRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get powerLevelRare;

  /// No description provided for @powerLevelEpic.
  ///
  /// In en, this message translates to:
  /// **'Epic'**
  String get powerLevelEpic;

  /// No description provided for @powerLevelLegendary.
  ///
  /// In en, this message translates to:
  /// **'Legendary'**
  String get powerLevelLegendary;

  /// No description provided for @resetChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Changes'**
  String get resetChangesTitle;

  /// No description provided for @resetChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all changes? This action cannot be undone.'**
  String get resetChangesMessage;

  /// No description provided for @cardSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} saved'**
  String cardSavedMessage(String name);

  /// No description provided for @pleaseEnter.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String pleaseEnter(String field);

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @pleaseEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number'**
  String get pleaseEnterNumber;

  /// No description provided for @pleaseEnterInteger.
  ///
  /// In en, this message translates to:
  /// **'Please enter an integer'**
  String get pleaseEnterInteger;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
