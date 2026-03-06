/// Flutter Lua Bridge - 原始 C API 导出
///
/// 这个库导出 Lua 的原始 C API，包括：
/// 1. ffigen 自动生成的 FFI 绑定
/// 2. 手动实现的 C 语言宏函数
///
/// 命名风格保持与 C 语言一致（小写下划线）：
/// - `lua_pcall` 而不是 `luaPcall`
/// - `lua_pop` 而不是 `luaPop`
/// - `luaL_dostring` 而不是 `luaLDoString`
///
/// 适合熟悉 Lua C API 的用户，或者需要直接翻译 C 代码的场景。
///
/// 使用示例：
/// ```dart
/// import 'package:flutter_lua_bridge/lua_raw_api.dart';
///
/// void main() {
///   final L = luaL_newstate();
///   luaL_openlibs(L);
///   
///   final code = 'print("Hello from Lua!")'.toPointerChar();
///   try {
///     if (luaL_dostring(L, code) == LUA_OK) {
///       print('Success');
///     }
///   } finally {
///     calloc.free(code);
///   }
///   
///   lua_close(L);
/// }
/// ```

library flutter_lua_bridge.raw_api;

// ==================== FFI 生成的底层绑定 ====================
/// 自动生成的 FFI 绑定，包含完整的 Lua C API
export 'src/gen/flutter_lua_bridge.g.dart'
    hide LUA_MULTRET, LUA_NOREF, LUA_REFNIL;

// ==================== 核心常量 ====================
/// Lua 常量定义（状态码、类型、GC 操作等）
export 'src/core/lua_constants.dart';

// ==================== C API 宏函数 ====================
/// C 语言 Lua API 中的宏和内联函数的 Dart 实现
export 'src/core/lua_c_api_helpers.dart';

// ==================== 基础类型转换（原始风格） ====================
/// 字符串和指针之间的基础转换
export 'src/utils/type_convert_helper.dart'
    show PointCharX, NativePointCharX, StringPointerHelper, StringBatch;
