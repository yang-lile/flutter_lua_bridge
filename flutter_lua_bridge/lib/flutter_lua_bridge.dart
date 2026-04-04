/// Flutter Lua Bridge - FFI bindings for Lua 5.4
///
/// This library provides Dart FFI bindings for the Lua C API,
/// allowing you to embed Lua scripting in your Flutter applications.
library;

// Generated interfaces
export 'src/gen/lua_aux_api.dart';
export 'src/gen/lua_c_api.dart';

// Implementations (隐藏内部类型定义)
export 'src/lua_c_api_impl.dart' hide lua_State, lua_Debug, lua_CFunction, lua_KFunction, lua_Alloc, lua_Hook, lua_Reader, lua_Writer, lua_WarnFunction;
export 'src/lua_aux_api_impl.dart';

