// 战斗公式的四种实现，都实现同一个接口 BattleFormulas（定义在契约
// lib/bridge/battle.dart 中）。战斗逻辑只依赖这个接口，用开关切换实现。
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import '../bridge/battle.dart';

export '../bridge/battle.dart' show BattleFormulas;

/// 公式由谁计算
enum FormulaBackend {
  /// 纯 Dart 参考实现，不经过 Lua；用作基准。
  dart('Dart', '纯 Dart 参考实现，不经过 Lua'),

  /// Lua 校验每个参数和返回值，pcall 捕获错误，返回 LuaCallResult。
  o1('O1', '严格类型检查 + pcall，返回 LuaCallResult'),

  /// pcall 捕获错误，没有 Lua 侧类型检查，返回 LuaCallResult。
  o2('O2', '仅 pcall，返回 LuaCallResult'),

  /// 直接调用，返回值本身，错误以异常抛出。
  o3('O3', '直接调用，错误抛出异常');

  const FormulaBackend(this.label, this.description);

  final String label;
  final String description;
}

/// O1/O2 的 [LuaFailure]，或 O3 抛出的异常，统一成游戏里的异常。
class FormulaException implements Exception {
  FormulaException(this.backend, this.method, this.message);

  final FormulaBackend backend;
  final String method;
  final String message;

  @override
  String toString() => '${backend.label} $method: $message';
}

/// 与 lua/src/formulas.tl 逐行对应的 Dart 实现。
///
/// 两边的浮点运算顺序一致，所以同一个 [Roll] 得到同样的结果；测试用它
/// 验证四种实现打出的战斗完全相同。
class DartFormulas implements BattleFormulas {
  const DartFormulas();

  static Damage _damage(
    double base,
    int defense,
    int softness,
    double critRate,
    double critDamage,
    Roll roll,
  ) {
    var amount = base * (1 - defense / (defense + softness));
    final critical = roll.crit < critRate;
    if (critical) amount = amount * critDamage;
    amount = amount * (0.9 + roll.variance * 0.2);
    final floor = amount.floor();
    return Damage(amount: floor < 1 ? 1 : floor, critical: critical);
  }

  @override
  Damage physicalDamage(
    Fighter attacker,
    Fighter defender,
    double multiplier,
    Roll roll,
  ) => _damage(
    attacker.attack * multiplier,
    defender.physicalDefense,
    100,
    attacker.critRate,
    attacker.critDamage,
    roll,
  );

  @override
  Damage magicDamage(
    Fighter attacker,
    Fighter defender,
    double multiplier,
    Roll roll,
  ) => _damage(
    attacker.magicAttack * multiplier,
    defender.magicDefense,
    80,
    attacker.magicCritRate,
    attacker.critDamage,
    roll,
  );

  @override
  int heal(Fighter caster, int base) =>
      (base * (1 + caster.magicAttack / 200)).floor();

  @override
  List<int> actionOrder(List<Fighter> fighters) {
    final order = [
      for (var i = 0; i < fighters.length; i++)
        if (fighters[i].hp > 0) i,
    ];
    order.sort((a, b) {
      final bySpeed = fighters[b].speed.compareTo(fighters[a].speed);
      return bySpeed != 0 ? bySpeed : a.compareTo(b);
    });
    return order;
  }
}

/// 把 O1/O2 客户端（返回 `LuaCallResult<T>`）适配成 [BattleFormulas]：
/// 成功取值，失败抛 [FormulaException]。
class EnvelopeFormulas implements BattleFormulas {
  EnvelopeFormulas.o1(FormulasO1ApiClient client)
    : backend = FormulaBackend.o1,
      _physical = client.physicalDamage,
      _magic = client.magicDamage,
      _heal = client.heal,
      _order = client.actionOrder;

  EnvelopeFormulas.o2(FormulasO2ApiClient client)
    : backend = FormulaBackend.o2,
      _physical = client.physicalDamage,
      _magic = client.magicDamage,
      _heal = client.heal,
      _order = client.actionOrder;

  final FormulaBackend backend;
  final LuaCallResult<Damage> Function(Fighter, Fighter, double, Roll)
  _physical;
  final LuaCallResult<Damage> Function(Fighter, Fighter, double, Roll) _magic;
  final LuaCallResult<int> Function(Fighter, int) _heal;
  final LuaCallResult<List<int>> Function(List<Fighter>) _order;

  T _value<T>(String method, LuaCallResult<T> result) => switch (result) {
    LuaSuccess(:final value) => value,
    LuaFailure(:final kind, :final message) => throw FormulaException(
      backend,
      method,
      '${kind.name}: $message',
    ),
  };

  @override
  Damage physicalDamage(
    Fighter attacker,
    Fighter defender,
    double multiplier,
    Roll roll,
  ) =>
      _value('physicalDamage', _physical(attacker, defender, multiplier, roll));

  @override
  Damage magicDamage(
    Fighter attacker,
    Fighter defender,
    double multiplier,
    Roll roll,
  ) => _value('magicDamage', _magic(attacker, defender, multiplier, roll));

  @override
  int heal(Fighter caster, int base) => _value('heal', _heal(caster, base));

  @override
  List<int> actionOrder(List<Fighter> fighters) =>
      _value('actionOrder', _order(fighters));
}
