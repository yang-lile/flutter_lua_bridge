/// Flutter Lua Bridge - Dart 风格 API 导出
///
/// 这个库提供符合 Dart 编码习惯的 API：
/// 1. 面向对象的 LuaState 类
/// 2. Dart 命名规范的扩展方法（小驼峰）
/// 3. 自动内存管理
/// 4. 异常处理而非返回码
///
/// 命名风格符合 Dart 规范：
/// - `luaState.pcall()` 而不是 `lua_pcall()`
/// - `luaState.pop()` 而不是 `lua_pop()`
/// - `luaState.doString()` 而不是 `luaL_dostring()`
///
/// 适合 Dart 开发者，代码更简洁、更符合 Dart 习惯。
///
/// 使用示例：
/// ```dart
/// import 'package:flutter_lua_bridge/lua_dart_api.dart';
///
/// void main() {
///   // 方式1: 使用 use 自动管理生命周期
///   LuaState.use((lua) {
///     lua.openLibs();
///     lua.doString('print("Hello from Lua!")');
///   });
///   
///   // 方式2: 手动管理生命周期
///   final lua = LuaState.create();
///   try {
///     lua.openLibs();
///     final result = lua.tryDoString('return 1 + 1');
///     print(result.value); // 2
///   } finally {
///     lua.close();
///   }
/// }
/// ```

library flutter_lua_bridge.dart_api;

// ==================== 核心常量 ====================
/// Lua 常量定义（状态码、类型、GC 操作等）
export 'src/core/lua_constants.dart';

// ==================== Lua 状态封装 ====================
/// 面向对象的 LuaState 类
export 'src/core/lua_state.dart';

// ==================== Dart 风格扩展 ====================
/// LuaState 指针的 Dart 风格扩展方法
/// - 小驼峰命名
/// - 返回 bool 而不是 int
/// - 自动内存管理
export 'src/utils/type_convert_helper.dart';
