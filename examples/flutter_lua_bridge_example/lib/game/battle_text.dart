// 战斗事件的文字描述，供战斗页和结果区使用
import '../l10n/app_localizations.dart';
import 'models.dart';

String describeEvent(
  AppLocalizations l10n,
  BattleEvent event,
  List<MonsterCard> fighters,
) {
  final actor = fighters[event.actor].name;
  final target = event.target == null ? null : fighters[event.target!].name;
  final amount = event.amount;
  return switch (event.kind) {
    BattleEventKind.attack || BattleEventKind.skill =>
      '${l10n.battleLogEntry(actor, event.action ?? '', target ?? '')} '
          '-$amount${event.critical ? ' (${l10n.critLabel.trim()})' : ''}',
    BattleEventKind.heal =>
      '${l10n.battleLogEntry(actor, event.action ?? '', target ?? '')} +$amount',
    BattleEventKind.effect =>
      '$actor【${event.note}】'
          '${target != null && target != actor ? ' → $target' : ''}'
          '${amount != null ? ' +$amount' : ''}',
    BattleEventKind.stunned => l10n.stunnedCannotAct(actor),
    BattleEventKind.defeated => l10n.fallenDown(actor),
  };
}
