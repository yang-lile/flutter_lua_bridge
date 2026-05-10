export 'src/lua_state.dart';
export 'src/gen/flutter_lua_shim.g.dart' show
  LuaType,
  LuaStatus,
  LuaGC,
  LuaArith,
  LuaCompare,
  LUA_REGISTRYINDEX;

// 高级用户可直接使用 ffigen 生成的枚举类型（与 C 枚举一一对应）。
export 'src/gen/flutter_lua_shim.g.dart'
    show
      lua_shim_type,
      lua_shim_status,
      lua_shim_gc,
      lua_shim_arith,
      lua_shim_compare;
