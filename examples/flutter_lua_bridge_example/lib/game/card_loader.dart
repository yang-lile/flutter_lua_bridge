// 卡牌加载器 - 从 Lua 配置文件加载怪物数据
import 'package:flutter/services.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import 'models.dart';

/// 卡牌加载器
class CardLoader {
  LuaRuntime? _lua;
  bool _formulasLoaded = false;

  /// 初始化 Lua 状态
  void init() {
    _lua ??= LuaRuntime.create();
  }

  /// 关闭 Lua 状态
  void dispose() {
    _lua?.close();
    _lua = null;
    _formulasLoaded = false;
  }

  LuaRuntime get lua {
    final lua = _lua;
    if (lua == null) {
      throw StateError('CardLoader not initialized. Call init() first.');
    }
    return lua;
  }

  /// 加载战斗公式
  Future<void> loadFormulas() async {
    if (_formulasLoaded) return;

    final formulaCode = await rootBundle.loadString('assets/game/formulas.lua');
    try {
      // 公式模块是脚本的返回值，保存到全局变量供战斗模拟器调用
      lua['_FORMULAS'] = lua.eval(formulaCode, name: '=formulas.lua');
    } on LuaBridgeException catch (error) {
      throw Exception('Failed to load formulas: ${error.message}');
    }

    _formulasLoaded = true;
  }

  /// 从 Lua 文件加载怪物卡牌
  Future<MonsterCard> loadCard(String assetPath) async {
    await loadFormulas();

    final cardCode = await rootBundle.loadString(assetPath);

    // 执行卡牌配置脚本，脚本返回卡牌配置表
    final Object? card;
    try {
      card = lua.eval(cardCode, name: '=$assetPath');
    } on LuaBridgeException catch (error) {
      throw Exception('Failed to load card from $assetPath: ${error.message}');
    }
    if (card is! LuaTable) {
      throw Exception('Invalid card data format: missing id');
    }
    final cardData = _parseLuaTable(card);
    if (!cardData.containsKey('id')) {
      throw Exception('Invalid card data format: missing id');
    }

    return MonsterCard.fromLua(cardData, lua, null);
  }

  /// 解析 Lua 表为 Dart Map（只保留字符串键）
  Map<String, dynamic> _parseLuaTable(LuaTable table) {
    final result = <String, dynamic>{};
    for (final entry in table.entries.entries) {
      final value = _luaValueToDart(entry.value);
      final key = entry.key;
      if (key is String) result[key] = value;
    }
    table.release();
    return result;
  }

  /// 将 Lua 值转换为 Dart 值
  dynamic _luaValueToDart(Object? value) {
    switch (value) {
      case num():
        return value.toDouble();
      case bool() || String():
        return value;
      case LuaTable():
        return _parseLuaTable(value);
      case LuaFunction():
        // 被动技能等函数只保留占位符
        value.release();
        return '<function>';
      case LuaRef():
        value.release();
        return null;
      default:
        return null;
    }
  }
}
