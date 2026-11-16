// 对比三档安全级别：同一组调用在 O1/O2/O3 下的结果，以及性能基准。
import 'dart:isolate';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import '../bridge/battle.dart';
import 'battle_simulator.dart';
import 'formulas.dart';
import 'game_scripts.dart';
import 'models.dart';

const _attacker = Fighter(
  name: '狂暴战士',
  hp: 1200,
  maxHp: 1200,
  attack: 85,
  magicAttack: 10,
  physicalDefense: 60,
  magicDefense: 20,
  speed: 50,
  critRate: 0.15,
  critDamage: 2.0,
  magicCritRate: 0.0,
);

const _defender = Fighter(
  name: '元素法师',
  hp: 700,
  maxHp: 700,
  attack: 20,
  magicAttack: 120,
  physicalDefense: 15,
  magicDefense: 50,
  speed: 70,
  critRate: 0.05,
  critDamage: 1.5,
  magicCritRate: 0.2,
);

const _roll = Roll(crit: 0.5, variance: 0.5);

/// 一次调用在某一档下的结果
class CallOutcome {
  const CallOutcome(this.method, this.ok, this.text);

  final String method;

  /// 调用是否成功拿到值
  final bool ok;

  /// 返回值、LuaFailure 或异常的描述
  final String text;
}

String _describe(Object? value) => switch (value) {
  Damage(:final amount, :final critical) =>
    'Damage(amount: $amount, critical: $critical)',
  _ => '$value',
};

CallOutcome _envelope<T>(String method, LuaCallResult<T> Function() call) {
  try {
    return switch (call()) {
      LuaSuccess(:final value) => CallOutcome(
        method,
        true,
        'LuaSuccess(${_describe(value)})',
      ),
      LuaFailure(:final kind, :final message) => CallOutcome(
        method,
        false,
        'LuaFailure(${kind.name}): $message',
      ),
    };
  } on Exception catch (error) {
    return CallOutcome(method, false, 'throws $error');
  }
}

CallOutcome _direct(String method, Object? Function() call) {
  try {
    return CallOutcome(method, true, _describe(call()));
  } on LuaBridgeException catch (error) {
    return CallOutcome(
      method,
      false,
      'throws ${error.runtimeType}: ${error.message}',
    );
  }
}

/// 用同一组参数调用三档绑定的每个方法，返回每档的结果。
Map<FormulaBackend, List<CallOutcome>> probeLevels(GameScripts scripts) {
  final fighters = [_attacker, _defender];
  final o1 = scripts.o1;
  final o2 = scripts.o2;
  final o3 = scripts.o3;
  return {
    FormulaBackend.o1: [
      _envelope(
        'physicalDamage',
        () => o1.physicalDamage(_attacker, _defender, 1.0, _roll),
      ),
      _envelope(
        'magicDamage',
        () => o1.magicDamage(_attacker, _defender, 1.0, _roll),
      ),
      _envelope('heal', () => o1.heal(_attacker, 150)),
      _envelope('actionOrder', () => o1.actionOrder(fighters)),
    ],
    FormulaBackend.o2: [
      _envelope(
        'physicalDamage',
        () => o2.physicalDamage(_attacker, _defender, 1.0, _roll),
      ),
      _envelope(
        'magicDamage',
        () => o2.magicDamage(_attacker, _defender, 1.0, _roll),
      ),
      _envelope('heal', () => o2.heal(_attacker, 150)),
      _envelope('actionOrder', () => o2.actionOrder(fighters)),
    ],
    FormulaBackend.o3: [
      _direct(
        'physicalDamage',
        () => o3.physicalDamage(_attacker, _defender, 1.0, _roll),
      ),
      _direct(
        'magicDamage',
        () => o3.magicDamage(_attacker, _defender, 1.0, _roll),
      ),
      _direct('heal', () => o3.heal(_attacker, 150)),
      _direct('actionOrder', () => o3.actionOrder(fighters)),
    ],
  };
}

/// 一种实现的基准结果，单位微秒
class BenchmarkRow {
  const BenchmarkRow({
    required this.backend,
    required this.physicalDamage,
    required this.actionOrder,
    required this.heal,
    required this.battle,
  });

  final FormulaBackend backend;

  /// 每次调用的平均耗时
  final double physicalDamage;
  final double actionOrder;
  final double heal;

  /// 每场完整战斗的平均耗时（含卡牌被动的 Lua 调用）
  final double battle;
}

double _time(int iterations, void Function() body) {
  for (var i = 0; i < iterations ~/ 10 + 1; i++) {
    body();
  }
  final watch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    body();
  }
  return watch.elapsedMicroseconds / iterations;
}

/// 在当前 isolate 运行基准。
List<BenchmarkRow> benchmarkFormulas(
  GameSources sources, {
  int iterations = 5000,
  int battles = 20,
}) {
  final scripts = GameScripts.create(sources);
  try {
    final catalog = scripts.catalog();
    MonsterCard card(String id) => catalog.firstWhere((c) => c.id == id).copy();
    final six = [
      for (final id in [
        'warrior_001',
        'mage_001',
        'healer_001',
        'assassin_001',
        'mage_001',
        'warrior_001',
      ])
        card(id).toFighter(),
    ];
    return [
      for (final backend in FormulaBackend.values)
        () {
          final formulas = scripts.formulas(backend);
          var seed = 0;
          return BenchmarkRow(
            backend: backend,
            physicalDamage: _time(
              iterations,
              () => formulas.physicalDamage(_attacker, _defender, 1.5, _roll),
            ),
            actionOrder: _time(iterations, () => formulas.actionOrder(six)),
            heal: _time(iterations, () => formulas.heal(_attacker, 150)),
            battle: _time(
              battles,
              () => BattleSimulator(
                scripts: scripts,
                formulas: formulas,
                teamA: [card('warrior_001'), card('healer_001')],
                teamB: [card('assassin_001'), card('mage_001')],
                seed: seed++,
              ).run(),
            ),
          );
        }(),
    ];
  } finally {
    scripts.close();
  }
}

/// 在后台 isolate 运行基准，不阻塞界面。
Future<List<BenchmarkRow>> benchmarkInBackground(
  GameSources sources, {
  int iterations = 5000,
  int battles = 20,
}) => Isolate.run(
  () => benchmarkFormulas(sources, iterations: iterations, battles: battles),
);
