// 卡牌加载器 - 从 Lua 配置文件加载怪物数据
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:flutter/services.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart' as flb;

import 'models.dart';

/// 卡牌加载器
class CardLoader {
  Pointer<flb.lua_State>? _lua;
  bool _formulasLoaded = false;

  /// 初始化 Lua 状态
  void init() {
    if (_lua != null) return;
    _lua = flb.FlutterLuaBridge.auxApi.luaL_newstate();
    flb.FlutterLuaBridge.auxApi.luaL_openlibs(_lua!);
  }

  /// 关闭 Lua 状态
  void dispose() {
    if (_lua != null) {
      flb.lua_close(_lua!);
      _lua = null;
    }
  }

  Pointer<flb.lua_State> get lua {
    if (_lua == null) {
      throw StateError('CardLoader not initialized. Call init() first.');
    }
    return _lua!;
  }

  /// 加载战斗公式
  Future<void> loadFormulas() async {
    if (_formulasLoaded) return;

    final formulaCode = await rootBundle.loadString('assets/game/formulas.lua');
    final result = flb.FlutterLuaBridge.auxApi.luaL_dostring(lua, formulaCode.toNativeUtf8().cast<Char>());

    if (result != flb.LUA_OK) {
      final error = flb.FlutterLuaBridge.auxApi.luaL_tolstring(lua, -1, nullptr);
      flb.FlutterLuaBridge.cApi.lua_pop(lua, 1);
      throw Exception('Failed to load formulas: $error');
    }

    // 执行成功后，公式模块在栈顶，将其保存到全局变量并弹出栈
    final ptr = '_FORMULAS'.toNativeUtf8().cast<Char>();
    try {
      flb.lua_setglobal(lua, ptr);
    } finally {
      calloc.free(ptr);
    }
    // lua_setglobal 会自动弹出栈顶值

    _formulasLoaded = true;
  }

  /// 从 Lua 文件加载怪物卡牌
  Future<MonsterCard> loadCard(String assetPath) async {
    await loadFormulas();

    final cardCode = await rootBundle.loadString(assetPath);

    // 执行卡牌配置脚本
    final result = flb.FlutterLuaBridge.auxApi.luaL_dostring(lua, cardCode.toNativeUtf8().cast<Char>());
    if (result != flb.LUA_OK) {
      final error = flb.FlutterLuaBridge.auxApi.luaL_tolstring(lua, -1, nullptr);
      flb.FlutterLuaBridge.cApi.lua_pop(lua, 1);
      throw Exception('Failed to load card from $assetPath: $error');
    }

    // 获取返回的表（lua 脚本返回的是最后一个表达式）
    // 卡牌配置表在栈顶
    final cardData = _parseLuaTable(-1);
    flb.FlutterLuaBridge.cApi.lua_pop(lua, 1);

    // 如果表中没有 id，说明返回结构不对，尝试从 require 结果获取
    if (!cardData.containsKey('id')) {
      throw Exception('Invalid card data format: missing id');
    }

    // 加载被动技能（简化处理，暂时不存储函数引用）
    // 实际项目中可以使用 Lua registry 存储函数引用

    return MonsterCard.fromLua(cardData, lua, null);
  }

  /// 解析 Lua 表为 Dart Map
  Map<String, dynamic> _parseLuaTable(int idx) {
    final result = <String, dynamic>{};

    // 转换为绝对索引
    final absIdx = idx < 0 ? flb.lua_gettop(lua) + idx + 1 : idx;

    // 遍历表
    flb.lua_pushnil(lua);
    while (flb.lua_next(lua, absIdx) != 0) {
      // key 在 -2, value 在 -1
      final key = _luaValueToDart(-2);
      final value = _luaValueToDart(-1);

      if (key is String) {
        result[key] = value;
      }

      // 弹出 value，保留 key 用于下一次迭代
      flb.FlutterLuaBridge.cApi.lua_pop(lua, 1);
    }

    return result;
  }

  /// 将 Lua 值转换为 Dart 值
  dynamic _luaValueToDart(int idx) {
    final absIdx = idx < 0 ? flb.lua_gettop(lua) + idx + 1 : idx;
    final type = flb.lua_type(lua, absIdx);

    switch (type) {
      case flb.LUA_TNIL:
        return null;
      case flb.LUA_TBOOLEAN:
        return flb.lua_toboolean(lua, absIdx) != 0;
      case flb.LUA_TNUMBER:
        return flb.lua_tonumberx(lua, absIdx, nullptr);
      case flb.LUA_TSTRING:
        // luaL_tolstring 会将结果压入栈，需要弹出
        final str = flb.FlutterLuaBridge.auxApi.luaL_tolstring(lua, absIdx, nullptr).cast<Utf8>().toDartString();
        flb.FlutterLuaBridge.cApi.lua_pop(lua, 1);
        return str;
      case flb.LUA_TTABLE:
        return _parseLuaTable(absIdx);
      case flb.LUA_TFUNCTION:
        // Lua 函数转换为字符串表示
        return '<function>';
      default:
        return null;
    }
  }
}
