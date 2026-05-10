/// Lua C API 类型定义
///
/// 此文件包含 Lua C API 的所有类型定义和枚举。
library;

import 'dart:ffi' as ffi;
import '../gen/flutter_lua_bridge.g.dart' as gen;

// ============================================================================
// 类型别名
// ============================================================================

/// Lua 状态机
typedef LuaState = gen.lua_State;

/// Lua C 函数类型（函数指针）
typedef LuaCFunction = ffi.Pointer<ffi.Void>;

/// Lua 调试信息结构（不透明指针）
typedef LuaDebug = ffi.Pointer<ffi.Void>;

/// Lua 钩子函数类型（函数指针）
typedef LuaHook = ffi.Pointer<ffi.Void>;

/// Lua 整数类型（使用 Dart 的 int64）
typedef LuaInteger = int;

/// Lua 上下文类型（用于 yield）
typedef LuaKContext = int;

/// Lua K 函数类型（函数指针，用于 yield）
typedef LuaKFunction = ffi.Pointer<ffi.Void>;

/// Lua 数字类型（使用 Dart 的 double）
typedef LuaNumber = double;

/// Lua 读取器函数类型（函数指针）
typedef LuaReader = ffi.Pointer<ffi.Void>;

/// Lua 无符号整数类型
typedef LuaUnsigned = int;

/// Lua 警告函数类型（函数指针）
typedef LuaWarnFunction = ffi.Pointer<ffi.Void>;

/// Lua 写入器函数类型（函数指针）
typedef LuaWriter = ffi.Pointer<ffi.Void>;

/// Lua 分配函数类型（函数指针）
typedef LuaAlloc = ffi.Pointer<ffi.Void>;

/// Lua 辅助库缓冲区类型（不透明指针）
typedef LuaLibBuffer = ffi.Pointer<ffi.Void>;

/// Lua 辅助库注册表类型（不透明指针）
typedef LuaLibReg = ffi.Pointer<ffi.Void>;

/// Lua 辅助库流类型（不透明指针）
typedef LuaLibStream = ffi.Pointer<ffi.Void>;

// ============================================================================
// 枚举类型
// ============================================================================

/// Lua 值类型枚举
enum LuaType {
  /// 无效索引
  none(-1),

  /// nil 值
  nil(0),

  /// 布尔值
  boolean(1),

  /// 轻量用户数据
  lightUserdata(2),

  /// 数字
  number(3),

  /// 字符串
  string(4),

  /// 表
  table(5),

  /// 函数
  function(6),

  /// 用户数据
  userdata(7),

  /// 线程（协程）
  thread(8);

  final int value;
  const LuaType(this.value);

  /// 从整数值创建 LuaType
  static LuaType fromValue(int value) {
    return switch (value) {
      -1 => LuaType.none,
      0 => LuaType.nil,
      1 => LuaType.boolean,
      2 => LuaType.lightUserdata,
      3 => LuaType.number,
      4 => LuaType.string,
      5 => LuaType.table,
      6 => LuaType.function,
      7 => LuaType.userdata,
      8 => LuaType.thread,
      _ => throw ArgumentError('Unknown value for LuaType: $value'),
    };
  }

  /// 从生成的枚举转换
  static LuaType fromFlbType(gen.FlbType type) {
    return fromValue(type.value);
  }

  /// 转换为生成的枚举
  gen.FlbType toFlbType() {
    return gen.FlbType.fromValue(value);
  }
}

/// Lua 线程/调用状态枚举
enum LuaStatus {
  /// 成功
  ok(0),

  /// 协程被 yield
  yield(1),

  /// 运行时错误
  errRun(2),

  /// 语法错误
  errSyntax(3),

  /// 内存分配错误
  errMem(4),

  /// 垃圾回收错误
  errGcmm(5),

  /// 错误处理错误
  errErr(6);

  final int value;
  const LuaStatus(this.value);

  /// 从整数值创建 LuaStatus
  static LuaStatus fromValue(int value) {
    return switch (value) {
      0 => LuaStatus.ok,
      1 => LuaStatus.yield,
      2 => LuaStatus.errRun,
      3 => LuaStatus.errSyntax,
      4 => LuaStatus.errMem,
      5 => LuaStatus.errGcmm,
      6 => LuaStatus.errErr,
      _ => throw ArgumentError('Unknown value for LuaStatus: $value'),
    };
  }

  /// 从生成的枚举转换
  static LuaStatus fromFlbStatus(gen.FlbStatus status) {
    return fromValue(status.value);
  }

  /// 转换为生成的枚举
  gen.FlbStatus toFlbStatus() {
    return gen.FlbStatus.fromValue(value);
  }
}

/// GC 操作枚举
enum LuaGC {
  /// 停止垃圾回收
  stop(0),

  /// 重启垃圾回收
  restart(1),

  /// 执行一次完整的垃圾回收
  collect(2),

  /// 返回当前内存使用量（KB）
  count(3),

  /// 返回当前字节使用量
  countB(4),

  /// 执行一步垃圾回收
  step(5),

  /// 设置暂停参数
  setPause(6),

  /// 设置步长乘数
  setStepMul(7),

  /// 检查 GC 是否运行
  isRunning(9);

  final int value;
  const LuaGC(this.value);

  /// 从整数值创建 LuaGC
  static LuaGC fromValue(int value) {
    return switch (value) {
      0 => LuaGC.stop,
      1 => LuaGC.restart,
      2 => LuaGC.collect,
      3 => LuaGC.count,
      4 => LuaGC.countB,
      5 => LuaGC.step,
      6 => LuaGC.setPause,
      7 => LuaGC.setStepMul,
      9 => LuaGC.isRunning,
      _ => throw ArgumentError('Unknown value for LuaGC: $value'),
    };
  }

  /// 从生成的枚举转换
  static LuaGC fromFlbGC(gen.FlbGC gc) {
    return fromValue(gc.value);
  }

  /// 转换为生成的枚举
  gen.FlbGC toFlbGC() {
    return gen.FlbGC.fromValue(value);
  }
}

/// 算术操作枚举
enum LuaArith {
  /// 加法 (+)
  add(0),

  /// 减法 (-)
  sub(1),

  /// 乘法 (*)
  mul(2),

  /// 除法 (/)
  div(4),

  /// 取模 (%)
  mod(5),

  /// 幂运算 (^)
  pow(6),

  /// 取反 (-)
  unm(7),

  /// 按位与 (&)
  band(8),

  /// 按位或 (|)
  bor(9),

  /// 按位异或 (^)
  bxor(10),

  /// 左移 (<<)
  shl(11),

  /// 右移 (>>)
  shr(12),

  /// 按位取反 (~)
  bnot(13);

  final int value;
  const LuaArith(this.value);

  /// 从整数值创建 LuaArith
  static LuaArith fromValue(int value) {
    return switch (value) {
      0 => LuaArith.add,
      1 => LuaArith.sub,
      2 => LuaArith.mul,
      4 => LuaArith.div,
      5 => LuaArith.mod,
      6 => LuaArith.pow,
      7 => LuaArith.unm,
      8 => LuaArith.band,
      9 => LuaArith.bor,
      10 => LuaArith.bxor,
      11 => LuaArith.shl,
      12 => LuaArith.shr,
      13 => LuaArith.bnot,
      _ => throw ArgumentError('Unknown value for LuaArith: $value'),
    };
  }

  /// 从生成的枚举转换
  static LuaArith fromFlbArith(gen.FlbArith arith) {
    return fromValue(arith.value);
  }

  /// 转换为生成的枚举
  gen.FlbArith toFlbArith() {
    return gen.FlbArith.fromValue(value);
  }
}

/// 比较操作枚举
enum LuaCompare {
  /// 相等 (==)
  eq(0),

  /// 小于 (<)
  lt(1),

  /// 小于等于 (<=)
  le(2);

  final int value;
  const LuaCompare(this.value);

  /// 从整数值创建 LuaCompare
  static LuaCompare fromValue(int value) {
    return switch (value) {
      0 => LuaCompare.eq,
      1 => LuaCompare.lt,
      2 => LuaCompare.le,
      _ => throw ArgumentError('Unknown value for LuaCompare: $value'),
    };
  }

  /// 从生成的枚举转换
  static LuaCompare fromFlbCompare(gen.FlbCompare compare) {
    return fromValue(compare.value);
  }

  /// 转换为生成的枚举
  gen.FlbCompare toFlbCompare() {
    return gen.FlbCompare.fromValue(value);
  }
}
