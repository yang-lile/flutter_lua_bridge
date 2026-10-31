import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_lua_bridge_example/game/card_loader.dart';
import 'package:flutter_lua_bridge_example/game/models.dart';

void main() {
  group('MonsterCard Model Tests', () {
    test('should parse complete card data correctly', () {
      final data = {
        'id': 'warrior_001',
        'name': '狂暴战士',
        'description': '高血量高物理攻击的坦克型怪物',
        'rarity': 'SR',
        'baseStats': {
          'hp': 1200,
          'attack': 85,
          'magicAttack': 10,
          'physicalDefense': 60,
          'magicDefense': 20,
          'speed': 50,
          'critRate': 0.15,
          'critDamage': 2.0,
          'magicCritRate': 0.0,
        },
        'normalAttack': {
          'name': '重击',
          'description': '造成100%物理伤害',
          'type': 'PHYSICAL',
          'multiplier': 1.0,
          'target': 'SINGLE',
          'cooldown': 0,
        },
        'skill': {
          'name': '旋风斩',
          'description': '造成150%物理伤害',
          'type': 'PHYSICAL',
          'multiplier': 1.5,
          'target': 'SINGLE',
          'cooldown': 2,
        },
      };

      final card = MonsterCard.fromLua(data, null, null);

      expect(card.id, equals('warrior_001'));
      expect(card.name, equals('狂暴战士'));
      expect(card.maxHp, equals(1200));
      expect(card.attack, equals(85));
      expect(card.critRate, equals(0.15));
      expect(card.critDamage, equals(2.0));
    });

    test('should handle double values from Lua', () {
      final data = {
        'id': 'test_001',
        'name': 'Test',
        'description': 'Test card',
        'rarity': 'N',
        'baseStats': {
          'hp': 1000.0,  // Lua returns double
          'attack': 50.0,
          'magicAttack': 10.0,
          'physicalDefense': 30.0,
          'magicDefense': 15.0,
          'speed': 40.0,
          'critRate': 0.1,
          'critDamage': 1.5,
          'magicCritRate': 0.0,
        },
        'normalAttack': {
          'name': 'Attack',
          'description': 'Basic attack',
          'type': 'PHYSICAL',
          'multiplier': 1.0,
          'target': 'SINGLE',
          'cooldown': 0,
        },
        'skill': {
          'name': 'Skill',
          'description': 'Special skill',
          'type': 'PHYSICAL',
          'multiplier': 1.5,
          'target': 'SINGLE',
          'cooldown': 2,
        },
      };

      final card = MonsterCard.fromLua(data, null, null);

      expect(card.maxHp, equals(1000));
      expect(card.attack, equals(50));
      expect(card.critRate, equals(0.1));
    });

    test('should handle null optional values', () {
      final data = {
        'id': 'test_002',
        'name': 'Test',
        'description': 'Test card with nulls',
        'rarity': 'N',
        'baseStats': {
          'hp': 500,
          'attack': 30,
          'magicAttack': 5,
          'physicalDefense': 20,
          'magicDefense': 10,
          'speed': 25,
          // critRate is null
          // critDamage is null
          // magicCritRate is null
        },
        'normalAttack': {
          'name': 'Attack',
          'description': 'Basic attack',
          'type': 'PHYSICAL',
          'multiplier': 1.0,
          'target': 'SINGLE',
          'cooldown': 0,
        },
        'skill': {
          'name': 'Skill',
          'description': 'Skill with null healBase',
          'type': 'MAGIC',
          'multiplier': 2.0,
          'target': 'SINGLE',
          'cooldown': 3,
          // healBase is null
          // ignoreDefense is null
        },
      };

      final card = MonsterCard.fromLua(data, null, null);

      expect(card.critRate, equals(0.0));  // default value
      expect(card.critDamage, equals(1.5));  // default value
      expect(card.magicCritRate, equals(0.0));  // default value
      expect(card.skill.healBase, isNull);
      expect(card.skill.ignoreDefense, isNull);
    });

    test('should handle missing optional fields gracefully', () {
      final data = {
        'id': 'test_003',
        'name': 'Minimal',
        'description': 'Minimal card',
        'rarity': 'N',
        'baseStats': {
          'hp': 100,
          'attack': 10,
          'magicAttack': 0,
          'physicalDefense': 5,
          'magicDefense': 2,
          'speed': 10,
        },
        'normalAttack': {
          'name': 'Attack',
          'description': 'Attack',
          'type': 'PHYSICAL',
          'multiplier': 1.0,
          'target': 'SINGLE',
          'cooldown': 0,
        },
        'skill': {
          'name': 'Skill',
          'description': 'Skill',
          'type': 'PHYSICAL',
          'multiplier': 1.2,
          'target': 'SINGLE',
          'cooldown': 1,
        },
      };

      final card = MonsterCard.fromLua(data, null, null);

      expect(card.maxHp, equals(100));
      expect(card.critRate, equals(0.0));  // default
      expect(card.critDamage, equals(1.5));  // default
    });

    test('should create card copy correctly', () {
      final data = {
        'id': 'test_004',
        'name': 'Test',
        'description': 'Test copy',
        'rarity': 'N',
        'baseStats': {
          'hp': 1000,
          'attack': 100,
          'magicAttack': 50,
          'physicalDefense': 50,
          'magicDefense': 30,
          'speed': 60,
          'critRate': 0.2,
          'critDamage': 1.8,
          'magicCritRate': 0.1,
        },
        'normalAttack': {
          'name': 'Attack',
          'description': 'Attack',
          'type': 'PHYSICAL',
          'multiplier': 1.0,
          'target': 'SINGLE',
          'cooldown': 0,
        },
        'skill': {
          'name': 'Skill',
          'description': 'Skill',
          'type': 'PHYSICAL',
          'multiplier': 1.5,
          'target': 'SINGLE',
          'cooldown': 2,
        },
      };

      final card = MonsterCard.fromLua(data, null, null);
      final copy = card.copy();

      expect(copy.id, equals(card.id));
      expect(copy.maxHp, equals(card.maxHp));
      expect(copy.attack, equals(card.attack));
      
      // Modify copy should not affect original
      copy.hp = 500;
      expect(card.hp, equals(card.maxHp));  // original unchanged
      expect(copy.hp, equals(500));
    });

    test('should track hp percentage correctly', () {
      final data = {
        'id': 'test_005',
        'name': 'HP Test',
        'description': 'Test HP',
        'rarity': 'N',
        'baseStats': {
          'hp': 1000,
          'attack': 50,
          'magicAttack': 10,
          'physicalDefense': 30,
          'magicDefense': 15,
          'speed': 40,
          'critRate': 0.1,
          'critDamage': 1.5,
          'magicCritRate': 0.0,
        },
        'normalAttack': {
          'name': 'Attack',
          'description': 'Attack',
          'type': 'PHYSICAL',
          'multiplier': 1.0,
          'target': 'SINGLE',
          'cooldown': 0,
        },
        'skill': {
          'name': 'Skill',
          'description': 'Skill',
          'type': 'PHYSICAL',
          'multiplier': 1.5,
          'target': 'SINGLE',
          'cooldown': 2,
        },
      };

      final card = MonsterCard.fromLua(data, null, null);
      expect(card.hpPercent, equals(1.0));  // 1000/1000

      card.hp = 500;
      expect(card.hpPercent, equals(0.5));  // 500/1000

      card.hp = 0;
      expect(card.hpPercent, equals(0.0));
      expect(card.isAlive, isFalse);
    });
  });

  group('Skill Model Tests', () {
    test('should parse skill with all fields', () {
      final data = {
        'name': '强力技能',
        'description': '造成大量伤害',
        'type': 'MAGIC',
        'multiplier': 2.5,
        'target': 'ALL',
        'cooldown': 3,
        'ignoreDefense': 0.3,
        'healBase': 150,
      };

      final skill = Skill.fromLua(data);

      expect(skill.name, equals('强力技能'));
      expect(skill.type, equals(DamageType.magic));
      expect(skill.multiplier, equals(2.5));
      expect(skill.cooldown, equals(3));
      expect(skill.ignoreDefense, equals(0.3));
      expect(skill.healBase, equals(150));
    });

    test('should parse skill without optional fields', () {
      final data = {
        'name': '普通攻击',
        'description': '基础攻击',
        'type': 'PHYSICAL',
        'multiplier': 1.0,
        'target': 'SINGLE',
        'cooldown': 0,
        // ignoreDefense is null
        // healBase is null
      };

      final skill = Skill.fromLua(data);

      expect(skill.name, equals('普通攻击'));
      expect(skill.type, equals(DamageType.physical));
      expect(skill.ignoreDefense, isNull);
      expect(skill.healBase, isNull);
    });

    test('should parse double multiplier correctly', () {
      final data = {
        'name': 'Test',
        'description': 'Test',
        'type': 'PHYSICAL',
        'multiplier': 1.5,  // double from Lua
        'target': 'SINGLE',
        'cooldown': 0,
      };

      final skill = Skill.fromLua(data);
      expect(skill.multiplier, equals(1.5));
    });

    test('should parse integer cooldown correctly', () {
      final data = {
        'name': 'Test',
        'description': 'Test',
        'type': 'PHYSICAL',
        'multiplier': 1.0,
        'target': 'SINGLE',
        'cooldown': 2.0,  // double from Lua
      };

      final skill = Skill.fromLua(data);
      expect(skill.cooldown, equals(2));
    });
  });

  group('DamageType Tests', () {
    test('should parse PHYSICAL correctly', () {
      final data = {
        'name': 'Test',
        'description': 'Test',
        'type': 'PHYSICAL',
        'multiplier': 1.0,
        'target': 'SINGLE',
        'cooldown': 0,
      };

      final skill = Skill.fromLua(data);
      expect(skill.type, equals(DamageType.physical));
    });

    test('should parse MAGIC correctly', () {
      final data = {
        'name': 'Test',
        'description': 'Test',
        'type': 'MAGIC',
        'multiplier': 1.0,
        'target': 'SINGLE',
        'cooldown': 0,
      };

      final skill = Skill.fromLua(data);
      expect(skill.type, equals(DamageType.magic));
    });

    test('should parse HEAL correctly', () {
      final data = {
        'name': 'Test',
        'description': 'Test',
        'type': 'HEAL',
        'multiplier': 0.0,
        'target': 'ALL_ALLY',
        'cooldown': 3,
      };

      final skill = Skill.fromLua(data);
      expect(skill.type, equals(DamageType.heal));
    });

    test('should default to PHYSICAL for unknown type', () {
      final data = {
        'name': 'Test',
        'description': 'Test',
        'type': 'UNKNOWN',
        'multiplier': 1.0,
        'target': 'SINGLE',
        'cooldown': 0,
      };

      final skill = Skill.fromLua(data);
      expect(skill.type, equals(DamageType.physical));
    });

    test('should handle null type gracefully', () {
      final data = {
        'name': 'Test',
        'description': 'Test',
        'type': null,  // null from Lua
        'multiplier': 1.0,
        'target': 'SINGLE',
        'cooldown': 0,
      };

      final skill = Skill.fromLua(data);
      expect(skill.type, equals(DamageType.physical));
    });

    test('should handle completely empty skill data', () {
      final data = <String, dynamic>{};

      final skill = Skill.fromLua(data);
      expect(skill.name, equals('Unknown'));
      expect(skill.type, equals(DamageType.physical));
      expect(skill.multiplier, equals(1.0));
      expect(skill.cooldown, equals(0));
    });
  });

  group('CardLoader Integration Tests - Load from Assets', () {
    late CardLoader cardLoader;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      cardLoader = CardLoader();
      cardLoader.init();
    });

    tearDown(() {
      cardLoader.dispose();
    });

    test('should load warrior card from assets', () async {
      final card = await cardLoader.loadCard('assets/game/cards/warrior.lua');

      expect(card.id, equals('warrior_001'));
      expect(card.name, equals('狂暴战士'));
      expect(card.description, equals('高血量高物理攻击的坦克型怪物'));
      expect(card.rarity, equals('SR'));
      expect(card.maxHp, equals(1200));
      expect(card.attack, equals(85));
      expect(card.magicAttack, equals(10));
      expect(card.physicalDefense, equals(60));
      expect(card.magicDefense, equals(20));
      expect(card.speed, equals(50));
      expect(card.critRate, equals(0.15));
      expect(card.critDamage, equals(2.0));
      expect(card.magicCritRate, equals(0.0));

      // Verify normal attack
      expect(card.normalAttack.name, equals('重击'));
      expect(card.normalAttack.type, equals(DamageType.physical));
      expect(card.normalAttack.multiplier, equals(1.0));

      // Verify skill
      expect(card.skill.name, equals('旋风斩'));
      expect(card.skill.type, equals(DamageType.physical));
      expect(card.skill.multiplier, equals(1.5));
      expect(card.skill.cooldown, equals(2));
    });

    test('should load mage card from assets', () async {
      final card = await cardLoader.loadCard('assets/game/cards/mage.lua');

      expect(card.id, equals('mage_001'));
      expect(card.name, equals('元素法师'));
      expect(card.description, equals('高法术伤害但脆弱的输出型怪物'));
      expect(card.rarity, equals('SSR'));
      expect(card.maxHp, equals(700));
      expect(card.attack, equals(20));
      expect(card.magicAttack, equals(120));
      expect(card.physicalDefense, equals(15));
      expect(card.magicDefense, equals(50));
      expect(card.speed, equals(70));
      expect(card.critRate, equals(0.05));
      expect(card.critDamage, equals(1.5));
      expect(card.magicCritRate, equals(0.20));

      // Verify normal attack is MAGIC type
      expect(card.normalAttack.name, equals('魔法弹'));
      expect(card.normalAttack.type, equals(DamageType.magic));
      expect(card.normalAttack.multiplier, equals(1.0));

      // Verify skill
      expect(card.skill.name, equals('陨石术'));
      expect(card.skill.type, equals(DamageType.magic));
      expect(card.skill.multiplier, equals(2.2));
      expect(card.skill.cooldown, equals(3));
    });

    test('should load assassin card from assets', () async {
      final card = await cardLoader.loadCard('assets/game/cards/assassin.lua');

      expect(card.id, equals('assassin_001'));
      expect(card.name, equals('暗影刺客'));
      expect(card.rarity, equals('SSR'));
      expect(card.maxHp, equals(650));
      expect(card.attack, equals(100));
      expect(card.speed, equals(95));
      expect(card.critRate, equals(0.30));
      expect(card.critDamage, equals(2.5));

      // Verify skill has ignoreDefense
      expect(card.skill.name, equals('暗影突袭'));
      expect(card.skill.multiplier, equals(1.8));
      expect(card.skill.ignoreDefense, equals(0.3));
    });

    test('should load healer card from assets', () async {
      final card = await cardLoader.loadCard('assets/game/cards/healer.lua');

      expect(card.id, equals('healer_001'));
      expect(card.name, equals('圣光牧师'));
      expect(card.rarity, equals('SR'));
      expect(card.maxHp, equals(900));
      expect(card.magicAttack, equals(60));
      expect(card.magicDefense, equals(45));

      // Verify HEAL type skill
      expect(card.skill.name, equals('群体治疗'));
      expect(card.skill.type, equals(DamageType.heal));
      expect(card.skill.healBase, equals(150));
    });

    test('should load all cards with correct rarity distribution', () async {
      final cards = <MonsterCard>[];
      final cardPaths = [
        'assets/game/cards/warrior.lua',
        'assets/game/cards/mage.lua',
        'assets/game/cards/assassin.lua',
        'assets/game/cards/healer.lua',
      ];

      for (final path in cardPaths) {
        cards.add(await cardLoader.loadCard(path));
      }

      // Verify all cards loaded
      expect(cards.length, equals(4));

      // Count rarity distribution
      final srCards = cards.where((c) => c.rarity == 'SR').length;
      final ssrCards = cards.where((c) => c.rarity == 'SSR').length;

      expect(srCards, equals(2)); // warrior, healer
      expect(ssrCards, equals(2)); // mage, assassin
    });

    test('should load cards with correct stat ranges', () async {
      final warrior = await cardLoader.loadCard('assets/game/cards/warrior.lua');
      final mage = await cardLoader.loadCard('assets/game/cards/mage.lua');
      final assassin = await cardLoader.loadCard('assets/game/cards/assassin.lua');
      final healer = await cardLoader.loadCard('assets/game/cards/healer.lua');

      // Warrior: highest HP and physical defense
      expect(warrior.maxHp, greaterThan(mage.maxHp));
      expect(warrior.physicalDefense, greaterThan(mage.physicalDefense));

      // Mage: highest magic attack
      expect(mage.magicAttack, greaterThan(warrior.magicAttack));
      expect(mage.magicAttack, greaterThan(assassin.magicAttack));

      // Assassin: highest speed and crit
      expect(assassin.speed, greaterThan(warrior.speed));
      expect(assassin.speed, greaterThan(mage.speed));
      expect(assassin.critRate, greaterThan(warrior.critRate));
      expect(assassin.critDamage, greaterThan(warrior.critDamage));

      // Healer: balanced stats
      expect(healer.maxHp, greaterThan(mage.maxHp));
      expect(healer.maxHp, lessThan(warrior.maxHp));
    });

    test('should preserve card immutability after loading', () async {
      final original = await cardLoader.loadCard('assets/game/cards/warrior.lua');
      final copy = original.copy();

      // Modify copy
      copy.hp = 500;

      // Original should be unchanged
      expect(original.hp, equals(original.maxHp));
      expect(copy.hp, equals(500));
    });

    test('should handle formulas loading once', () async {
      // First load should load formulas
      final card1 = await cardLoader.loadCard('assets/game/cards/warrior.lua');
      expect(card1.id, equals('warrior_001'));

      // Second load should reuse loaded formulas (no error)
      final card2 = await cardLoader.loadCard('assets/game/cards/mage.lua');
      expect(card2.id, equals('mage_001'));
    });
  });
}
