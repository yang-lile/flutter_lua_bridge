/// Annotations used to describe a typed Dart / Lua bridge contract.
library;

/// How much protection the generated Lua glue adds around a [LuaApi].
enum LuaOptimization {
  /// Lua validates arguments and results, and catches errors with `pcall`.
  /// Generated client methods return `LuaCallResult<T>`.
  o1,

  /// Lua catches errors with `pcall` but does not validate types.
  /// Generated client methods return `LuaCallResult<T>`.
  o2,

  /// Direct calls. Generated client methods return `T` and failures surface
  /// as exceptions.
  o3,
}

/// Declares an interface implemented by a Lua module and called from Dart.
///
/// Every abstract method of the annotated class is part of the contract.
class LuaApi {
  const LuaApi({required this.module, this.optimization});

  /// The Lua module name, as passed to `require`.
  final String module;

  /// Overrides the builder's `optimization` option for this interface.
  final LuaOptimization? optimization;
}

/// Declares an interface implemented in Dart and exposed to Lua via require().
///
/// Every abstract method of the annotated class is part of the contract.
class DartApi {
  const DartApi({required this.module});

  /// The Lua module name, as passed to `require`.
  final String module;
}

/// Overrides a method, data class field or enum value's Lua name.
class LuaName {
  const LuaName(this.name);

  final String name;
}
