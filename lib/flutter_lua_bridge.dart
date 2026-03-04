/// Flutter Lua Bridge
///
/// Dart 与 Lua 的 FFI 绑定库，支持从源码编译 Lua，
/// 便于替换 Lua 核心。
///
/// 提供两层 API：
/// 1. 底层 FFI 绑定 - 直接调用 Lua C API（生成的代码）
/// 2. 高层封装 - 面向对象的 Dart API（推荐）
///
/// 使用示例：
/// ```dart
/// import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
///
/// void main() {
///   // 方式1：使用高层封装（推荐）
///   LuaState.create().use((lua) {
///     lua.openLibs();
///     lua.doString('print("Hello from Lua!")');
///   });
///
///   // 方式2：使用底层 FFI
///   final L = luaL_newstate();
///   luaL_openlibs(L);
///   luaL_dostring(L, 'print("Hello")'.toPointerChar());
///   lua_close(L);
/// }
/// ```

// ==================== 核心常量 ====================
export 'src/core/lua_constants.dart';

// ==================== Lua 状态封装 ====================
export 'src/core/lua_state.dart';

// ==================== FFI 生成的底层绑定 ====================
///
/// 这些是由 ffigen 自动生成的 FFI 绑定，
/// 包含完整的 Lua C API。
///
/// 注意：直接使用这些 API 需要手动管理内存和错误处理。
///
/// 隐藏与 lua_constants.dart 中重复的常量
export 'src/gen/flutter_lua_bridge.g.dart'
    hide LUA_MULTRET, LUA_NOREF, LUA_REFNIL;

// ==================== 辅助工具 ====================
///
/// 类型转换辅助，包含 String/Pointer<Char> 转换、
/// LuaState 扩展方法等。
export 'src/utils/type_convert_helper.dart';

// ==================== 兼容旧版本 ====================
///
/// 以下导出为兼容旧版本，建议使用新的 LuaState API
///

// 类型转换扩展（已移动到 utils）
export 'src/utils/type_convert_helper.dart'
    show PointCharX, NativePointCharX, StringPointerHelper, StringBatch;

// Lua 状态扩展（已移动到 utils）
export 'src/utils/type_convert_helper.dart' show LuaStateX;

// ==================== 已弃用的导出 ====================
///
/// 以下文件的内容已整合到新的结构中，
/// 保留导出以确保向后兼容。
///
@Deprecated('使用 LuaState 类或 lua_constants.dart 中的常量')
export 'src/macro_defines.dart'
    hide
        LUA_MULTRET,
        LUA_NOREF,
        LUA_REFNIL,
        lua_pcall,
        luaL_dostring,
        lua_tostring,
        lua_pop,
        lua_pushcfunction;

@Deprecated('功能已合并到 type_convert_helper.dart')
export 'src/helper/quick_call_method.dart';

@Deprecated('功能已合并到 type_convert_helper.dart')
export 'src/helper/type_convert_helper.dart';
