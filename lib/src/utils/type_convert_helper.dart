// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import '../gen/flutter_lua_bridge.g.dart'
    hide LUA_MULTRET, LUA_NOREF, LUA_REFNIL;
import '../core/lua_constants.dart';

/// Pointer<Char> 扩展
extension PointCharX on Pointer<Char> {
  /// 将 C 字符串转换为 Dart 字符串
  ///
  /// 如果指针为空，返回空字符串
  String toDartString() {
    if (this == nullptr) return '';
    return cast<Utf8>().toDartString();
  }

  /// 安全地将 C 字符串转换为 Dart 字符串，带长度限制
  ///
  /// [maxLength] 最大读取长度
  String toDartStringSafe(int maxLength) {
    if (this == nullptr) return '';
    return cast<Utf8>().toDartString(length: maxLength);
  }
}

/// String 扩展
extension NativePointCharX on String {
  /// 将 Dart 字符串转换为 C 字符串指针
  ///
  /// 注意：返回的指针需要在使用后释放
  /// 使用示例：
  /// ```dart
  /// final ptr = 'hello'.toPointerChar();
  /// try {
  ///   lua_pushstring(L, ptr);
  /// } finally {
  ///   ptr.free();
  /// }
  /// ```
  Pointer<Char> toPointerChar() => toNativeUtf8().cast<Char>();

  /// 将 Dart 字符串转换为 Utf8 指针
  ///
  /// 注意：返回的指针需要在使用后释放
  Pointer<Utf8> toUtf8Pointer() => toNativeUtf8();
}

/// Lua 状态指针扩展
///
/// 提供便捷的 Lua 栈操作方法
extension LuaStateX on Pointer<lua_State> {
  /// 检查指针是否有效
  bool get isValid => this != nullptr;

  /// 获取栈顶索引
  int get top => lua_gettop(this);

  /// 设置栈顶索引
  set top(int idx) => lua_settop(this, idx);

  /// 检查栈空间
  bool checkStack(int n) => lua_checkstack(this, n) != 0;

  /// 获取栈中元素的类型
  int getType(int idx) => lua_type(this, idx);

  /// 获取类型名称
  String getTypeName(int tp) => lua_typename(this, tp).toDartString();

  /// 检查值是否为 nil
  bool isNil(int idx) => lua_type(this, idx) == LuaType.NIL;

  /// 检查值是否为数字
  bool isNumber(int idx) => lua_isnumber(this, idx) != 0;

  /// 检查值是否为整数
  bool isInteger(int idx) => lua_isinteger(this, idx) != 0;

  /// 检查值是否为字符串
  bool isString(int idx) => lua_isstring(this, idx) != 0;

  /// 检查值是否为函数
  bool isFunction(int idx) => lua_type(this, idx) == LuaType.FUNCTION;

  /// 检查值是否为表
  bool isTable(int idx) => lua_type(this, idx) == LuaType.TABLE;

  /// 检查值是否为布尔值
  bool isBoolean(int idx) => lua_type(this, idx) == LuaType.BOOLEAN;

  /// 从栈中获取数字
  double toNumber(int idx) {
    final isNum = calloc<Int>();
    try {
      final result = lua_tonumberx(this, idx, isNum);
      return isNum.value != 0 ? result : 0.0;
    } finally {
      calloc.free(isNum);
    }
  }

  /// 从栈中获取整数
  int toInteger(int idx) {
    final isNum = calloc<Int>();
    try {
      final result = lua_tointegerx(this, idx, isNum);
      return isNum.value != 0 ? result : 0;
    } finally {
      calloc.free(isNum);
    }
  }

  /// 从栈中获取布尔值
  bool toBoolean(int idx) => lua_toboolean(this, idx) != 0;

  /// 从栈中获取字符串
  String toLuaString(int idx) {
    final ptr = lua_tolstring(this, idx, nullptr);
    if (ptr == nullptr) return '';
    return ptr.cast<Utf8>().toDartString();
  }

  /// 从栈中获取裸字符串（带长度）
  String toLString(int idx, Pointer<Size> len) {
    final ptr = lua_tolstring(this, idx, len);
    if (ptr == nullptr) return '';
    return ptr.cast<Utf8>().toDartString();
  }

  /// 压入 nil
  void pushNil() => lua_pushnil(this);

  /// 压入数字
  void pushNumber(double n) => lua_pushnumber(this, n);

  /// 压入整数
  void pushInteger(int n) => lua_pushinteger(this, n);

  /// 压入布尔值
  void pushBoolean(bool b) => lua_pushboolean(this, b ? 1 : 0);

  /// 压入 Dart 字符串（自动转换）
  ///
  /// 注意：此方法会分配内存，返回的指针需要释放
  Pointer<Char> pushString(String s) {
    final ptr = s.toPointerChar();
    lua_pushstring(this, ptr);
    return ptr;
  }

  /// 压入轻量用户数据
  void pushLightUserData(Pointer<Void> p) => lua_pushlightuserdata(this, p);

  /// 弹出栈顶 n 个元素
  void pop(int n) => lua_settop(this, -n - 1);

  /// 获取全局变量
  int getGlobal(String name) {
    final ptr = name.toPointerChar();
    try {
      return lua_getglobal(this, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 设置全局变量
  void setGlobal(String name) {
    final ptr = name.toPointerChar();
    try {
      lua_setglobal(this, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 创建表
  void createTable(int narr, int nrec) => lua_createtable(this, narr, nrec);

  /// 获取表字段
  int getField(int idx, String k) {
    final ptr = k.toPointerChar();
    try {
      return lua_getfield(this, idx, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 设置表字段
  void setField(int idx, String k) {
    final ptr = k.toPointerChar();
    try {
      lua_setfield(this, idx, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 获取表元素（整数键）
  int getI(int idx, int n) => lua_geti(this, idx, n);

  /// 设置表元素（整数键）
  void setI(int idx, int n) => lua_seti(this, idx, n);

  /// 获取原始表元素
  int rawGet(int idx) => lua_rawget(this, idx);

  /// 设置原始表元素
  void rawSet(int idx) => lua_rawset(this, idx);

  /// 获取原始表元素（整数键）
  int rawGetI(int idx, int n) => lua_rawgeti(this, idx, n);

  /// 设置原始表元素（整数键）
  void rawSetI(int idx, int n) => lua_rawseti(this, idx, n);

  /// 获取表长度
  int rawLen(int idx) => lua_rawlen(this, idx);

  /// 调用 Lua 函数
  ///
  /// [nargs] 参数数量
  /// [nresults] 返回值数量，LUA_MULTRET 表示不限制
  int pcall(int nargs, int nresults, int errfunc) =>
      lua_pcallk(this, nargs, nresults, errfunc, 0, nullptr);

  /// 加载 Lua 字符串
  int loadString(String s) {
    final ptr = s.toPointerChar();
    try {
      return luaL_loadstring(this, ptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 执行 Lua 字符串
  ///
  /// 组合了 loadString 和 pcall
  int doString(String s) {
    final ptr = s.toPointerChar();
    try {
      final loadStatus = luaL_loadstring(this, ptr);
      if (loadStatus != LuaStatus.OK) {
        return loadStatus;
      }
      return lua_pcallk(this, 0, LUA_MULTRET, 0, 0, nullptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 获取错误信息（通常在 pcall 失败后栈顶）
  String getErrorMessage() => toLuaString(-1);

  /// 垃圾回收
  int gc(int what) => lua_gc(this, what);

  /// 打开所有标准库
  void openLibs() => luaL_openlibs(this);
}

/// 使用 with 语句自动管理 Pointer<Char> 生命周期
///
/// 使用示例：
/// ```dart
/// 'hello'.withPointerChar((ptr) {
///   lua_pushstring(L, ptr);
/// });
/// ```
extension StringPointerHelper on String {
  void withPointerChar(void Function(Pointer<Char> ptr) action) {
    final ptr = toPointerChar();
    try {
      action(ptr);
    } finally {
      calloc.free(ptr);
    }
  }
}

/// 批量字符串转换辅助
class StringBatch {
  final List<Pointer<Char>> _pointers = [];

  /// 添加字符串并返回指针
  Pointer<Char> add(String s) {
    final ptr = s.toPointerChar();
    _pointers.add(ptr);
    return ptr;
  }

  /// 释放所有指针
  void freeAll() {
    for (final ptr in _pointers) {
      calloc.free(ptr);
    }
    _pointers.clear();
  }
}

// ==================== 兼容性别名 ====================

/// @Deprecated('使用 toPointerChar')
extension NativePointCharXCompat on String {
  /// 兼容旧 API
  @Deprecated('使用 toPointerChar()')
  Pointer<Char> toPointChar() => toPointerChar();
}
