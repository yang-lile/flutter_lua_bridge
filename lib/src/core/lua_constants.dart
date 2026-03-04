// ignore_for_file: constant_identifier_names

/// Lua 常量定义
///
/// 这些常量对应 Lua C API 中的宏定义
/// 参考: https://www.lua.org/manual/5.4/manual.html

/// 栈操作常量
const int LUA_MULTRET = -1;

/// Lua 类型常量
class LuaType {
  LuaType._();

  static const int NONE = -1;
  static const int NIL = 0;
  static const int BOOLEAN = 1;
  static const int LIGHTUSERDATA = 2;
  static const int NUMBER = 3;
  static const int STRING = 4;
  static const int TABLE = 5;
  static const int FUNCTION = 6;
  static const int USERDATA = 7;
  static const int THREAD = 8;
  static const int NUMTYPES = 9;

  /// 获取类型名称
  static String getName(int type) {
    switch (type) {
      case NONE:
        return 'none';
      case NIL:
        return 'nil';
      case BOOLEAN:
        return 'boolean';
      case LIGHTUSERDATA:
        return 'lightuserdata';
      case NUMBER:
        return 'number';
      case STRING:
        return 'string';
      case TABLE:
        return 'table';
      case FUNCTION:
        return 'function';
      case USERDATA:
        return 'userdata';
      case THREAD:
        return 'thread';
      default:
        return 'unknown';
    }
  }
}

/// Lua 状态线程状态
class LuaStatus {
  LuaStatus._();

  static const int OK = 0;
  static const int YIELD = 1;
  static const int ERRRUN = 2;
  static const int ERRSYNTAX = 3;
  static const int ERRMEM = 4;
  static const int ERRERR = 5;

  /// 获取状态描述
  static String getDescription(int status) {
    switch (status) {
      case OK:
        return 'OK';
      case YIELD:
        return 'YIELD';
      case ERRRUN:
        return 'Runtime error';
      case ERRSYNTAX:
        return 'Syntax error';
      case ERRMEM:
        return 'Memory allocation error';
      case ERRERR:
        return 'Error while running error handler';
      default:
        return 'Unknown status: $status';
    }
  }
}

/// 垃圾回收操作
class LuaGC {
  LuaGC._();

  static const int STOP = 0;
  static const int RESTART = 1;
  static const int COLLECT = 2;
  static const int COUNT = 3;
  static const int COUNTB = 4;
  static const int STEP = 5;
  static const int SETPAUSE = 6;
  static const int SETSTEPMUL = 7;
  static const int ISRUNNING = 9;
}

/// 算术操作
class LuaArithOp {
  LuaArithOp._();

  static const int ADD = 0;
  static const int SUB = 1;
  static const int MUL = 2;
  static const int MOD = 3;
  static const int POW = 4;
  static const int DIV = 5;
  static const int IDIV = 6;
  static const int BAND = 7;
  static const int BOR = 8;
  static const int BXOR = 9;
  static const int SHL = 10;
  static const int SHR = 11;
  static const int UNM = 12;
  static const int BNOT = 13;
}

/// 比较操作
class LuaCompareOp {
  LuaCompareOp._();

  static const int EQ = 0;
  static const int LT = 1;
  static const int LE = 2;
}

/// 标准库的引用位置
class LuaRegistryIndex {
  LuaRegistryIndex._();

  /// 伪索引用于注册表
  static const int REGISTRYINDEX = -1001000;

  /// 主线程
  static const int RIDX_MAINTHREAD = 1;

  /// 全局环境
  static const int RIDX_GLOBALS = 2;

  /// 最后一个保留索引
  static const int RIDX_LAST = RIDX_GLOBALS;
}

/// 引用常量
const int LUA_NOREF = -2;
const int LUA_REFNIL = -1;

/// 栈索引辅助函数
///
/// 获取上值的索引
/// [i] 上值索引（从 1 开始）
int lua_upvalueindex(int i) => LuaRegistryIndex.REGISTRYINDEX - i;
