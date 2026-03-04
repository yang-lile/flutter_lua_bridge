// ignore_for_file: constant_identifier_names

import 'dart:ffi';
// ffi 导入通过 type_convert_helper.dart 间接使用

import '../gen/flutter_lua_bridge.g.dart';
import '../utils/type_convert_helper.dart';
import 'lua_constants.dart';

/// Lua 异常
class LuaException implements Exception {
  final String message;
  final int? status;

  const LuaException(this.message, {this.status});

  @override
  String toString() => status != null
      ? 'LuaException[$status]: $message'
      : 'LuaException: $message';
}

/// Lua 状态封装类
///
/// 提供面向对象的 Lua API 封装，自动管理资源
///
/// 使用示例：
/// ```dart
/// final lua = LuaState.create();
/// try {
///   lua.openLibs();
///   lua.doString('print("Hello from Lua!")');
/// } finally {
///   lua.close();
/// }
/// ```
class LuaState {
  Pointer<lua_State>? _state;

  /// 获取底层 Lua 状态指针
  Pointer<lua_State> get ptr {
    if (_state == null) {
      throw const LuaException('Lua state has been closed');
    }
    return _state!;
  }

  /// 检查状态是否有效
  bool get isOpen => _state != null && _state!.isValid;

  /// 私有构造函数
  LuaState._(this._state);

  /// 创建新的 Lua 状态
  ///
  /// 使用 [luaL_newstate] 创建标准 Lua 状态
  factory LuaState.create() {
    final state = luaL_newstate();
    if (state == nullptr) {
      throw const LuaException('Failed to create Lua state');
    }
    return LuaState._(state);
  }

  /// 使用自定义分配器创建 Lua 状态
  ///
  /// [f] 自定义内存分配函数
  /// [ud] 用户数据
  factory LuaState.createWithAlloc(lua_Alloc f, Pointer<Void> ud) {
    final state = lua_newstate(f, ud);
    if (state == nullptr) {
      throw const LuaException(
        'Failed to create Lua state with custom allocator',
      );
    }
    return LuaState._(state);
  }

  /// 关闭 Lua 状态并释放资源
  void close() {
    if (_state != null && _state!.isValid) {
      lua_close(_state!);
      _state = null;
    }
  }

  /// 使用 try-finally 模式执行操作
  ///
  /// 使用示例：
  /// ```dart
  /// LuaState.create().use((lua) {
  ///   lua.openLibs();
  ///   lua.doString('print("Hello!")');
  /// });
  /// ```
  static R use<R>(R Function(LuaState lua) action) {
    final lua = LuaState.create();
    try {
      return action(lua);
    } finally {
      lua.close();
    }
  }

  /// 打开所有标准库
  void openLibs() => luaL_openlibs(ptr);

  /// 打开指定标准库
  void openBase() => luaopen_base(ptr);
  void openTable() => luaopen_table(ptr);
  void openIO() => luaopen_io(ptr);
  void openOS() => luaopen_os(ptr);
  void openString() => luaopen_string(ptr);
  void openMath() => luaopen_math(ptr);
  void openDebug() => luaopen_debug(ptr);
  void openPackage() => luaopen_package(ptr);
  void openCoroutine() => luaopen_coroutine(ptr);
  void openUTF8() => luaopen_utf8(ptr);

  // ==================== 栈操作 ====================

  /// 获取栈顶索引
  int get top => ptr.top;

  /// 设置栈顶索引
  set top(int idx) => ptr.top = idx;

  /// 检查栈空间是否足够
  bool checkStack(int n) => ptr.checkStack(n);

  /// 压入 nil
  void pushNil() => ptr.pushNil();

  /// 压入数字
  void pushNumber(double n) => ptr.pushNumber(n);

  /// 压入整数
  void pushInteger(int n) => ptr.pushInteger(n);

  /// 压入布尔值
  void pushBoolean(bool b) => ptr.pushBoolean(b);

  /// 压入字符串
  void pushString(String s) {
    s.withPointerChar((ptr) => lua_pushstring(this.ptr, ptr));
  }

  /// 压入轻量用户数据
  void pushLightUserData(Pointer<Void> p) => ptr.pushLightUserData(p);

  /// 弹出 n 个元素
  void pop(int n) => ptr.pop(n);

  // ==================== 栈访问 ====================

  /// 获取类型
  int getType(int idx) => ptr.getType(idx);

  /// 获取类型名称
  String getTypeName(int tp) => ptr.getTypeName(tp);

  /// 检查值类型
  bool isNil(int idx) => ptr.isNil(idx);
  bool isNumber(int idx) => ptr.isNumber(idx);
  bool isInteger(int idx) => ptr.isInteger(idx);
  bool isString(int idx) => ptr.isString(idx);
  bool isFunction(int idx) => ptr.isFunction(idx);
  bool isTable(int idx) => ptr.isTable(idx);
  bool isBoolean(int idx) => ptr.isBoolean(idx);

  /// 转换为 Dart 类型
  double toNumber(int idx) => ptr.toNumber(idx);
  int toInteger(int idx) => ptr.toInteger(idx);
  bool toBoolean(int idx) => ptr.toBoolean(idx);

  /// 从栈中获取字符串
  String toLuaString(int idx) => ptr.toLuaString(idx);

  /// 获取值（自动判断类型）
  dynamic getValue(int idx) {
    final type = getType(idx);
    switch (type) {
      case LuaType.NIL:
        return null;
      case LuaType.BOOLEAN:
        return toBoolean(idx);
      case LuaType.NUMBER:
        return isInteger(idx) ? toInteger(idx) : toNumber(idx);
      case LuaType.STRING:
        return toLuaString(idx);
      case LuaType.TABLE:
        return '<table>';
      case LuaType.FUNCTION:
        return '<function>';
      case LuaType.USERDATA:
        return '<userdata>';
      case LuaType.THREAD:
        return '<thread>';
      default:
        return null;
    }
  }

  // ==================== 表操作 ====================

  /// 创建新表
  ///
  /// [narr] 数组部分的预分配大小
  /// [nrec] 记录部分的预分配大小
  void createTable([int narr = 0, int nrec = 0]) => ptr.createTable(narr, nrec);

  /// 新建空表并压入栈
  void newTable() => createTable(0, 0);

  /// 获取表字段
  int getField(int idx, String key) => ptr.getField(idx, key);

  /// 设置表字段
  void setField(int idx, String key) => ptr.setField(idx, key);

  /// 获取数组元素
  int getIndex(int idx, int n) => ptr.getI(idx, n);

  /// 设置数组元素
  void setIndex(int idx, int n) => ptr.setI(idx, n);

  /// 获取表长度
  int rawLen(int idx) => ptr.rawLen(idx);

  /// 获取全局表中的字段
  ///
  /// 将全局变量 [name] 压入栈顶
  int getGlobal(String name) => ptr.getGlobal(name);

  /// 设置全局表中的字段
  ///
  /// 将栈顶值弹出并设置为全局变量 [name]
  void setGlobal(String name) => ptr.setGlobal(name);

  /// 获取全局变量的值
  dynamic getGlobalValue(String name) {
    getGlobal(name);
    final value = getValue(-1);
    pop(1);
    return value;
  }

  /// 设置全局变量的值
  void setGlobalValue(String name, dynamic value) {
    pushValue(value);
    setGlobal(name);
  }

  /// 压入值（根据类型自动选择）
  void pushValue(dynamic value) {
    if (value == null) {
      pushNil();
    } else if (value is bool) {
      pushBoolean(value);
    } else if (value is int) {
      pushInteger(value);
    } else if (value is double) {
      pushNumber(value);
    } else if (value is String) {
      pushString(value);
    } else {
      throw LuaException('Unsupported type: ${value.runtimeType}');
    }
  }

  // ==================== 调用与执行 ====================

  /// 调用 Lua 函数
  ///
  /// [nargs] 参数数量
  /// [nresults] 返回值数量，LUA_MULTRET 表示全部返回
  /// [errfunc] 错误处理函数索引，0 表示无
  ///
  /// 抛出 [LuaException] 如果调用失败
  void call(int nargs, int nresults, {int errfunc = 0}) {
    final status = lua_pcallk(ptr, nargs, nresults, errfunc, 0, nullptr);
    if (status != LuaStatus.OK) {
      final msg = ptr.getErrorMessage();
      pop(1); // 移除错误消息
      throw LuaException(msg, status: status);
    }
  }

  /// 加载 Lua 代码字符串
  ///
  /// 将编译后的函数压入栈顶
  /// 抛出 [LuaException] 如果加载失败
  void loadString(String code) {
    final status = ptr.loadString(code);
    if (status != LuaStatus.OK) {
      final msg = ptr.getErrorMessage();
      pop(1); // 移除错误消息
      throw LuaException('Syntax error: $msg', status: status);
    }
  }

  /// 执行 Lua 代码字符串
  ///
  /// 抛出 [LuaException] 如果执行失败
  void doString(String code) {
    final status = ptr.doString(code);
    if (status != LuaStatus.OK) {
      final msg = ptr.getErrorMessage();
      pop(1); // 移除错误消息
      throw LuaException(msg, status: status);
    }
  }

  /// 保护模式执行 Lua 代码
  ///
  /// 返回执行结果和可能的错误信息
  LuaResult<void> tryDoString(String code) {
    try {
      doString(code);
      return LuaResult.success(null);
    } on LuaException catch (e) {
      return LuaResult.failure(e);
    }
  }

  // ==================== 垃圾回收 ====================

  /// 执行完整垃圾回收周期
  void gcCollect() => gc(LuaGC.COLLECT);

  /// 获取 Lua 使用的内存（KB）
  int gcCount() => gc(LuaGC.COUNT);

  /// 停止垃圾回收
  void gcStop() => gc(LuaGC.STOP);

  /// 重启垃圾回收
  void gcRestart() => gc(LuaGC.RESTART);

  /// 检查垃圾回收是否在运行
  bool gcIsRunning() => gc(LuaGC.ISRUNNING) != 0;

  /// 执行垃圾回收操作
  int gc(int what) => ptr.gc(what);

  // ==================== 工具方法 ====================

  /// 获取 Lua 版本号
  double get version => lua_version(ptr);

  /// 获取版本字符串
  String get versionString => 'Lua ${version.toInt()}';

  /// 打印栈内容（调试用）
  void dumpStack() {
    final top = this.top;
    print('=== Lua Stack ($top items) ===');
    for (int i = 1; i <= top; i++) {
      final type = getType(i);
      final typeName = getTypeName(type);
      final value = getValue(i);
      print('  [$i] $typeName: $value');
    }
    print('========================');
  }
}

/// Lua 执行结果
class LuaResult<T> {
  final bool success;
  final T? value;
  final LuaException? error;

  const LuaResult._({required this.success, this.value, this.error});

  factory LuaResult.success(T value) =>
      LuaResult._(success: true, value: value);

  factory LuaResult.failure(LuaException error) =>
      LuaResult._(success: false, error: error);

  /// 获取值或抛出异常
  T getOrThrow() {
    if (success) return value as T;
    throw error!;
  }

  /// 获取值或返回默认值
  T getOrElse(T defaultValue) => success ? value as T : defaultValue;

  /// 获取错误信息或空字符串
  String get errorMessage => error?.message ?? '';
}
