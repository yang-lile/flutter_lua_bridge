// Run with `dart test -P teal-worker`; see dart_test.yaml.
@Tags(['teal-worker'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_lua_bridge_codegen/src/builders/teal_worker_client.dart';
import 'package:test/test.dart';

void main() {
  late TealWorkerClient worker;
  setUpAll(() async => worker = await TealWorkerClient.start());
  tearDownAll(TealWorkerClient.stopAll);

  final declarations = {
    'battle_bridge': {
      'd.tl': {
        'path': 'test/fixtures/lua/types/battle_bridge.d.tl',
        'source': File('test/fixtures/lua/types/battle_bridge.d.tl')
            .readAsStringSync(),
      },
    },
  };
  final source = File('test/fixtures/lua/src/battle.tl').readAsStringSync();

  test('compiles Teal against generated declarations', () async {
    final result = await worker.compile(
      path: 'lua/src/battle.tl',
      source: source,
      modules: declarations,
    );
    expect(result.errors, isEmpty);
    expect(result.lua, contains('return bridge.bindBattleApi(implementation)'));
    expect(result.lua, isNot(contains(': bridge.Fighter')));
    // The committed output is what the builder produces.
    expect(
      result.lua,
      File('test/fixtures/lua/out/battle.lua').readAsStringSync(),
    );
  });

  test('reports type errors with their position', () async {
    final result = await worker.compile(
      path: 'lua/src/battle.tl',
      source: source.replaceFirst('attacker.attack', 'attacker.attak'),
      modules: declarations,
    );
    expect(result.lua, isNull);
    expect(
      result.errors.first,
      startsWith("lua/src/battle.tl:6:41: invalid key 'attak'"),
    );
  });

  test('reports syntax errors and missing modules', () async {
    final syntax = await worker.compile(
      path: 'lua/src/broken.tl',
      source: 'local x: integer = = 1',
      modules: const {},
    );
    expect(syntax.lua, isNull);
    expect(syntax.errors.first, startsWith('lua/src/broken.tl:1:'));

    final missing = await worker.compile(
      path: 'lua/src/battle.tl',
      source: source,
      modules: const {},
    );
    expect(missing.lua, isNull);
    expect(missing.errors.join('\n'), contains("battle_bridge"));
  });

  test('resolves sibling Teal modules', () async {
    final result = await worker.compile(
      path: 'lua/src/main.tl',
      source: 'local util = require("util")\nreturn util.twice(21)\n',
      modules: {
        'util': {
          'tl': {
            'path': 'lua/src/util.tl',
            'source': 'local util = {}\nfunction util.twice(n: integer): integer return n * 2 end\nreturn util\n',
          },
        },
      },
    );
    expect(result.errors, isEmpty);
    expect(result.lua, contains('util.twice(21)'));
  });
}
