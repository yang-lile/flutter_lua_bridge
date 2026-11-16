import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/bridge/battle.dart';
import 'package:flutter_lua_bridge_example/game/game_scripts.dart';
import 'package:flutter_lua_bridge_example/game/models.dart';

import 'game_test_helpers.dart';

void main() {
  late GameScripts scripts;
  setUp(() async => scripts = GameScripts.create(await gameSources()));
  tearDown(() => scripts.close());

  test('loads the typed card catalog from Lua', () {
    final catalog = scripts.catalog();
    expect(catalog.map((c) => c.id), [
      'warrior_001',
      'mage_001',
      'healer_001',
      'assassin_001',
    ]);
    final warrior = catalog.first;
    expect(warrior.name, '狂暴战士');
    expect(warrior.rarity, Rarity.sr);
    expect(warrior.rarity.label, 'SR');
    expect(warrior.maxHp, 1200);
    expect(warrior.hp, warrior.maxHp);
    expect(warrior.critDamage, 2.0);
    expect(warrior.skill.damageType, DamageType.physical);
    expect(warrior.skill.cooldown, 2);
    expect(warrior.skill.ignoreDefense, isNull);
    expect(warrior.passive?.trigger, PassiveTrigger.turnStart);

    final healer = card(catalog, 'healer_001');
    expect(healer.skill.damageType, DamageType.heal);
    expect(healer.skill.target, SkillTarget.allAllies);
    expect(healer.skill.healBase, 150);
    final assassin = card(catalog, 'assassin_001');
    expect(assassin.skill.ignoreDefense, 0.3);
    expect(assassin.passive?.trigger, PassiveTrigger.battleStart);
    for (final card in catalog) {
      expect(card.maxHp, inInclusiveRange(500, 1500), reason: card.id);
      expect(card.critRate, inInclusiveRange(0, 1), reason: card.id);
    }
  });

  test('copies keep the stats and reset the battle state', () {
    final warrior = scripts.catalog().first
      ..hp = 10
      ..stunned = true
      ..spentEffects.add('x');
    final copy = warrior.copy();
    expect(copy.hp, 10);
    expect(copy.stunned, isFalse);
    expect(copy.spentEffects, isEmpty);
    expect(copy.hpPercent, closeTo(10 / 1200, 1e-9));
  });

  test('passives and skill effects run in Lua', () {
    final catalog = scripts.catalog();
    final warrior = card(catalog, 'warrior_001');
    expect(scripts.passive(warrior, PassiveTrigger.turnStart), isNull);
    warrior.hp = 300;
    final berserk = scripts.passive(warrior, PassiveTrigger.turnStart)!;
    expect(berserk.attackScale, 1.5);
    expect(berserk.once, isTrue);
    // The trigger must match the card's passive.
    expect(scripts.passive(warrior, PassiveTrigger.battleStart), isNull);

    final healer = card(catalog, 'healer_001');
    final ally = card(catalog, 'mage_001')..hp = 100;
    final rescue = scripts.passive(
      healer,
      PassiveTrigger.allyLowHp,
      target: ally,
    )!;
    expect(rescue.heal, 70);

    final target = card(catalog, 'mage_001');
    expect(scripts.skillEffect(warrior, target, 0.1)?.stun, isTrue);
    expect(scripts.skillEffect(warrior, target, 0.9), isNull);
  });
}
