// 游戏的 Lua 脚本：一个 LuaRuntime，加载卡牌模块和三档公式绑定。
import 'package:flutter/services.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import '../bridge/battle.dart';
import 'formulas.dart';
import 'models.dart';

/// 由 build_runner 编译到 assets/lua/ 的模块
class GameSources {
  const GameSources({
    required this.cards,
    required this.formulas,
    required this.o1,
    required this.o2,
    required this.o3,
  });

  /// 读取资产。[formulas] 可以换成 `formulas_faulty.lua` 来演示故障脚本。
  static Future<GameSources> load(
    AssetBundle bundle, {
    String formulas = 'formulas.lua',
  }) async {
    Future<String> read(String name) => bundle.loadString('assets/lua/$name');
    return GameSources(
      cards: await read('cards.lua'),
      formulas: await read(formulas),
      o1: await read('formulas_o1.lua'),
      o2: await read('formulas_o2.lua'),
      o3: await read('formulas_o3.lua'),
    );
  }

  final String cards;

  /// 被三档绑定共享的公式实现，以模块名 `formulas` 加载
  final String formulas;
  final String o1;
  final String o2;
  final String o3;
}

class GameScripts {
  GameScripts._(this.runtime, this.cards, this.o1, this.o2, this.o3);

  /// 在当前 isolate 创建运行时并加载全部模块
  factory GameScripts.create(GameSources sources) {
    final runtime = LuaRuntime.create();
    try {
      final cards = CardApiClient.load(runtime: runtime, source: sources.cards);
      // formulas_o1/o2/o3 都 require("formulas")，先把共享实现加载进来。
      runtime.loadModule('formulas', source: sources.formulas);
      return GameScripts._(
        runtime,
        cards,
        FormulasO1ApiClient.load(runtime: runtime, source: sources.o1),
        FormulasO2ApiClient.load(runtime: runtime, source: sources.o2),
        FormulasO3ApiClient.load(runtime: runtime, source: sources.o3),
      );
    } catch (_) {
      runtime.close();
      rethrow;
    }
  }

  static Future<GameScripts> load(AssetBundle bundle) async =>
      GameScripts.create(await GameSources.load(bundle));

  final LuaRuntime runtime;
  final CardApiClient cards;

  // 同一份 Lua 公式的三档绑定
  final FormulasO1ApiClient o1;
  final FormulasO2ApiClient o2;
  final FormulasO3ApiClient o3;

  /// 用 [backend] 计算的公式
  BattleFormulas formulas(FormulaBackend backend) => switch (backend) {
    FormulaBackend.dart => const DartFormulas(),
    FormulaBackend.o1 => EnvelopeFormulas.o1(o1),
    FormulaBackend.o2 => EnvelopeFormulas.o2(o2),
    // O3 客户端本身就实现了 BattleFormulas。
    FormulaBackend.o3 => o3,
  };

  /// 卡牌目录
  List<MonsterCard> catalog() => [
    for (final spec in _value(cards.catalog())) MonsterCard.fromSpec(spec),
  ];

  Effect? passive(
    MonsterCard card,
    PassiveTrigger trigger, {
    MonsterCard? target,
  }) => _value(
    cards.passive(
      card.id,
      trigger,
      card.toFighter(),
      (target ?? card).toFighter(),
    ),
  );

  Effect? skillEffect(MonsterCard card, MonsterCard target, double roll) =>
      _value(cards.skillEffect(card.id, target.toFighter(), roll));

  static T _value<T>(LuaCallResult<T> result) => switch (result) {
    LuaSuccess(:final value) => value,
    LuaFailure(:final kind, :final message) => throw LuaBridgeException(
      'cards: ${kind.name}: $message',
    ),
  };

  void close() => runtime.close();
}
