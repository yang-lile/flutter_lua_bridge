import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/game/battle_simulator.dart';
import 'package:flutter_lua_bridge_example/game/formulas.dart';
import 'package:flutter_lua_bridge_example/game/game_scripts.dart';
import 'package:flutter_lua_bridge_example/game/models.dart';

import 'game_test_helpers.dart';

void main() {
  late GameScripts scripts;
  late List<MonsterCard> catalog;
  setUp(() async {
    scripts = GameScripts.create(await gameSources());
    catalog = scripts.catalog();
  });
  tearDown(() => scripts.close());

  BattleResult battle(FormulaBackend backend, int seed) => BattleSimulator(
    scripts: scripts,
    formulas: scripts.formulas(backend),
    teamA: [card(catalog, 'warrior_001'), card(catalog, 'healer_001')],
    teamB: [card(catalog, 'assassin_001'), card(catalog, 'mage_001')],
    seed: seed,
  ).run();

  test('the Lua formulas match the Dart reference at every level', () {
    for (var seed = 0; seed < 20; seed++) {
      final expected = battle(FormulaBackend.dart, seed);
      for (final backend in [
        FormulaBackend.o1,
        FormulaBackend.o2,
        FormulaBackend.o3,
      ]) {
        final actual = battle(backend, seed);
        expect(actual.outcome, expected.outcome, reason: '$backend $seed');
        expect(
          actual.events.map((e) => '$e'),
          expected.events.map((e) => '$e'),
          reason: '$backend seed $seed',
        );
      }
    }
  });

  test('a battle ends with a result and runs the Lua passives', () {
    final result = battle(FormulaBackend.o1, 7);
    expect(result.turns, inInclusiveRange(1, 100));
    expect(
      result.events.where((e) => e.kind == BattleEventKind.defeated),
      isNotEmpty,
    );
    final notes = {for (final e in result.events) ?e.note};
    // The assassin's stealth fires when the battle starts.
    expect(result.events.first.note, startsWith('隐身'));
    expect(notes, contains(startsWith('隐身')));
    final all = [
      for (var s = 0; s < 20; s++) ...battle(FormulaBackend.o3, s).events,
    ];
    expect(all.where((e) => e.kind == BattleEventKind.heal), isNotEmpty);
    expect(all.where((e) => e.kind == BattleEventKind.stunned), isNotEmpty);
    expect({for (final e in all) ?e.note}, containsAll(['救赎', '眩晕']));
  });

  test('stepping yields the same events as running', () {
    final simulator = BattleSimulator(
      scripts: scripts,
      formulas: scripts.formulas(FormulaBackend.o2),
      teamA: [card(catalog, 'warrior_001')],
      teamB: [card(catalog, 'mage_001')],
      seed: 3,
    );
    final stepped = <BattleEvent>[];
    for (var step = simulator.step(); step != null; step = simulator.step()) {
      stepped.addAll(step);
    }
    final run = BattleSimulator(
      scripts: scripts,
      formulas: scripts.formulas(FormulaBackend.o2),
      teamA: [card(catalog, 'warrior_001')],
      teamB: [card(catalog, 'mage_001')],
      seed: 3,
    ).run();
    expect(stepped.map((e) => '$e'), run.events.map((e) => '$e'));
    expect(simulator.outcome, run.outcome);
  });
}
