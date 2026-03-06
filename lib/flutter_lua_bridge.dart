/// Flutter Lua Bridge
///
/// Dart 与 Lua 的 FFI 绑定库，支持从源码编译 Lua，
/// 便于替换 Lua 核心。
///
/// 本库提供两种 API 风格：
///
/// 1. **原始 C API** (`lua_raw_api.dart`)
///    - 保持 C 语言命名风格（小写下划线）
///    - 适合熟悉 Lua C API 的用户
///    - 直接翻译 C 代码更方便
///
/// 2. **Dart 风格 API** (`lua_dart_api.dart`)
///    - 面向对象的 LuaState 类
///    - 符合 Dart 命名规范（小驼峰）
///    - 自动内存管理和异常处理
///    - 推荐 Dart 开发者使用
///
/// 默认导出（向后兼容）：同时导出两套 API
///
/// 使用示例：
/// ```dart
/// import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
///
/// void main() {
///   // 推荐：使用 Dart 风格 API
///   LuaState.use((lua) {
///     lua.openLibs();
///     lua.doString('print("Hello from Lua!")');
///   });
///   
///   // 也可以使用原始 C API
///   final L = luaL_newstate();
///   luaL_openlibs(L);
///   lua_close(L);
/// }
/// ```
///
/// 或者只导入你需要的风格：
/// ```dart
/// // 只使用 Dart 风格
/// import 'package:flutter_lua_bridge/lua_dart_api.dart';
///
/// // 只使用原始 C 风格
/// import 'package:flutter_lua_bridge/lua_raw_api.dart';
/// ```

library flutter_lua_bridge;

// ==================== 子库导出 ====================

/// 原始 C API 导出（C 语言风格）
/// - 小写下划线命名
/// - 直接操作指针
/// - 需要手动管理内存
export 'lua_raw_api.dart';

/// Dart 风格 API 导出（Dart 习惯）
/// - 小驼峰命名
/// - 面向对象封装
/// - 自动内存管理
export 'lua_dart_api.dart';

// ==================== 兼容性导出 ====================
/// 为了保持向后兼容，主库仍然导出所有内容
/// 新项目建议根据需求导入子库
