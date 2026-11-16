import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/game/formula_lab.dart';
import 'package:flutter_lua_bridge_example/game/formulas.dart';
import 'package:flutter_lua_bridge_example/game/game_scripts.dart';

import 'game_test_helpers.dart';

void main() {
  test('every level returns the same values for a correct script', () async {
    final scripts = GameScripts.create(await gameSources());
    try {
      final outcomes = probeLevels(scripts);
      for (final level in outcomes.values) {
        expect(level.every((call) => call.ok), isTrue);
      }
      expect(
        outcomes[FormulaBackend.o1]!.first.text,
        'LuaSuccess(Damage(amount: 73, critical: false))',
      );
      expect(
        outcomes[FormulaBackend.o3]!.first.text,
        'Damage(amount: 73, critical: false)',
      );
    } finally {
      scripts.close();
    }
  });

  test('each level reports the bugs of a faulty script its own way', () async {
    final scripts = GameScripts.create(
      await gameSources(formulas: 'formulas_faulty.lua'),
    );
    try {
      final outcomes = probeLevels(scripts);
      final o1 = outcomes[FormulaBackend.o1]!;
      final o2 = outcomes[FormulaBackend.o2]!;
      final o3 = outcomes[FormulaBackend.o3]!;
      // O1: the Lua validator names the offending path.
      expect(o1[0].text, contains('LuaFailure(type)'));
      expect(
        o1[0].text,
        contains('FormulasO1Api.physicalDamage.result.amount'),
      );
      expect(o1[1].text, contains('LuaFailure(runtime)'));
      expect(o1[1].text, contains('magic formula crashed'));
      expect(o1[2].text, contains('LuaFailure(type)'));
      expect(o1[3].ok, isTrue);
      // O2: no Lua checks, but Dart still decodes the result strictly, so a
      // wrong type is a LuaFailure too, with the path on the Dart side.
      expect(o2[0].text, contains('LuaFailure(type)'));
      expect(o2[0].text, contains('result.value.amount'));
      expect(o2[1].text, contains('LuaFailure(runtime)'));
      expect(o2[2].text, contains('got double'));
      expect(o2[3].ok, isTrue);
      // O3: everything that goes wrong is an exception.
      expect(o3[0].text, startsWith('throws LuaTypeException'));
      expect(o3[1].text, startsWith('throws LuaBridgeException'));
      expect(o3[1].text, contains('magic formula crashed'));
      expect(o3[3].ok, isTrue);
    } finally {
      scripts.close();
    }
  });

  test('the benchmark measures every backend', () async {
    final rows = benchmarkFormulas(
      await gameSources(),
      iterations: 50,
      battles: 2,
    );
    expect(rows.map((r) => r.backend), FormulaBackend.values);
    for (final row in rows) {
      expect(row.physicalDamage, greaterThan(0));
      expect(row.battle, greaterThan(0));
    }
  });
}
