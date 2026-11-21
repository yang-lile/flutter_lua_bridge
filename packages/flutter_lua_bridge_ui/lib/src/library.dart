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

/// A named set of widgets that Lua can create.
///
/// Lua refers to a widget as `library.Widget`, for example `core.Column` or
/// `material.ElevatedButton`; a name without a library means `core`. Libraries
/// with different names can therefore define widgets of the same name.
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
/// `ui.library("app", {"Badge"})`.
class LuaWidgetLibrary {
  /// Creates a library. [name] must not contain a dot.
  LuaWidgetLibrary({required this.name, required this.widgets})
    : assert(!name.contains('.'), 'A library name cannot contain a dot');

  /// The prefix Lua uses for these widgets.
  final String name;

  /// The builders, by widget name without the library prefix.
  final Map<String, LuaWidgetBuilder> widgets;
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
