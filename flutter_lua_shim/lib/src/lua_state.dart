import 'dart:ffi';
import 'dart:typed_data';
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

  // 索引转换
  int absIndex(int idx) => generated.dart_lua_shim_absindex(_ptr, idx);

  // 调用相关
  void call(int nargs, int nresults) => generated.dart_lua_shim_call(_ptr, nargs, nresults);
  void callK(int nargs, int nresults, int ctx, Pointer<Void> k) =>
      generated.dart_lua_shim_callk(_ptr, nargs, nresults, ctx, k);
  
  /// 保护模式调用，返回状态枚举
  generated.lua_shim_status pCallStatus(int nargs, int nresults, {int errfunc = 0}) =>
      generated.dart_lua_shim_pcall(_ptr, nargs, nresults, errfunc);
  
  void pCallK(int nargs, int nresults, int errfunc, int ctx, Pointer<Void> k) =>
      generated.dart_lua_shim_pcallk(_ptr, nargs, nresults, errfunc, ctx, k);

  /// 加载字符串，返回状态枚举
  generated.lua_shim_status loadStringStatus(String code) {
    final ptr = code.toNativeUtf8();
    final r = generated.dart_lua_shim_loadstring(_ptr, ptr.cast());
    calloc.free(ptr);
    return r;
  }

  int status() => generated.dart_lua_shim_status(_ptr).value;

  // 协程
  int pushThread() => generated.dart_lua_shim_pushthread(_ptr);
  
  generated.lua_shim_status resume(LuaState from, int narg, Pointer<Int> nres) =>
      generated.dart_lua_shim_resume(_ptr, from._ptr, narg, nres);
  
  int yield(int nresults) => generated.dart_lua_shim_yield(_ptr, nresults);
  
  generated.lua_shim_status yieldK(int nresults, int ctx, Pointer<Void> k) =>
      generated.dart_lua_shim_yieldk(_ptr, nresults, ctx, k);
  
  int resetThread() => generated.dart_lua_shim_resetthread(_ptr).value;
  
  int isYieldable() => generated.dart_lua_shim_isyieldable(_ptr);
  
  int closeThread(LuaState from) => generated.dart_lua_shim_closethread(_ptr, from._ptr);
  
  void closeSlot(int idx) {
    final result = generated.dart_lua_shim_closeslot(_ptr, idx);
    if (result.error != nullptr) {
      final error = result.error.cast<Utf8>().toDartString();
      throw Exception('closeSlot failed: $error');
    }
  }

  // 栈操作
  void rotate(int idx, int n) => generated.dart_lua_shim_rotate(_ptr, idx, n);
  void xMove(LuaState to, int n) => generated.dart_lua_shim_xmove(_ptr, to._ptr, n);

  // 类型检查补充
  bool isNone(int idx) => generated.dart_lua_shim_isnone(_ptr, idx) != 0;
  bool isNoneOrNil(int idx) => generated.dart_lua_shim_isnoneornil(_ptr, idx) != 0;
  bool isLightUserdata(int idx) => generated.dart_lua_shim_islightuserdata(_ptr, idx);
  int isInteger(int idx) => generated.dart_lua_shim_isinteger(_ptr, idx);

  // 取值补充
  double toNumber(int idx) => generated.dart_lua_shim_tonumber(_ptr, idx);
  int toInteger(int idx) => generated.dart_lua_shim_tointeger(_ptr, idx);
  String toStringValue(int idx) {
    final ptr = generated.dart_lua_shim_tostring(_ptr, idx);
    return ptr.cast<Utf8>().toDartString();
  }
  Pointer<Void> toCFunction(int idx) => generated.dart_lua_shim_tocfunction(_ptr, idx);
  Pointer<Void> toPointer(int idx) => generated.dart_lua_shim_topointer(_ptr, idx);

  void toClose(int idx) {
    final result = generated.dart_lua_shim_toclose(_ptr, idx);
    if (result.error != nullptr) {
      final error = result.error.cast<Utf8>().toDartString();
      throw Exception('toClose failed: $error');
    }
  }

  // 压栈补充
  void pushCClosure(Pointer<Void> fn, int n) =>
      generated.dart_lua_shim_pushcclosure(_ptr, fn, n);
  
  void pushCFunction(Pointer<Void> f) =>
      generated.dart_lua_shim_pushcfunction(_ptr, f);
  
  void pushDartFunction(generated.DartCFunction f) =>
      generated.dart_lua_shim_pushdartfunction(_ptr, f);
  
  String pushExternalString(String s, Pointer<Void> ud) {
    final bytes = s.toNativeUtf8();
    final ptr = generated.dart_lua_shim_pushexternalstring(_ptr, bytes.cast(), bytes.length, ud);
    calloc.free(bytes);
    return ptr.cast<Utf8>().toDartString();
  }
  
  String pushFString(String fmt) {
    final ptr = fmt.toNativeUtf8();
    final result = generated.dart_lua_shim_pushfstring(_ptr, ptr.cast());
    calloc.free(ptr);
    return result.cast<Utf8>().toDartString();
  }
  
  void pushGlobalTable() => generated.dart_lua_shim_pushglobaltable(_ptr);
  
  String pushLiteral(String s) {
    final ptr = s.toNativeUtf8();
    final result = generated.dart_lua_shim_pushliteral(_ptr, ptr.cast());
    calloc.free(ptr);
    return result.cast<Utf8>().toDartString();
  }
  
  String pushVFString(String fmt, Pointer<Void> argp) {
    final ptr = fmt.toNativeUtf8();
    final result = generated.dart_lua_shim_pushvfstring(_ptr, ptr.cast(), argp);
    calloc.free(ptr);
    return result.cast<Utf8>().toDartString();
  }

  // 表操作补充
  void rawGetP(int idx, Pointer<Void> p) =>
      generated.dart_lua_shim_rawgetp(_ptr, idx, p);
  
  void rawSetP(int idx, Pointer<Void> p) =>
      generated.dart_lua_shim_rawsetp(_ptr, idx, p);
  
  void getI(int idx, int n) => generated.dart_lua_shim_geti(_ptr, idx, n);
  
  void setI(int idx, int n) => generated.dart_lua_shim_seti(_ptr, idx, n);
  
  int next(int idx) => generated.dart_lua_shim_next(_ptr, idx);

  // 元表补充
  int getMetatableByName(String tname) {
    final ptr = tname.toNativeUtf8();
    final result = generated.dart_lua_shimL_getmetatable(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  void setMetatableByName(String tname) {
    final ptr = tname.toNativeUtf8();
    generated.dart_lua_shimL_setmetatable(_ptr, ptr.cast());
    calloc.free(ptr);
  }

  // 用户数据
  Pointer<Void> newUserdata(int sz) =>
      generated.dart_lua_shim_newuserdata(_ptr, sz);
  
  Pointer<Void> newUserdataUV(int sz, int nuvalue) =>
      generated.dart_lua_shim_newuserdatauv(_ptr, sz, nuvalue);
  
  void getUserValue(int idx) => generated.dart_lua_shim_getuservalue(_ptr, idx);
  
  void setUserValue(int idx) => generated.dart_lua_shim_setuservalue(_ptr, idx);
  
  void getIUserValue(int idx, int n) =>
      generated.dart_lua_shim_getiuservalue(_ptr, idx, n);
  
  void setIUserValue(int idx, int n) =>
      generated.dart_lua_shim_setiuservalue(_ptr, idx, n);

  // Upvalue
  String getUpvalue(int funcindex, int n) {
    final ptr = generated.dart_lua_shim_getupvalue(_ptr, funcindex, n);
    return ptr.cast<Utf8>().toDartString();
  }
  
  String setUpvalue(int funcindex, int n) {
    final ptr = generated.dart_lua_shim_setupvalue(_ptr, funcindex, n);
    return ptr.cast<Utf8>().toDartString();
  }
  
  int upvalueIndex(int i) => generated.dart_lua_shim_upvalueindex(i);
  
  Pointer<Void> upvalueId(int fidx, int n) =>
      generated.dart_lua_shim_upvalueid(_ptr, fidx, n);
  
  void upvalueJoin(int fidx1, int n1, int fidx2, int n2) =>
      generated.dart_lua_shim_upvaluejoin(_ptr, fidx1, n1, fidx2, n2);

  // 调试
  Pointer<Void> getHook() => generated.dart_lua_shim_gethook(_ptr);
  int getHookCount() => generated.dart_lua_shim_gethookcount(_ptr);
  int getHookMask() => generated.dart_lua_shim_gethookmask(_ptr);
  
  int setHook(Pointer<Void> func, int mask, int count) =>
      generated.dart_lua_shim_sethook(_ptr, func, mask, count);
  
  int getStack(int level, Pointer<Void> ar) =>
      generated.dart_lua_shim_getstack(_ptr, level, ar);
  
  int getInfo(String what, Pointer<Void> ar) {
    final ptr = what.toNativeUtf8();
    final result = generated.dart_lua_shim_getinfo(_ptr, ptr.cast(), ar);
    calloc.free(ptr);
    return result;
  }
  
  String getLocal(Pointer<Void> ar, int n) {
    final ptr = generated.dart_lua_shim_getlocal(_ptr, ar, n);
    return ptr.cast<Utf8>().toDartString();
  }
  
  String setLocal(Pointer<Void> ar, int n) {
    final ptr = generated.dart_lua_shim_setlocal(_ptr, ar, n);
    return ptr.cast<Utf8>().toDartString();
  }

  // 内存管理
  Pointer<Void> getAllocF(Pointer<Pointer<Void>> ud) =>
      generated.dart_lua_shim_getallocf(_ptr, ud);
  
  void setAllocF(Pointer<Void> f, Pointer<Void> ud) =>
      generated.dart_lua_shim_setallocf(_ptr, f, ud);
  
  Pointer<Void> getExtraSpace() => generated.dart_lua_shim_getextraspace(_ptr);

  // Panic
  Pointer<Void> atPanic(Pointer<Void> panicf) =>
      generated.dart_lua_shim_atpanic(_ptr, panicf);

  // Dump
  int dump(Pointer<Void> writer, Pointer<Void> data, int strip) =>
      generated.dart_lua_shim_dump(_ptr, writer, data, strip);

  // Load
  int load(Pointer<Void> reader, Pointer<Void> dt, String chunkname, String mode) {
    final chunknamePtr = chunkname.toNativeUtf8();
    final modePtr = mode.toNativeUtf8();
    final result = generated.dart_lua_shim_load(_ptr, reader, dt, chunknamePtr.cast(), modePtr.cast());
    calloc.free(chunknamePtr);
    calloc.free(modePtr);
    return result;
  }

  // 字符串转数字
  int stringToNumber(String s) {
    final ptr = s.toNativeUtf8();
    final result = generated.dart_lua_shim_stringtonumber(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  String numberToCString(double n) {
    final len = calloc<Size>();
    final ptr = generated.dart_lua_shim_numbertocstring(_ptr, n, len);
    final s = ptr.cast<Utf8>().toDartString(length: len.value);
    calloc.free(len);
    return s;
  }
  
  int numberToInteger(double n, Pointer<Int64> p) =>
      generated.dart_lua_shim_numbertointeger(n, p);

  // 原始相等
  int rawEqual(int idx1, int idx2) =>
      generated.dart_lua_shim_rawequal(_ptr, idx1, idx2);

  // Register
  void register(String n, Pointer<Void> f) {
    final ptr = n.toNativeUtf8();
    generated.dart_lua_shim_register(_ptr, ptr.cast(), f);
    calloc.free(ptr);
  }

  // 警告
  void warning(String msg, int tocont) {
    final ptr = msg.toNativeUtf8();
    generated.dart_lua_shim_warning(_ptr, ptr.cast(), tocont);
    calloc.free(ptr);
  }
  
  void setWarnF(Pointer<Void> f, Pointer<Void> ud) {
    final result = generated.dart_lua_shim_setwarnf(_ptr, f, ud);
    if (result.error != nullptr) {
      final error = result.error.cast<Utf8>().toDartString();
      throw Exception('setWarnF failed: $error');
    }
  }

  // 版本
  double version() => generated.dart_lua_shim_version(_ptr);

  // 标准库单独打开
  void openBase() => generated.dart_lua_shim_open_base(_ptr);
  void openDebug() => generated.dart_lua_shim_open_debug(_ptr);
  void openIo() => generated.dart_lua_shim_open_io(_ptr);
  void openMath() => generated.dart_lua_shim_open_math(_ptr);
  void openOs() => generated.dart_lua_shim_open_os(_ptr);
  void openPackage() => generated.dart_lua_shim_open_package(_ptr);
  void openString() => generated.dart_lua_shim_open_string(_ptr);
  void openTable() => generated.dart_lua_shim_open_table(_ptr);
  void openUtf8() => generated.dart_lua_shim_open_utf8(_ptr);

  // ========== 辅助库 (luaL) ==========

  // 字符串缓冲区
  void addChar(Pointer<Void> B, int c) =>
      generated.dart_lua_shimL_addchar(B, c);
  
  void addGSub(Pointer<Void> B, String s, String p, String r) {
    final sPtr = s.toNativeUtf8();
    final pPtr = p.toNativeUtf8();
    final rPtr = r.toNativeUtf8();
    final result = generated.dart_lua_shimL_addgsub(B, sPtr.cast(), pPtr.cast(), rPtr.cast());
    calloc.free(sPtr);
    calloc.free(pPtr);
    calloc.free(rPtr);
    if (result.error != nullptr) {
      final error = result.error.cast<Utf8>().toDartString();
      throw Exception('addGSub failed: $error');
    }
  }
  
  void addLString(Pointer<Void> B, String s, int l) {
    final ptr = s.toNativeUtf8();
    generated.dart_lua_shimL_addlstring(B, ptr.cast(), l);
    calloc.free(ptr);
  }
  
  void addSize(Pointer<Void> B, int n) =>
      generated.dart_lua_shimL_addsize(B, n);
  
  void addString(Pointer<Void> B, String s) {
    final ptr = s.toNativeUtf8();
    generated.dart_lua_shimL_addstring(B, ptr.cast());
    calloc.free(ptr);
  }
  
  void addValue(Pointer<Void> B) =>
      generated.dart_lua_shimL_addvalue(B);
  
  Pointer<Char> buffAddr(Pointer<Void> B) =>
      generated.dart_lua_shimL_buffaddr(B);
  
  void buffInit(Pointer<Void> B) =>
      generated.dart_lua_shimL_buffinit(_ptr, B);
  
  Pointer<Char> buffInitSize(Pointer<Void> B, int sz) =>
      generated.dart_lua_shimL_buffinitsize(_ptr, B, sz);
  
  int buffLen(Pointer<Void> B) =>
      generated.dart_lua_shimL_bufflen(B);
  
  void buffSub(Pointer<Void> B, int n) {
    final result = generated.dart_lua_shimL_buffsub(B, n);
    if (result.error != nullptr) {
      final error = result.error.cast<Utf8>().toDartString();
      throw Exception('buffSub failed: $error');
    }
  }
  
  Pointer<Char> prepBuffer(Pointer<Void> B) =>
      generated.dart_lua_shimL_prepbuffer(B);
  
  Pointer<Char> prepBuffSize(Pointer<Void> B, int sz) =>
      generated.dart_lua_shimL_prepbuffsize(B, sz);
  
  void pushResult(Pointer<Void> B) =>
      generated.dart_lua_shimL_pushresult(B);
  
  void pushResultSize(Pointer<Void> B, int sz) =>
      generated.dart_lua_shimL_pushresultsize(B, sz);

  // 参数检查
  void argCheck(bool cond, int arg, String extramsg) {
    final ptr = extramsg.toNativeUtf8();
    generated.dart_lua_shimL_argcheck(_ptr, cond ? 1 : 0, arg, ptr.cast());
    calloc.free(ptr);
  }
  
  int argError(int arg, String extramsg) {
    final ptr = extramsg.toNativeUtf8();
    final result = generated.dart_lua_shimL_argerror(_ptr, arg, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  void argExpected(bool cond, int arg, String tname) {
    final ptr = tname.toNativeUtf8();
    final result = generated.dart_lua_shimL_argexpected(_ptr, cond ? 1 : 0, arg, ptr.cast());
    calloc.free(ptr);
    if (result.error != nullptr) {
      final error = result.error.cast<Utf8>().toDartString();
      throw Exception('argExpected failed: $error');
    }
  }
  
  void checkAny(int arg) => generated.dart_lua_shimL_checkany(_ptr, arg);
  
  int checkInteger(int arg) =>
      generated.dart_lua_shimL_checkinteger(_ptr, arg);
  
  String checkLString(int arg) {
    final l = calloc<Size>();
    final ptr = generated.dart_lua_shimL_checklstring(_ptr, arg, l);
    final s = ptr.cast<Utf8>().toDartString(length: l.value);
    calloc.free(l);
    return s;
  }
  
  double checkNumber(int arg) =>
      generated.dart_lua_shimL_checknumber(_ptr, arg);
  
  int checkOption(int arg, String def, List<String> lst) {
    final defPtr = def.toNativeUtf8();
    final lstPtrs = lst.map((s) => s.toNativeUtf8()).toList();
    final lstArray = calloc<Pointer<Char>>(lst.length + 1);
    for (int i = 0; i < lst.length; i++) {
      lstArray[i] = lstPtrs[i].cast();
    }
    lstArray[lst.length] = nullptr;
    final result = generated.dart_lua_shimL_checkoption(_ptr, arg, defPtr.cast(), lstArray);
    calloc.free(defPtr);
    for (final ptr in lstPtrs) {
      calloc.free(ptr);
    }
    calloc.free(lstArray);
    return result;
  }
  
  void checkStackL(int sz, String msg) {
    final ptr = msg.toNativeUtf8();
    generated.dart_lua_shimL_checkstack(_ptr, sz, ptr.cast());
    calloc.free(ptr);
  }
  
  String checkString(int arg) {
    final ptr = generated.dart_lua_shimL_checkstring(_ptr, arg);
    return ptr.cast<Utf8>().toDartString();
  }
  
  void checkType(int arg, int t) =>
      generated.dart_lua_shimL_checktype(_ptr, arg, t);
  
  Pointer<Void> checkUdata(int ud, String tname) {
    final ptr = tname.toNativeUtf8();
    final result = generated.dart_lua_shimL_checkudata(_ptr, ud, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  void checkVersion() => generated.dart_lua_shimL_checkversion(_ptr);

  // 执行
  int doFile(String fn) {
    final ptr = fn.toNativeUtf8();
    final result = generated.dart_lua_shimL_dofile(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  int doString(String s) {
    final ptr = s.toNativeUtf8();
    final result = generated.dart_lua_shimL_dostring(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  int errorL(String fmt) {
    final ptr = fmt.toNativeUtf8();
    final result = generated.dart_lua_shimL_error(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  int execResult(int stat) =>
      generated.dart_lua_shimL_execresult(_ptr, stat);
  
  int fileResult(int stat, String fname) {
    final ptr = fname.toNativeUtf8();
    final result = generated.dart_lua_shimL_fileresult(_ptr, stat, ptr.cast());
    calloc.free(ptr);
    return result;
  }

  // 元表
  int callMeta(int obj, String e) {
    final ptr = e.toNativeUtf8();
    final result = generated.dart_lua_shimL_callmeta(_ptr, obj, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  int getMetaField(int obj, String e) {
    final ptr = e.toNativeUtf8();
    final result = generated.dart_lua_shimL_getmetafield(_ptr, obj, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  int getSubTable(int idx, String fname) {
    final ptr = fname.toNativeUtf8();
    final result = generated.dart_lua_shimL_getsubtable(_ptr, idx, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  String gSub(String s, String p, String r) {
    final sPtr = s.toNativeUtf8();
    final pPtr = p.toNativeUtf8();
    final rPtr = r.toNativeUtf8();
    final result = generated.dart_lua_shimL_gsub(_ptr, sPtr.cast(), pPtr.cast(), rPtr.cast());
    calloc.free(sPtr);
    calloc.free(pPtr);
    calloc.free(rPtr);
    return result.cast<Utf8>().toDartString();
  }
  
  int lenL(int idx) => generated.dart_lua_shimL_len(_ptr, idx);

  // 加载
  int loadBuffer(String buff, int sz, String name) {
    final buffPtr = buff.toNativeUtf8();
    final namePtr = name.toNativeUtf8();
    final result = generated.dart_lua_shimL_loadbuffer(_ptr, buffPtr.cast(), sz, namePtr.cast());
    calloc.free(buffPtr);
    calloc.free(namePtr);
    return result;
  }
  
  int loadBufferX(String buff, int sz, String name, String mode) {
    final buffPtr = buff.toNativeUtf8();
    final namePtr = name.toNativeUtf8();
    final modePtr = mode.toNativeUtf8();
    final result = generated.dart_lua_shimL_loadbufferx(_ptr, buffPtr.cast(), sz, namePtr.cast(), modePtr.cast());
    calloc.free(buffPtr);
    calloc.free(namePtr);
    calloc.free(modePtr);
    return result;
  }
  
  int loadFile(String filename) {
    final ptr = filename.toNativeUtf8();
    final result = generated.dart_lua_shimL_loadfile(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  int loadFileX(String filename, String mode) {
    final filenamePtr = filename.toNativeUtf8();
    final modePtr = mode.toNativeUtf8();
    final result = generated.dart_lua_shimL_loadfilex(_ptr, filenamePtr.cast(), modePtr.cast());
    calloc.free(filenamePtr);
    calloc.free(modePtr);
    return result;
  }
  
  int loadStringL(String s) {
    final ptr = s.toNativeUtf8();
    final result = generated.dart_lua_shimL_loadstring(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }

  // 库
  int makeSeed() => generated.dart_lua_shimL_makeseed(_ptr);
  
  void newLib(Pointer<Void> l, int nrec) =>
      generated.dart_lua_shimL_newlib(_ptr, l, nrec);
  
  void newLibTable(int nrec) =>
      generated.dart_lua_shimL_newlibtable(_ptr, nrec);
  
  int newMetatable(String tname) {
    final ptr = tname.toNativeUtf8();
    final result = generated.dart_lua_shimL_newmetatable(_ptr, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  LuaState lNewState() => LuaState._(generated.dart_lua_shimL_newstate());
  
  void openLibsL() => generated.dart_lua_shimL_openlibs(_ptr);
  
  void openSelectedLibs(String libs) {
    final ptr = libs.toNativeUtf8();
    final result = generated.dart_lua_shimL_openselectedlibs(_ptr, ptr.cast());
    calloc.free(ptr);
    if (result.error != nullptr) {
      final error = result.error.cast<Utf8>().toDartString();
      throw Exception('openSelectedLibs failed: $error');
    }
  }

  // 可选参数
  Pointer<Void> opt(Pointer<Void> f, int n, Pointer<Void> d) =>
      generated.dart_lua_shimL_opt(_ptr, f, n, d);
  
  int optInteger(int arg, int def) =>
      generated.dart_lua_shimL_optinteger(_ptr, arg, def);
  
  String optLString(int arg, String def) {
    final defPtr = def.toNativeUtf8();
    final l = calloc<Size>();
    final ptr = generated.dart_lua_shimL_optlstring(_ptr, arg, defPtr.cast(), l);
    final s = ptr.cast<Utf8>().toDartString(length: l.value);
    calloc.free(defPtr);
    calloc.free(l);
    return s;
  }
  
  double optNumber(int arg, double def) =>
      generated.dart_lua_shimL_optnumber(_ptr, arg, def);
  
  String optString(int arg, String def) {
    final defPtr = def.toNativeUtf8();
    final ptr = generated.dart_lua_shimL_optstring(_ptr, arg, defPtr.cast());
    calloc.free(defPtr);
    return ptr.cast<Utf8>().toDartString();
  }

  // Push
  void pushFail() => generated.dart_lua_shimL_pushfail(_ptr);

  // 引用
  int lRef(int t) => generated.dart_lua_shimL_ref(_ptr, t);
  
  void lUnref(int t, int ref) =>
      generated.dart_lua_shimL_unref(_ptr, t, ref);
  
  void requireF(String modname, Pointer<Void> openf, int glb) {
    final ptr = modname.toNativeUtf8();
    generated.dart_lua_shimL_requiref(_ptr, ptr.cast(), openf, glb);
    calloc.free(ptr);
  }
  
  void setFuncs(Pointer<Void> l, int nup) =>
      generated.dart_lua_shimL_setfuncs(_ptr, l, nup);
  
  Pointer<Void> testUdata(int ud, String tname) {
    final ptr = tname.toNativeUtf8();
    final result = generated.dart_lua_shimL_testudata(_ptr, ud, ptr.cast());
    calloc.free(ptr);
    return result;
  }
  
  String lToLString(int idx) {
    final len = calloc<Size>();
    final ptr = generated.dart_lua_shimL_tolstring(_ptr, idx, len);
    final s = ptr.cast<Utf8>().toDartString(length: len.value);
    calloc.free(len);
    return s;
  }
  
  void traceback(LuaState l1, String msg, int level) {
    final msgPtr = msg.toNativeUtf8();
    generated.dart_lua_shimL_traceback(_ptr, l1._ptr, msgPtr.cast(), level);
    calloc.free(msgPtr);
  }
  
  int typeError(int arg, String tname) {
    final ptr = tname.toNativeUtf8();
    final result = generated.dart_lua_shimL_typeerror(_ptr, arg, ptr.cast());
    calloc.free(ptr);
    return result.value;
  }
  
  String lTypeName(int idx) {
    final ptr = generated.dart_lua_shimL_typename(_ptr, idx);
    return ptr.cast<Utf8>().toDartString();
  }
  
  void where(int lvl) => generated.dart_lua_shimL_where(_ptr, lvl);

  // 获取底层指针（用于高级 FFI 场景）
  Pointer<generated.lua_State> get ptr => _ptr;

  /// 获取最后一次 shim 层错误信息（如调用了版本不支持的 API）。
  String lastError() {
    final ptr = generated.dart_lua_shim_lasterror();
    return ptr.cast<Utf8>().toDartString();
  }
}
