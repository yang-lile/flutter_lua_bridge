// Flutter Lua Bridge - 简化版 API
//
// 提供最简洁的 Lua 调用方式，无需手动管理状态
//
// 使用示例：
// ```dart
// import 'package:flutter_lua_bridge/lua_simple_api.dart';
//
// void main() {
//   // 执行 Lua 代码并获取结果
//   final result = lua.eval('return 1 + 1');
//   print(result); // 2
//
//   // 执行多行代码
//   lua.exec('''
//     print("Hello from Lua!")
//     x = 10
//     y = 20
//     return x + y
//   ''');
//
//   // 获取全局变量
//   lua.set('name', 'John');
//   final name = lua.get('name');
//
//   // 调用 Lua 函数
//   lua.exec('function add(a, b) return a + b end');
//   final sum = lua.call('add', [10, 20]);
//   print(sum); // 30
// }
// ```

@ffi.DefaultAsset('package:flutter_lua_bridge/flutter_lua_bridge.dart')
library flutter_lua_bridge.simple_api;

import 'dart:ffi' as ffi;
import 'src/gen/flutter_lua_bridge.g.dart' as gen;
import 'src/implementations/index.dart' show LuaAPI;

// ==================== 全局 Lua 实例 ====================

/// 全局 Lua 实例，提供简洁的 Lua 操作接口
///
/// 这是一个单例对象，在首次使用时自动初始化，
/// 程序结束时自动清理。
///
/// 使用示例：
/// ```dart
/// final result = lua.eval('return 1 + 1');
/// ```
final GlobalLua _luaInstance = GlobalLua._internal();

/// 全局 Lua 实例，提供简洁的 Lua 操作接口
///
/// 这是一个单例对象，在首次使用时自动初始化，
/// 程序结束时自动清理。
///
/// 使用示例：
/// ```dart
/// final result = lua.eval('return 1 + 1');
/// ```
GlobalLua get lua => _luaInstance;

/// 全局 Lua 状态管理器
class GlobalLua {
  LuaAPI? _api;
  bool _initialized = false;

  GlobalLua._internal();

  /// 获取底层 LuaAPI（延迟初始化）
  LuaAPI get _lua {
    if (!_initialized) {
      _init();
    }
    return _api!;
  }

  /// 初始化 Lua 状态
  void _init() {
    _api = LuaAPI.create();
    _api!.openLibs();
    _initialized = true;
  }

  /// 关闭 Lua 状态（通常在程序退出时调用）
  void dispose() {
    if (_initialized && _api != null) {
      _api!.close();
      _initialized = false;
      _api = null;
    }
  }

  // ==================== 核心方法 ====================

  /// 执行 Lua 表达式并返回结果
  ///
  /// [code] Lua 代码字符串
  /// 返回最后一个表达式的值
  ///
  /// 示例：
  /// ```dart
  /// final result = lua.eval('return 1 + 1'); // 2
  /// final str = lua.eval('return "Hello"'); // "Hello"
  /// ```
  dynamic eval(String code) {
    final fullCode = code.trim().startsWith('return') ? code : 'return $code';
    final status = _lua.doString(fullCode);

    if (status != gen.LUA_OK) {
      final error = _getError();
      throw LuaRuntimeException(error);
    }

    return _getValue(-1);
  }

  /// 执行 Lua 代码
  ///
  /// [code] Lua 代码字符串
  /// 不返回结果，只执行副作用
  ///
  /// 示例：
  /// ```dart
  /// lua.exec('print("Hello")');
  /// lua.exec('x = 10');
  /// ```
  void exec(String code) {
    final status = _lua.doString(code);

    if (status != gen.LUA_OK) {
      final error = _getError();
      throw LuaRuntimeException(error);
    }

    // 清理栈
    _lua.setTop(0);
  }

  /// 执行 Lua 代码并返回多个结果
  ///
  /// [code] Lua 代码字符串
  /// 返回所有返回值组成的列表
  ///
  /// 示例：
  /// ```dart
  /// final results = lua.evalMulti('return 1, 2, 3');
  /// print(results); // [1, 2, 3]
  /// ```
  List<dynamic> evalMulti(String code) {
    final fullCode = code.trim().startsWith('return') ? code : 'return $code';
    final status = _lua.doString(fullCode);

    if (status != gen.LUA_OK) {
      final error = _getError();
      throw LuaRuntimeException(error);
    }

    final results = <dynamic>[];
    final top = _lua.top;
    for (var i = 1; i <= top; i++) {
      results.add(_getValue(i));
    }
    _lua.setTop(0);
    return results;
  }

  // ==================== 变量操作 ====================

  /// 设置全局变量
  ///
  /// [name] 变量名
  /// [value] 值（支持 int, double, String, bool, null）
  ///
  /// 示例：
  /// ```dart
  /// lua.set('x', 10);
  /// lua.set('name', 'John');
  /// lua.set('enabled', true);
  /// ```
  void set(String name, dynamic value) {
    _pushValue(value);
    _lua.setGlobal(name);
  }

  /// 获取全局变量
  ///
  /// [name] 变量名
  /// 返回变量的值
  ///
  /// 示例：
  /// ```dart
  /// lua.set('x', 10);
  /// final x = lua.get('x'); // 10
  /// ```
  dynamic get(String name) {
    _lua.getGlobal(name);
    final value = _getValue(-1);
    _lua.pop(1);
    return value;
  }

  /// 检查全局变量是否存在
  ///
  /// [name] 变量名
  ///
  /// 示例：
  /// ```dart
  /// lua.set('x', 10);
  /// print(lua.has('x')); // true
  /// print(lua.has('y')); // false
  /// ```
  bool has(String name) {
    _lua.getGlobal(name);
    final exists = !_lua.isNil(-1);
    _lua.pop(1);
    return exists;
  }

  /// 删除全局变量
  ///
  /// [name] 变量名
  void delete(String name) {
    _lua.pushNil();
    _lua.setGlobal(name);
  }

  // ==================== 函数调用 ====================

  /// 调用 Lua 全局函数
  ///
  /// [name] 函数名
  /// [args] 参数列表
  /// 返回函数返回值
  ///
  /// 示例：
  /// ```dart
  /// lua.exec('function add(a, b) return a + b end');
  /// final result = lua.call('add', [10, 20]); // 30
  /// ```
  dynamic call(String name, List<dynamic> args) {
    _lua.getGlobal(name);

    if (!_lua.isFunction(-1)) {
      _lua.pop(1);
      throw LuaRuntimeException("'$name' is not a function");
    }

    for (final arg in args) {
      _pushValue(arg);
    }

    final status = _lua.pcall(args.length, 1, 0);

    if (status != gen.LUA_OK) {
      final error = _getError();
      throw LuaRuntimeException(error);
    }

    final result = _getValue(-1);
    _lua.pop(1);
    return result;
  }

  /// 调用 Lua 全局函数，返回多个结果
  ///
  /// [name] 函数名
  /// [args] 参数列表
  /// [nResults] 返回结果数量
  /// 返回结果列表
  ///
  /// 示例：
  /// ```dart
  /// lua.exec('function multi() return 1, 2, 3 end');
  /// final results = lua.callMulti('multi', [], 3); // [1, 2, 3]
  /// ```
  List<dynamic> callMulti(String name, List<dynamic> args, int nResults) {
    _lua.getGlobal(name);

    if (!_lua.isFunction(-1)) {
      _lua.pop(1);
      throw LuaRuntimeException("'$name' is not a function");
    }

    for (final arg in args) {
      _pushValue(arg);
    }

    final status = _lua.pcall(args.length, nResults, 0);

    if (status != gen.LUA_OK) {
      final error = _getError();
      throw LuaRuntimeException(error);
    }

    final results = <dynamic>[];
    for (var i = 0; i < nResults; i++) {
      results.add(_getValue(-nResults + i));
    }
    _lua.pop(nResults);
    return results;
  }

  // ==================== 表操作 ====================

  /// 创建 Lua 表
  ///
  /// [data] Dart Map，将被转换为 Lua 表
  /// 返回表引用（可作为参数传递给 Lua 函数）
  ///
  /// 示例：
  /// ```dart
  /// final table = lua.createTable({'a': 1, 'b': 2});
  /// lua.call('process', [table]);
  /// ```
  LuaTable createTable([Map<String, dynamic>? data]) {
    _lua.createTable(0, data?.length ?? 0);
    final tableRef = _lua.ref(gen.LUA_REGISTRYINDEX);

    if (data != null) {
      _lua.rawGetI(gen.LUA_REGISTRYINDEX, tableRef);
      for (final entry in data.entries) {
        _lua.pushString(entry.key);
        _pushValue(entry.value);
        _lua.rawSet(-3);
      }
      _lua.pop(1);
    }

    return LuaTable._(this, tableRef);
  }

  /// 获取全局表
  ///
  /// [name] 表名
  /// 返回 LuaTable 对象
  LuaTable getTable(String name) {
    _lua.getGlobal(name);
    if (!_lua.isTable(-1)) {
      _lua.pop(1);
      throw LuaRuntimeException("'$name' is not a table");
    }
    final tableRef = _lua.ref(gen.LUA_REGISTRYINDEX);
    return LuaTable._(this, tableRef);
  }

  // ==================== 工具方法 ====================

  /// 注册 Dart 函数给 Lua 调用
  ///
  /// [name] 函数在 Lua 中的名称
  /// [fn] Dart 函数
  ///
  /// 示例：
  /// ```dart
  /// lua.register('dartAdd', (List<dynamic> args) {
  ///   return (args[0] as int) + (args[1] as int);
  /// });
  /// lua.exec('print(dartAdd(10, 20))');
  /// ```
  void register(String name, LuaDartFunction fn) {
    // TODO: 实现 Dart 函数注册
    throw UnimplementedError('register not yet implemented');
  }

  /// 清空栈
  void clear() {
    _lua.setTop(0);
  }

  /// 获取 Lua 版本
  String get version => _lua.version.toString();

  // ==================== 内部辅助方法 ====================

  /// 获取错误信息
  String _getError() {
    final msg = _lua.isString(-1) ? _lua.toStr(-1) : 'Unknown error';
    _lua.pop(1);
    return msg;
  }

  /// 将 Dart 值压入 Lua 栈
  void _pushValue(dynamic value) {
    if (value == null) {
      _lua.pushNil();
    } else if (value is bool) {
      _lua.pushBool(value);
    } else if (value is int) {
      _lua.pushInt(value);
    } else if (value is double) {
      _lua.pushDouble(value);
    } else if (value is String) {
      _lua.pushString(value);
    } else if (value is LuaTable) {
      _lua.rawGetI(gen.LUA_REGISTRYINDEX, value._ref);
    } else {
      throw LuaRuntimeException('Unsupported type: ${value.runtimeType}');
    }
  }

  /// 从 Lua 栈获取值
  dynamic _getValue(int index) {
    if (_lua.isNil(index)) {
      return null;
    } else if (_lua.isBool(index)) {
      return _lua.toBool(index);
    } else if (_lua.isInt(index)) {
      return _lua.toInt(index);
    } else if (_lua.isNumber(index)) {
      return _lua.toDouble(index);
    } else if (_lua.isString(index)) {
      return _lua.toStr(index);
    } else if (_lua.isTable(index)) {
      // 转换为 Dart Map
      return _tableToMap(index);
    } else {
      return null;
    }
  }

  /// 将 Lua 表转换为 Dart Map
  Map<String, dynamic> _tableToMap(int index) {
    final result = <String, dynamic>{};
    _lua.pushNil();
    while (_lua.next(index < 0 ? index - 1 : index)) {
      if (_lua.isString(-2)) {
        final key = _lua.toStr(-2);
        final value = _getValue(-1);
        result[key] = value;
      }
      _lua.pop(1);
    }
    return result;
  }
}

// ==================== Lua 表包装器 ====================

/// Lua 表的 Dart 包装
class LuaTable {
  final GlobalLua _lua;
  final int _ref;

  LuaTable._(this._lua, this._ref);

  /// 获取表中的值
  dynamic operator [](String key) {
    _lua._lua.rawGetI(gen.LUA_REGISTRYINDEX, _ref);
    _lua._lua.getField(-1, key);
    final value = _lua._getValue(-1);
    _lua._lua.pop(2);
    return value;
  }

  /// 设置表中的值
  void operator []=(String key, dynamic value) {
    _lua._lua.rawGetI(gen.LUA_REGISTRYINDEX, _ref);
    _lua._lua.pushString(key);
    _lua._pushValue(value);
    _lua._lua.rawSet(-3);
    _lua._lua.pop(1);
  }

  /// 获取所有键
  List<String> get keys {
    final result = <String>[];
    _lua._lua.rawGetI(gen.LUA_REGISTRYINDEX, _ref);
    _lua._lua.pushNil();
    while (_lua._lua.next(-2)) {
      if (_lua._lua.isString(-2)) {
        result.add(_lua._lua.toStr(-2));
      }
      _lua._lua.pop(1);
    }
    _lua._lua.pop(1);
    return result;
  }

  /// 转换为 Dart Map
  Map<String, dynamic> toMap() {
    _lua._lua.rawGetI(gen.LUA_REGISTRYINDEX, _ref);
    final result = _lua._tableToMap(-1);
    _lua._lua.pop(1);
    return result;
  }

  /// 释放引用
  void dispose() {
    _lua._lua.unref(gen.LUA_REGISTRYINDEX, _ref);
  }
}

// ==================== 类型定义 ====================

/// Dart 函数类型，可被 Lua 调用
typedef LuaDartFunction = dynamic Function(List<dynamic> args);

// ==================== 异常 ====================

/// Lua 运行时异常
class LuaRuntimeException implements Exception {
  final String message;

  LuaRuntimeException(this.message);

  @override
  String toString() => 'LuaRuntimeException: $message';
}
