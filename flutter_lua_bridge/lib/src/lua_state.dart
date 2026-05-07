import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;

import 'gen/flutter_lua_bridge.g.dart' as flb;
import 'raw/lua_c_api.dart';
import 'raw/lua_aux_api.dart';
import 'flutter_lua_bridge.dart';
import 'lua_status.dart';

/// 对用户友好的 Lua State 高层封装。
///
/// 将 [ffi.Pointer]<[flb.lua_State]>、字符串内存转换、以及常见的
/// C 宏/辅助操作隐藏在此类内部，使 Dart 侧代码更加安全和易读。
class LuaState {
  LuaState._(this._L);

  final ffi.Pointer<flb.lua_State> _L;
  final LuaCApi _c = FlutterLuaBridge.cApi;
  final LuaAuxApi _aux = FlutterLuaBridge.auxApi;

  /// 内部原始指针，仅在需要直接调用底层 API 时使用。
  ffi.Pointer<flb.lua_State> get rawState => _L;

  // ==================== 生命周期 ====================

  /// 创建一个新的 Lua 状态。
  static LuaState newState() {
    final L = FlutterLuaBridge.auxApi.luaL_newstate();
    return LuaState._(L);
  }

  /// 关闭 Lua 状态，释放所有资源。
  void close() => _c.lua_close(_L);

  /// 打开所有标准库。
  void openLibs() => _aux.luaL_openlibs(_L);

  // ==================== 栈操作 ====================

  /// 返回栈顶索引（即元素个数）。
  int get getTop => _c.lua_gettop(_L);

  /// 设置栈顶为 [idx]。
  /// 正数索引表示保留到该位置，负数或 0 表示弹出相应数量的元素。
  void setTop(int idx) => _c.lua_settop(_L, idx);

  /// 弹出栈顶 [n] 个元素。
  void pop(int n) => _c.lua_pop(_L, n);

  /// 将 [index] 处的值压入栈顶。
  void pushValue(int index) => _c.lua_pushvalue(_L, index);

  /// 将栈顶元素移动到 [index] 处，并将其从原位置移除。
  void insert(int index) => _c.lua_insert(_L, index);

  /// 移除 [index] 处的元素。
  void remove(int index) => _c.lua_remove(_L, index);

  /// 用栈顶值替换 [index] 处的值，并弹出栈顶。
  void replace(int index) => _c.lua_replace(_L, index);

  /// 旋转栈中从 [index] 到栈顶的 [n] 个元素。
  void rotate(int index, int n) => _c.lua_rotate(_L, index, n);

  /// 将 [fromidx] 处的值复制到 [toidx]。
  void copy(int fromidx, int toidx) => _c.lua_copy(_L, fromidx, toidx);

  /// 检查栈是否还有足够的空间容纳 [n] 个额外元素。
  bool checkStack(int n) => _c.lua_checkstack(_L, n) != 0;

  /// 交换两个 Lua 状态之间的 [n] 个值。
  static void xmove(LuaState from, LuaState to, int n) =>
      _cFrom().lua_xmove(from._L, to._L, n);

  static LuaCApi _cFrom() => FlutterLuaBridge.cApi;

  // ==================== 压栈（Push） ====================

  /// 将 nil 压入栈。
  void pushNil() => _c.lua_pushnil(_L);

  /// 将布尔值 [b] 压入栈。
  void pushBoolean(bool b) => _c.lua_pushboolean(_L, b ? 1 : 0);

  /// 将整数 [n] 压入栈。
  void pushInteger(int n) => _c.lua_pushinteger(_L, n);

  /// 将浮点数 [n] 压入栈。
  void pushNumber(double n) => _c.lua_pushnumber(_L, n);

  /// 将 Dart [String] 压入栈。
  void pushString(String s) {
    pkg_ffi.using((arena) {
      final ptr = s.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      _c.lua_pushstring(_L, ptr);
    });
  }

  /// 将轻量用户数据 [p] 压入栈。
  void pushLightUserdata(ffi.Pointer<ffi.Void> p) =>
      _c.lua_pushlightuserdata(_L, p);

  /// 将当前线程压入栈，返回该线程是否为当前主线程。
  bool pushThread() => _c.lua_pushthread(_L) != 0;

  // ==================== 读取（To） ====================

  /// 将 [index] 处的值转为 bool。
  bool toBoolean(int index) => _c.lua_toboolean(_L, index) != 0;

  /// 将 [index] 处的值转为 int（如果不能转换则返回 0）。
  int toInteger(int index) => _c.lua_tointeger(_L, index);

  /// 将 [index] 处的值转为 double（如果不能转换则返回 0）。
  double toNumber(int index) => _c.lua_tonumber(_L, index);

  /// 将 [index] 处的值转为 [String]，失败返回 null。
  String? getString(int index) {
    return pkg_ffi.using((arena) {
      final len = arena<ffi.Size>();
      final ptr = _c.lua_tolstring(_L, index, len);
      if (ptr == ffi.nullptr) return null;
      return ptr.cast<pkg_ffi.Utf8>().toDartString(length: len.value);
    });
  }

  /// 将 [index] 处的值转为指针，失败返回 null。
  ffi.Pointer<ffi.Void>? toPointer(int index) {
    final p = _c.lua_topointer(_L, index);
    return p == ffi.nullptr ? null : p;
  }

  /// 将 [index] 处的值转为线程，失败返回 null。
  LuaState? toThread(int index) {
    final p = _c.lua_tothread(_L, index);
    return p == ffi.nullptr ? null : LuaState._(p);
  }

  /// 将 [index] 处的值转为 userdata 指针，失败返回 null。
  ffi.Pointer<ffi.Void>? toUserdata(int index) {
    final p = _c.lua_touserdata(_L, index);
    return p == ffi.nullptr ? null : p;
  }

  // ==================== 类型检查 ====================

  int type(int index) => _c.lua_type(_L, index);

  String? typeName(int tp) {
    final ptr = _c.lua_typename(_L, tp);
    if (ptr == ffi.nullptr) return null;
    return ptr.cast<pkg_ffi.Utf8>().toDartString();
  }

  String? typeNameAt(int index) => typeName(type(index));

  bool isNil(int index) => _c.lua_isnil(_L, index) != 0;
  bool isNone(int index) => _c.lua_isnone(_L, index) != 0;
  bool isNoneOrNil(int index) => _c.lua_isnoneornil(_L, index) != 0;
  bool isBoolean(int index) => _c.lua_isboolean(_L, index) != 0;
  bool isInteger(int index) => _c.lua_isinteger(_L, index) != 0;
  bool isNumber(int index) => _c.lua_isnumber(_L, index) != 0;
  bool isString(int index) => _c.lua_isstring(_L, index) != 0;
  bool isTable(int index) => _c.lua_istable(_L, index) != 0;
  bool isFunction(int index) => _c.lua_isfunction(_L, index) != 0;
  bool isCFunction(int index) => _c.lua_iscfunction(_L, index) != 0;
  bool isUserdata(int index) => _c.lua_isuserdata(_L, index) != 0;
  bool isLightUserdata(int index) => _c.lua_islightuserdata(_L, index) != 0;
  bool isThread(int index) => _c.lua_isthread(_L, index) != 0;

  // ==================== 全局变量 ====================

  /// 获取名为 [name] 的全局变量，并将其压入栈顶。返回该值的类型码。
  int getGlobal(String name) {
    return pkg_ffi.using((arena) {
      final ptr = name.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _c.lua_getglobal(_L, ptr);
    });
  }

  /// 将栈顶的值弹出，并设置为全局变量 [name]。
  void setGlobal(String name) {
    pkg_ffi.using((arena) {
      final ptr = name.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      _c.lua_setglobal(_L, ptr);
    });
  }

  // ==================== 表操作 ====================

  /// 创建一张空表并压入栈。
  void newTable() => _c.lua_newtable(_L);

  /// 创建一张预分配大小的新表。
  void createTable(int nseq, int nrec) => _c.lua_createtable(_L, nseq, nrec);

  /// 获取 [index] 处表的字段 [k]，将结果压入栈。
  int getField(int index, String k) {
    return pkg_ffi.using((arena) {
      final ptr = k.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _c.lua_getfield(_L, index, ptr);
    });
  }

  /// 设置 [index] 处表的字段 [k] 为栈顶值，并弹出栈顶。
  void setField(int index, String k) {
    pkg_ffi.using((arena) {
      final ptr = k.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      _c.lua_setfield(_L, index, ptr);
    });
  }

  /// 获取 [index] 处表的 [i] 号元素，将结果压入栈。
  int getI(int index, int i) => _c.lua_geti(_L, index, i);

  /// 设置 [index] 处表的 [i] 号元素为栈顶值，并弹出栈顶。
  void setI(int index, int i) => _c.lua_seti(_L, index, i);

  /// 获取 [index] 处表的元表。如果有则压入栈并返回 true，否则返回 false。
  bool getMetatable(int index) => _c.lua_getmetatable(_L, index) != 0;

  /// 将栈顶的表弹出，并设置为 [index] 处值的元表。
  void setMetatable(int index) => _c.lua_setmetatable(_L, index);

  /// 压入全局注册表中名为 [tname] 的元表。
  bool getMetatableByName(String tname) {
    return pkg_ffi.using((arena) {
      final ptr = tname.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return _aux.luaL_getmetatable(_L, ptr) != 0;
    });
  }

  // ==================== 调用与保护调用 ====================

  /// 调用栈顶的函数，传入 [nargs] 个参数，期望 [nresults] 个返回值。
  void call(int nargs, int nresults) => _c.lua_call(_L, nargs, nresults);

  /// 保护调用，出错时不 longjmp，而是将错误信息压栈并返回状态码。
  LuaStatusCode pcall(int nargs, int nresults, int msgh) =>
      LuaStatusCode(_c.lua_pcall(_L, nargs, nresults, msgh));

  // ==================== 辅助库：加载与执行 ====================

  /// 加载并执行 Lua 代码字符串 [code]。
  LuaStatusCode doString(String code) {
    return pkg_ffi.using((arena) {
      final ptr = code.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return LuaStatusCode(_aux.luaL_dostring(_L, ptr));
    });
  }

  /// 加载并执行 Lua 文件 [path]。
  LuaStatusCode doFile(String path) {
    return pkg_ffi.using((arena) {
      final ptr = path.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return LuaStatusCode(_aux.luaL_dofile(_L, ptr));
    });
  }

  /// 加载 Lua 代码字符串，不执行。成功后将函数压入栈。
  LuaStatusCode loadString(String s, {String? name}) {
    return pkg_ffi.using((arena) {
      final ptr = s.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      return LuaStatusCode(_aux.luaL_loadstring(_L, ptr));
    });
  }

  // ==================== 错误与工具 ====================

  /// 触发一个 Lua 错误，使用栈顶值作为错误对象。
  Never error() {
    _c.lua_error(_L);
    throw StateError('lua_error should never return');
  }

  /// 抛出格式化错误信息（底层为 C 的格式化字符串，此处仅传递单个字符串）。
  Never errorFmt(String msg) {
    pkg_ffi.using((arena) {
      final ptr = msg.toNativeUtf8(allocator: arena).cast<ffi.Char>();
      _aux.luaL_error(_L, ptr);
    });
    throw StateError('luaL_error should never return');
  }

  /// 检查参数 [arg] 的类型是否为 [t]，否则抛出错误。
  void checkType(int arg, int t) => _aux.luaL_checktype(_L, arg, t);

  /// 检查栈上是否有至少 [sz] 个额外空间，否则抛出错误。
  void checkStackAux(int sz, {String? msg}) {
    pkg_ffi.using((arena) {
      final ptr = msg != null
          ? msg.toNativeUtf8(allocator: arena).cast<ffi.Char>()
          : ffi.nullptr;
      _aux.luaL_checkstack(_L, sz, ptr);
    });
  }

  /// 将 [index] 处的值转为字符串并压入栈，返回字符串指针（一般不需要直接使用）。
  String? lToString(int index) => getString(index);

  /// 连接栈顶的 [n] 个值。
  void concat(int n) => _c.lua_concat(_L, n);

  /// 获取 [index] 处值的长度，并将结果压入栈。
  void len(int index) => _c.lua_len(_L, index);

  /// 返回 [index] 处值的长度（不压栈）。
  int rawLen(int index) => _c.lua_rawlen(_L, index);

  // ==================== GC ====================

  int gc(int what) => _c.lua_gc(_L, what);
}
