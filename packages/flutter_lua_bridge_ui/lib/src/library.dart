import 'package:flutter/widgets.dart';

import 'args.dart';

/// Builds one widget from the arguments Lua gave a node.
///
/// Builders are plain closures in a [LuaWidgetLibrary]. A widget is in the
/// application only because a registered builder references it, so the Dart
/// tree shaker keeps exactly the registered widgets and Lua can use nothing
/// else.
typedef LuaWidgetBuilder = Widget Function(
  BuildContext context,
  LuaWidgetArgs args,
);

/// A Dart function that Lua calls through a [LuaWidgetLibrary].
///
/// [context] is the context of the [LuaView] whose render, event handler,
/// method or builder made the call, and [arguments] are its Lua arguments as
/// plain data (`null`, `bool`, `num`, `String`, `List`, `Map`). The result
/// goes back to Lua the same way. A [Future] result makes the calling event
/// handler or method wait: Lua continues with its value when it completes,
/// or with an error when it fails.
typedef LuaHostFunction = Object? Function(
  BuildContext context,
  List<Object?> arguments,
);

/// A named set of widgets that Lua can create.
///
/// Lua refers to a widget as `library.Widget`, for example `core.Column`,
/// `core.ListView.builder` or `material.ElevatedButton`. Libraries with
/// different names can therefore define widgets of the same name.
///
/// The `core` library ([coreLibrary]) covers `package:flutter/widgets.dart`.
/// Material, Cupertino and application widgets are registered the same way:
///
/// ```dart
/// final app = LuaWidgetLibrary(
///   name: 'app',
///   widgets: {
///     'Badge': (context, args) => Badge(label: args.v<String>(['label'])),
///   },
/// );
/// ```
///
/// Lua creates them with `ui.node("app.Badge", {...})`, or through
/// `local app = ui.library("app", {"Badge"})` and `app.Badge {...}`.
///
/// A library can ship Lua constructors for its widgets: [luaModules] are
/// loaded into the runtime, and the table that module [luaGlobals] returns
/// is installed as globals, so scripts write `ElevatedButton {...}` like
/// they write `Column {...}`.
class LuaWidgetLibrary {
  /// Creates a library. [name] must not contain a dot.
  LuaWidgetLibrary({
    required this.name,
    required this.widgets,
    this.functions = const {},
    this.luaModules = const {},
    this.luaGlobals,
  }) : assert(!name.contains('.'), 'A library name cannot contain a dot'),
       assert(
         luaGlobals == null || luaModules.containsKey(luaGlobals),
         'luaGlobals must name one of luaModules',
       );

  /// The prefix Lua uses for these widgets.
  final String name;

  /// The builders, by widget name without the library prefix. A named
  /// constructor is `Widget.name`, such as `ListView.builder`.
  final Map<String, LuaWidgetBuilder> widgets;

  /// Dart functions Lua can call, by name without the library prefix, such
  /// as `Navigator.pushNamed`. Lua calls them with
  /// `ui.invoke("library.Name", ...)`; `ui.functions(prefix, names)` builds
  /// the wrappers a library's Lua module usually exports as globals.
  final Map<String, LuaHostFunction> functions;

  /// Lua module sources by module name, loaded with
  /// `LuaRuntime.ensureModule` before the script runs.
  final Map<String, String> luaModules;

  /// The module of [luaModules] whose returned table becomes globals.
  final String? luaGlobals;
}

/// Merges [libraries] into one lookup table keyed by `library.Widget`.
Map<String, LuaWidgetBuilder> mergeLibraries(List<LuaWidgetLibrary> libraries) {
  final names = <String>{};
  final result = <String, LuaWidgetBuilder>{};
  for (final library in libraries) {
    if (!names.add(library.name)) {
      throw ArgumentError.value(
        library.name,
        'libraries',
        'Two libraries have the same name',
      );
    }
    for (final entry in library.widgets.entries) {
      result['${library.name}.${entry.key}'] = entry.value;
    }
  }
  return result;
}

/// Merges the [LuaWidgetLibrary.functions] of [libraries] into one lookup
/// table keyed by `library.Name`.
Map<String, LuaHostFunction> mergeFunctions(List<LuaWidgetLibrary> libraries) =>
    {
      for (final library in libraries)
        for (final entry in library.functions.entries)
          '${library.name}.${entry.key}': entry.value,
    };
