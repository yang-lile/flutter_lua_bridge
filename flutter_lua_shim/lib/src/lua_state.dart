import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'gen/flutter_lua_shim.g.dart' as generated;
import 'lua_constants.dart';

/// Dart 友好的 Lua State 包装器
class LuaState {
  final Pointer<generated.lua_State> _ptr;

  LuaState._(this._ptr);

  factory LuaState.newState() {
    final p = generated.dart_lua_shim_newstate();
    if (p == nullptr) throw Exception('Failed to create Lua state');
    return LuaState._(p);
  }

  void close() => generated.dart_lua_shim_close(_ptr);

  // 栈操作
  int get top => generated.dart_lua_shim_gettop(_ptr);
  set top(int n) => generated.dart_lua_shim_settop(_ptr, n);
  void pop(int n) => generated.dart_lua_shim_pop(_ptr, n);
  void pushValue(int idx) => generated.dart_lua_shim_pushvalue(_ptr, idx);
  void remove(int idx) => generated.dart_lua_shim_remove(_ptr, idx);
  void insert(int idx) => generated.dart_lua_shim_insert(_ptr, idx);
  void replace(int idx) => generated.dart_lua_shim_replace(_ptr, idx);
  void copy(int from, int to) => generated.dart_lua_shim_copy(_ptr, from, to);
  bool checkStack(int n) => generated.dart_lua_shim_checkstack(_ptr, n) != 0;

  // 类型检查
  bool isNil(int idx) => generated.dart_lua_shim_isnil(_ptr, idx);
  bool isBoolean(int idx) => generated.dart_lua_shim_isboolean(_ptr, idx);
  bool isNumber(int idx) => generated.dart_lua_shim_isnumber(_ptr, idx);
  bool isString(int idx) => generated.dart_lua_shim_isstring(_ptr, idx);
  bool isTable(int idx) => generated.dart_lua_shim_istable(_ptr, idx);
  bool isFunction(int idx) => generated.dart_lua_shim_isfunction(_ptr, idx);
  bool isCFunction(int idx) => generated.dart_lua_shim_iscfunction(_ptr, idx);
  bool isUserdata(int idx) => generated.dart_lua_shim_isuserdata(_ptr, idx);
  bool isThread(int idx) => generated.dart_lua_shim_isthread(_ptr, idx);

  /// 返回栈索引处值的类型码。对应 [LuaType] 常量。
  int type(int idx) => generated.dart_lua_shim_type(_ptr, idx).value;

  String typeName(int tp) {
    final ptr = generated.dart_lua_shim_typename(
      _ptr,
      generated.lua_shim_type.fromValue(tp),
    );
    return ptr.cast<Utf8>().toDartString();
  }

  // 取值
  double toNumberX(int idx, {bool check = false}) {
    final ok = calloc<Bool>();
    final v = generated.dart_lua_shim_tonumberx(_ptr, idx, ok);
    if (check && !ok.value) {
      calloc.free(ok);
      throw Exception('Not a number at index $idx');
    }
    calloc.free(ok);
    return v;
  }

  int toIntegerX(int idx, {bool check = false}) {
    final ok = calloc<Bool>();
    final v = generated.dart_lua_shim_tointegerx(_ptr, idx, ok);
    if (check && !ok.value) {
      calloc.free(ok);
      throw Exception('Not an integer at index $idx');
    }
    calloc.free(ok);
    return v;
  }

  bool toBoolean(int idx) => generated.dart_lua_shim_toboolean(_ptr, idx);

  String toLString(int idx) {
    final len = calloc<Size>();
    final ptr = generated.dart_lua_shim_tolstring(_ptr, idx, len);
    final s = ptr.cast<Utf8>().toDartString(length: len.value);
    calloc.free(len);
    return s;
  }

  int rawLen(int idx) => generated.dart_lua_shim_rawlen(_ptr, idx);
  Pointer<Void> toUserdata(int idx) => generated.dart_lua_shim_touserdata(_ptr, idx);
  LuaState toThread(int idx) => LuaState._(generated.dart_lua_shim_tothread(_ptr, idx));

  // 压栈
  void pushNil() => generated.dart_lua_shim_pushnil(_ptr);
  void pushNumber(double n) => generated.dart_lua_shim_pushnumber(_ptr, n);
  void pushInteger(int n) => generated.dart_lua_shim_pushinteger(_ptr, n);
  void pushLString(String s) {
    final bytes = s.toNativeUtf8();
    generated.dart_lua_shim_pushlstring(_ptr, bytes.cast(), bytes.length);
    calloc.free(bytes);
  }

  void pushString(String s) {
    final ptr = s.toNativeUtf8();
    generated.dart_lua_shim_pushstring(_ptr, ptr.cast());
    calloc.free(ptr);
  }

  void pushBoolean(bool b) => generated.dart_lua_shim_pushboolean(_ptr, b);
  void pushLightUserdata(Pointer<Void> p) => generated.dart_lua_shim_pushlightuserdata(_ptr, p);

  // 表操作
  void getTable(int idx) => generated.dart_lua_shim_gettable(_ptr, idx);

  /// 获取字段并将字段类型码压入栈。返回类型码，对应 [LuaType] 常量。
  int getField(int idx, String k) {
    final ptr = k.toNativeUtf8();
    final tp = generated.dart_lua_shim_getfield(_ptr, idx, ptr.cast());
    calloc.free(ptr);
    return tp.value;
  }

  void rawGet(int idx) => generated.dart_lua_shim_rawget(_ptr, idx);
  void rawGetI(int idx, int n) => generated.dart_lua_shim_rawgeti(_ptr, idx, n);
  void createTable(int narr, int nrec) => generated.dart_lua_shim_createtable(_ptr, narr, nrec);
  void newTable() => generated.dart_lua_shim_newtable(_ptr);
  void setTable(int idx) => generated.dart_lua_shim_settable(_ptr, idx);
  void setField(int idx, String k) {
    final ptr = k.toNativeUtf8();
    generated.dart_lua_shim_setfield(_ptr, idx, ptr.cast());
    calloc.free(ptr);
  }

  void rawSet(int idx) => generated.dart_lua_shim_rawset(_ptr, idx);
  void rawSetI(int idx, int n) => generated.dart_lua_shim_rawseti(_ptr, idx, n);

  // 全局

  /// 获取全局变量并将值压入栈。返回类型码，对应 [LuaType] 常量。
  int getGlobal(String name) {
    final ptr = name.toNativeUtf8();
    final tp = generated.dart_lua_shim_getglobal(_ptr, ptr.cast());
    calloc.free(ptr);
    return tp.value;
  }

  void setGlobal(String name) {
    final ptr = name.toNativeUtf8();
    generated.dart_lua_shim_setglobal(_ptr, ptr.cast());
    calloc.free(ptr);
  }

  // 调用

  /// 以保护模式调用函数。返回状态码，对应 [LuaStatus] 常量。
  int pCall(int nargs, int nresults, {int errfunc = 0}) =>
      generated.dart_lua_shim_pcallk(_ptr, nargs, nresults, errfunc, 0, nullptr).value;

  /// 加载字符串。返回状态码，对应 [LuaStatus] 常量。
  int loadString(String code) {
    final ptr = code.toNativeUtf8();
    final r = generated.dart_lua_shim_loadstring(_ptr, ptr.cast());
    calloc.free(ptr);
    return r.value;
  }

  // 标准库
  void openLibs() => generated.dart_lua_shim_openlibs(_ptr);

  // 协程
  LuaState newThread() => LuaState._(generated.dart_lua_shim_newthread(_ptr));

  // GC
  int gc(int what, int data) =>
      generated.dart_lua_shim_gc(_ptr, generated.lua_shim_gc.fromValue(what), data);

  // 错误
  int error() => generated.dart_lua_shim_error(_ptr).value;
  int throwString(String s) {
    final ptr = s.toNativeUtf8();
    final r = generated.dart_lua_shim_throwstring(_ptr, ptr.cast());
    calloc.free(ptr);
    return r.value;
  }

  // 元表
  bool getMetatable(int objindex) => generated.dart_lua_shim_getmetatable(_ptr, objindex) != 0;
  void setMetatable(int objindex) => generated.dart_lua_shim_setmetatable(_ptr, objindex);

  // Registry 引用
  int ref(int t) => generated.dart_lua_shim_ref(_ptr, t);
  void unref(int t, int ref) => generated.dart_lua_shim_unref(_ptr, t, ref);

  // 算术
  void arith(int op) =>
      generated.dart_lua_shim_arith(_ptr, generated.lua_shim_arith.fromValue(op));

  bool compare(int idx1, int idx2, int op) =>
      generated.dart_lua_shim_compare(
            _ptr,
            idx1,
            idx2,
            generated.lua_shim_compare.fromValue(op),
          ) !=
          0;

  void len(int idx) => generated.dart_lua_shim_len(_ptr, idx);
  void concat(int n) => generated.dart_lua_shim_concat(_ptr, n);

  // 获取底层指针（用于高级 FFI 场景）
  Pointer<generated.lua_State> get ptr => _ptr;

  /// 获取最后一次 shim 层错误信息（如调用了版本不支持的 API）。
  String lastError() {
    final ptr = generated.dart_lua_shim_lasterror();
    return ptr.cast<Utf8>().toDartString();
  }
}
