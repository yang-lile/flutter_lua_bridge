/// Dart / Lua interoperability on Lua 5.3, 5.4 or 5.5.
///
/// [LuaRuntime] is the single entry point: it runs Lua code, exchanges values
/// and functions with it, and hosts the generated typed bindings.
library;

export 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

// Support for generated `.g.dart` parts: a contract library needs this one
// import only. These names can change between releases; applications use the
// generated classes instead.
export 'src/codecs.dart';
export 'src/errors.dart';
export 'src/runtime.dart'
    show
        BridgeHostMethod,
        LuaBinding,
        LuaCallback,
        LuaFunction,
        LuaLibrary,
        LuaRef,
        LuaRuntime,
        LuaTable,
        LuaThread,
        LuaThreadStatus,
        LuaUserdata,
        LuaValues,
        LuaYield;
