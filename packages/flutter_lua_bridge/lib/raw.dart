/// Low-level Lua 5.4 bindings retained for migration and expert use.
///
/// These APIs expose Lua's stack, pointers and error machinery directly. They
/// are not used by the typed runtime and do not provide its safety guarantees.
library;

export 'src/raw/gen/flutter_lua_bridge.g.dart';
export 'src/raw/flutter_lua_bridge.dart';
export 'src/raw/lua_state.dart';
export 'src/raw/lua_status.dart';
