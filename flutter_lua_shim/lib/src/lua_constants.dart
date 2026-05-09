// 以下常量值与 src/lua_api_types.h 中的 C 枚举严格对应。
// ffigen 运行时也会生成同名 Dart enum（lua_shim_type / lua_shim_status 等），
// 此处保留 friendly wrapper 常量名，方便 Dart 侧直接使用。

// Lua 类型常量
class LuaType {
  static const int none = -1; // LUA_SHIM_TNONE
  static const int nil = 0; // LUA_SHIM_TNIL
  static const int boolean = 1; // LUA_SHIM_TBOOLEAN
  static const int lightUserdata = 2; // LUA_SHIM_TLIGHTUSERDATA
  static const int number = 3; // LUA_SHIM_TNUMBER
  static const int string = 4; // LUA_SHIM_TSTRING
  static const int table = 5; // LUA_SHIM_TTABLE
  static const int function = 6; // LUA_SHIM_TFUNCTION
  static const int userdata = 7; // LUA_SHIM_TUSERDATA
  static const int thread = 8; // LUA_SHIM_TTHREAD
}

// Lua 状态码
class LuaStatus {
  static const int ok = 0; // LUA_SHIM_OK
  static const int yield = 1; // LUA_SHIM_YIELD
  static const int errRun = 2; // LUA_SHIM_ERRRUN
  static const int errSyntax = 3; // LUA_SHIM_ERRSYNTAX
  static const int errMem = 4; // LUA_SHIM_ERRMEM
  static const int errGcmm = 5; // LUA_SHIM_ERRGCMM
  static const int errErr = 6; // LUA_SHIM_ERRERR
  static const int errNotSup = 7; // LUA_SHIM_ERRNOTSUP
}

// GC 操作
class LuaGC {
  static const int stop = 0; // LUA_SHIM_GC_STOP
  static const int restart = 1; // LUA_SHIM_GC_RESTART
  static const int collect = 2; // LUA_SHIM_GC_COLLECT
  static const int count = 3; // LUA_SHIM_GC_COUNT
  static const int countb = 4; // LUA_SHIM_GC_COUNTB
  static const int step = 5; // LUA_SHIM_GC_STEP
  static const int setpause = 6; // LUA_SHIM_GC_SETPAUSE
  static const int setstepmul = 7; // LUA_SHIM_GC_SETSTEPMUL
  static const int isrunning = 9; // LUA_SHIM_GC_ISRUNNING
}

// 算术操作
class LuaArith {
  static const int add = 0; // LUA_SHIM_OPADD
  static const int sub = 1; // LUA_SHIM_OPSUB
  static const int mul = 2; // LUA_SHIM_OPMUL
  static const int mod = 3; // LUA_SHIM_OPMOD
  static const int pow = 4; // LUA_SHIM_OPPOW
  static const int div = 5; // LUA_SHIM_OPDIV
  static const int idiv = 6; // LUA_SHIM_OPIDIV
  static const int band = 7; // LUA_SHIM_OPBAND
  static const int bor = 8; // LUA_SHIM_OPBOR
  static const int bxor = 9; // LUA_SHIM_OPBXOR
  static const int shl = 10; // LUA_SHIM_OPSHL
  static const int shr = 11; // LUA_SHIM_OPSHR
  static const int unm = 12; // LUA_SHIM_OPUNM
  static const int bnot = 13; // LUA_SHIM_OPBNOT
}

// 比较操作
class LuaCompare {
  static const int eq = 0; // LUA_SHIM_OPEQ
  static const int lt = 1; // LUA_SHIM_OPLT
  static const int le = 2; // LUA_SHIM_OPLE
}

// Registry 索引
class LuaRegistry {
  static const int index = -1001000; // LUA_REGISTRYINDEX
}
