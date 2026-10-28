/// Annotations used to describe a typed Dart / Lua bridge contract.
library;

/// Declares an interface implemented by a Lua module.
class LuaApi {
  const LuaApi({required this.module});

  final String module;
}

/// Declares an interface implemented in Dart and exposed to Lua via require().
class DartApi {
  const DartApi({required this.module});

  final String module;
}

/// Overrides a method, DTO field or enum value's Lua name.
class LuaName {
  const LuaName(this.name);

  final String name;
}

/// Configures generated Dart, Lua and Teal artifact locations.
///
/// Paths are relative to the directory in which the generator is run.
class ConfigureLuaBridge {
  const ConfigureLuaBridge({
    required this.dartOut,
    required this.luaOut,
    required this.tealOut,
    this.optimization = 'O1',
  });

  final String dartOut;
  final String luaOut;
  final String tealOut;

  /// Generated Lua safety level: `O1`, `O2` or `O3`.
  final String optimization;
}
