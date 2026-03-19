// FFI Implementation - Lua C API Dart Wrapper

import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:flutter_lua_bridge/src/macro_defines.dart' as gen;

import '../gen/flutter_lua_bridge.g.dart' as gen;

/// Lua C API 的 Dart 封装类
///
/// 提供对 Lua C API 和辅助库函数的完整访问
///
/// 使用示例：
/// ```dart
/// final lua = LuaAPI.create();
/// lua.openLibs();
/// lua.doString('print("Hello")');
/// ```
class LuaAPI {
  /// Lua 状态指针
  final ffi.Pointer<gen.lua_State> _state;

  /// 获取底层 Lua 状态指针
  ffi.Pointer<gen.lua_State> get state => _state;

  LuaAPI._(this._state);

  /// 创建新的 Lua 状态
  factory LuaAPI.create() {
    final state = gen.luaL_newstate();
    if (state == ffi.nullptr) {
      throw StateError('Failed to create Lua state');
    }
    return LuaAPI._(state);
  }

  /// 使用 try-finally 模式执行操作
  static R use<R>(R Function(LuaAPI lua) action) {
    final lua = LuaAPI.create();
    try {
      return action(lua);
    } finally {
      lua.close();
    }
  }

  // ==================== 状态管理 ====================

  /// 关闭 Lua 状态
  void close() => gen.lua_close(_state);

  /// 打开所有标准库
  void openLibs() => gen.luaL_openlibs(_state);

  /// 获取版本号
  double get version => gen.lua_version(_state);

  /// 获取栈顶位置
  int get top => gen.lua_gettop(_state);

  /// 设置栈顶位置
  void setTop(int index) => gen.lua_settop(_state, index);

  // ==================== 栈操作 ====================

  /// 弹出 n 个元素
  void pop(int n) => gen.lua_settop(_state, -n - 1);

  /// 压入 nil
  void pushNil() => gen.lua_pushnil(_state);

  /// 压入布尔值
  void pushBool(bool b) => gen.lua_pushboolean(_state, b ? 1 : 0);

  /// 压入整数
  void pushInt(int n) => gen.lua_pushinteger(_state, n);

  /// 压入浮点数
  void pushDouble(double n) => gen.lua_pushnumber(_state, n);

  /// 压入字符串
  void pushString(String s) {
    final ptr = s.toNativeUtf8();
    try {
      gen.lua_pushstring(_state, ptr as ffi.Pointer<ffi.Char>);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 压入值到栈
  void pushValue(int index) => gen.lua_pushvalue(_state, index);

  /// 移除指定索引的元素
  void remove(int index) {
    gen.lua_rotate(_state, index, -1);
    pop(1);
  }

  /// 插入到指定索引
  void insert(int index) => gen.lua_rotate(_state, index, 1);

  /// 复制值
  void copy(int fromIdx, int toIdx) => gen.lua_copy(_state, fromIdx, toIdx);

  /// 替换指定索引
  void replace(int index) {
    copy(-1, index);
    pop(1);
  }

  // ==================== 类型检查 ====================

  /// 检查是否为 nil
  bool isNil(int index) => gen.lua_type(_state, index) == gen.LUA_TNIL;

  /// 检查是否为布尔值
  bool isBool(int index) => gen.lua_type(_state, index) == gen.LUA_TBOOLEAN;

  /// 检查是否为数字
  bool isNumber(int index) => gen.lua_isnumber(_state, index) == 1;

  /// 检查是否为整数
  bool isInt(int index) => gen.lua_isinteger(_state, index) == 1;

  /// 检查是否为字符串
  bool isString(int index) => gen.lua_isstring(_state, index) == 1;

  /// 检查是否为表
  bool isTable(int index) => gen.lua_type(_state, index) == gen.LUA_TTABLE;

  /// 检查是否为函数
  bool isFunction(int index) => gen.lua_type(_state, index) == gen.LUA_TFUNCTION;

  /// 获取类型
  int type(int index) => gen.lua_type(_state, index);

  /// 获取类型名称
  String typeName(int tp) {
    final ptr = gen.lua_typename(_state, tp);
    return ptr.cast<Utf8>().toDartString();
  }

  // ==================== 值获取 ====================

  /// 转换为布尔值
  bool toBool(int index) => gen.lua_toboolean(_state, index) == 1;

  /// 转换为整数
  int toInt(int index) => gen.lua_tointegerx(_state, index, ffi.nullptr);

  /// 转换为浮点数
  double toDouble(int index) => gen.lua_tonumberx(_state, index, ffi.nullptr);

  /// 转换为字符串
  String toStr(int index) {
    final ptr = gen.lua_tolstring(_state, index, ffi.nullptr);
    return ptr.cast<Utf8>().toDartString();
  }

  // ==================== 全局变量 ====================

  /// 获取全局变量
  void getGlobal(String name) {
    final ptr = name.toNativeUtf8();
    try {
      gen.lua_getglobal(_state, ptr as ffi.Pointer<ffi.Char>);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 设置全局变量
  void setGlobal(String name) {
    final ptr = name.toNativeUtf8();
    try {
      gen.lua_setglobal(_state, ptr as ffi.Pointer<ffi.Char>);
    } finally {
      calloc.free(ptr);
    }
  }

  // ==================== 表操作 ====================

  /// 创建表
  void createTable(int nArr, int nRec) => gen.lua_createtable(_state, nArr, nRec);

  /// 获取表字段
  void getField(int index, String k) {
    final ptr = k.toNativeUtf8();
    try {
      gen.lua_getfield(_state, index, ptr as ffi.Pointer<ffi.Char>);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 设置表字段
  void setField(int index, String k) {
    final ptr = k.toNativeUtf8();
    try {
      gen.lua_setfield(_state, index, ptr as ffi.Pointer<ffi.Char>);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 原始获取
  void rawGet(int index) => gen.lua_rawget(_state, index);

  /// 原始获取（按整数索引）
  void rawGetI(int index, int n) => gen.lua_rawgeti(_state, index, n);

  /// 原始设置
  void rawSet(int index) => gen.lua_rawset(_state, index);

  /// 获取元表
  bool getMetaTable(int index) => gen.lua_getmetatable(_state, index) == 1;

  /// 设置元表
  bool setMetaTable(int index) => gen.lua_setmetatable(_state, index) == 1;

  // ==================== 函数调用 ====================

  /// 调用函数
  void call(int nArgs, int nResults) =>
      gen.lua_callk(_state, nArgs, nResults, 0, ffi.nullptr);

  /// 保护模式调用，返回状态码
  int pcall(int nArgs, int nResults, int errFunc) =>
      gen.lua_pcallk(_state, nArgs, nResults, errFunc, 0, ffi.nullptr);

  /// 执行 Lua 字符串
  int doString(String code) {
    final ptr = code.toNativeUtf8();
    try {
      var status = gen.luaL_loadstring(_state, ptr as ffi.Pointer<ffi.Char>);
      if (status != gen.LUA_OK) {
        return status;
      }
      return gen.lua_pcallk(_state, 0, gen.LUA_MULTRET, 0, 0, ffi.nullptr);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 加载 Lua 字符串（不执行）
  int loadString(String code) {
    final ptr = code.toNativeUtf8();
    try {
      return gen.luaL_loadstring(_state, ptr as ffi.Pointer<ffi.Char>);
    } finally {
      calloc.free(ptr);
    }
  }

  // ==================== 其他操作 ====================

  /// 连接栈顶 n 个值
  void concat(int n) => gen.lua_concat(_state, n);

  /// 执行算术操作
  void arith(int op) => gen.lua_arith(_state, op);

  /// 比较值
  bool compare(int idx1, int idx2, int op) =>
      gen.lua_compare(_state, idx1, idx2, op) == 1;

  /// 获取下一个键值对（用于遍历表）
  bool next(int index) => gen.lua_next(_state, index) == 1;

  /// 获取长度
  void len(int index) => gen.lua_len(_state, index);

  /// 获取表长度（Aux Lib）
  int length(int index) => gen.luaL_len(_state, index);

  /// 检查栈空间
  bool checkStack(int n) => gen.lua_checkstack(_state, n) == 1;

  /// 垃圾回收
  int gc(int what) => gen.lua_gc(_state, what);

  /// 获取表/字符串长度
  int rawLen(int index) => gen.lua_rawlen(_state, index);

  // ==================== 引用系统 ====================

  /// 创建引用
  int ref(int t) => gen.luaL_ref(_state, t);

  /// 释放引用
  void unref(int t, int ref) => gen.luaL_unref(_state, t, ref);

  // ==================== 错误处理 ====================

  /// 获取错误信息（栈顶应该是错误对象）
  String getErrorString() {
    if (isString(-1)) {
      return toStr(-1);
    }
    return 'Unknown error';
  }

  /// 抛出错误
  int throwError() => gen.lua_error(_state);

  /// 检查参数类型
  void checkAny(int arg) => gen.luaL_checkany(_state, arg);

  /// 检查整数参数
  int checkInt(int arg) => gen.luaL_checkinteger(_state, arg);

  /// 检查数字参数
  double checkDouble(int arg) => gen.luaL_checknumber(_state, arg);

  // ==================== 辅助功能 ====================

  /// 创建新元表
  bool newMetaTable(String name) {
    final ptr = name.toNativeUtf8();
    try {
      return gen.luaL_newmetatable(_state, ptr as ffi.Pointer<ffi.Char>) == 1;
    } finally {
      calloc.free(ptr);
    }
  }

  /// 通过名称设置元表
  void setMetaTableByName(String name) {
    final ptr = name.toNativeUtf8();
    try {
      gen.luaL_setmetatable(_state, ptr as ffi.Pointer<ffi.Char>);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 获取元表字段
  bool getMetaField(int obj, String e) {
    final ptr = e.toNativeUtf8();
    try {
      return gen.luaL_getmetafield(_state, obj, ptr as ffi.Pointer<ffi.Char>) == 1;
    } finally {
      calloc.free(ptr);
    }
  }

  /// 检查版本
  /// 使用 LUAL_NUMSIZES = sizeof(lua_Integer)*16 + sizeof(lua_Number)
  /// 对于 64 位系统: 8*16 + 8 = 136
  void checkVersion() =>
      gen.luaL_checkversion_(_state, gen.LUA_VERSION_NUM.toDouble(), 136);

  /// 获取栈中值作为字符串表示
  String toLString(int idx) {
    final ptr = gen.luaL_tolstring(_state, idx, ffi.nullptr);
    return ptr.cast<Utf8>().toDartString();
  }

  /// 生成回溯信息
  void traceBack(ffi.Pointer<gen.lua_State> l1, String msg, int level) {
    final ptr = msg.toNativeUtf8();
    try {
      gen.luaL_traceback(_state, l1, ptr as ffi.Pointer<ffi.Char>, level);
    } finally {
      calloc.free(ptr);
    }
  }

  /// 获取可选整数参数
  int optInt(int arg, int def) => gen.luaL_optinteger(_state, arg, def);

  /// 获取可选数字参数
  double optDouble(int arg, double def) => gen.luaL_optnumber(_state, arg, def);

  // ==================== 宏定义函数（FFI 未生成，作为额外方法提供）====================

  /// lua_yield - 让出协程（无延续）
  /// 宏定义: #define lua_yield(L,n)		lua_yieldk(L, (n), 0, NULL)
  int yieldk(int nResults) => gen.lua_yieldk(_state, nResults, 0, ffi.nullptr);

  /// lua_newtable - 创建新表
  /// 宏定义: #define lua_newtable(L)		lua_createtable(L, 0, 0)
  void newTable() => gen.lua_createtable(_state, 0, 0);

  /// lua_pushcfunction - 压入 C 函数（无 upvalue）
  /// 宏定义: #define lua_pushcfunction(L,f)	lua_pushcclosure(L, f, 0)
  void pushCFunction(gen.lua_CFunction fn) => gen.lua_pushcclosure(_state, fn, 0);

  /// lua_isthread - 检查是否为线程
  /// 宏定义: #define lua_isthread(L,n)		(lua_type(L, (n)) == LUA_TTHREAD)
  bool isThread(int index) => gen.lua_type(_state, index) == gen.LUA_TTHREAD;

  /// lua_isnone - 检查是否为无（无效索引）
  /// 宏定义: #define lua_isnone(L,n)		(lua_type(L, (n)) == LUA_TNONE)
  bool isNone(int index) => gen.lua_type(_state, index) == gen.LUA_TNONE;

  /// lua_isnoneornil - 检查是否为无或 nil
  /// 宏定义: #define lua_isnoneornil(L,n)	(lua_type(L, (n)) <= LUA_TNIL)
  bool isNoneOrNil(int index) => gen.lua_type(_state, index) <= gen.LUA_TNIL;

  /// lua_upvalueindex - 获取 upvalue 索引
  /// 宏定义: #define lua_upvalueindex(i)	(LUA_REGISTRYINDEX - (i))
  static int upvalueIndex(int i) => gen.LUA_REGISTRYINDEX - i;
}

/// 扩展方法：将 Dart String 转换为 Native Utf8 指针
extension StringToNative on String {
  ffi.Pointer<ffi.Char> toNativeChar() {
    return toNativeUtf8() as ffi.Pointer<ffi.Char>;
  }
}
