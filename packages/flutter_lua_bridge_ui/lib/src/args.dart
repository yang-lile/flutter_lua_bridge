import 'package:flutter/widgets.dart';

/// Calls the Lua event handler [id] with the positional [arguments].
typedef LuaEventSink = void Function(int id, List<Object?> arguments);

/// Calls the Lua builder [id] with the positional [arguments] and returns
/// the widget it built.
typedef LuaBuildSink = Widget Function(int id, List<Object?> arguments);

/// Calls the Lua function behind a handler with the positional
/// [arguments], matching the Flutter callback's parameters: a
/// `ValueChanged<bool>` calls `trigger([value])`.
typedef LuaHandlerTrigger = void Function([List<Object?> arguments]);

/// Calls the Lua builder function behind an argument with the positional
/// [arguments] (the first is the `BuildContext` slot, sent as `nil`).
typedef LuaBuilderTrigger = Widget Function(List<Object?> arguments);

/// The arguments of one Lua node, as seen by a [LuaWidgetBuilder].
///
/// This mirrors the `DataSource` interface of `package:rfw`, so builders read
/// the same way: a key is a path of map keys (`String`) and list indices
/// (`int`, zero-based), for example `['style', 'color']` or
/// `['children', 2]`.
///
/// Values arrive as Lua sent them: `bool`, `int`, `double`, `String`, `List`
/// and `Map`. Child nodes have already been turned into widgets, Lua
/// functions into handler references that [voidHandler] and [handler] wrap,
/// and functions passed as `...builder`/`...Builder` into builder
/// references that [builder] and [indexedBuilder] wrap.
class LuaWidgetArgs {
  /// Wraps the argument table [values] of a node.
  LuaWidgetArgs(this.values, this._events, [this._builds]);

  /// The raw arguments.
  final Map<Object?, Object?> values;
  final LuaEventSink _events;
  final LuaBuildSink? _builds;

  /// The value at [key], or `null` when there is none.
  Object? operator [](List<Object> key) {
    Object? current = values;
    for (final part in key) {
      switch ((current, part)) {
        case (Map<Object?, Object?> map, _):
          current = map[part];
        case (List<Object?> list, int index):
          current = index >= 0 && index < list.length ? list[index] : null;
        default:
          return null;
      }
    }
    return current;
  }

  /// The value at [key] if it is a [T], else `null`. [T] is `bool`, `int`,
  /// `double` or `String`. Lua integers are accepted where a `double` is
  /// asked for, because Lua code rarely writes `1.0`.
  T? v<T extends Object>(List<Object> key) {
    final value = this[key];
    if (value is T) return value;
    if (T == double && value is int) return value.toDouble() as T;
    return null;
  }

  /// Whether the value at [key] is a list. An empty Lua table counts as an
  /// empty list as well as an empty map.
  bool isList(List<Object> key) {
    final value = this[key];
    return value is List || (value is Map && value.isEmpty);
  }

  /// Whether the value at [key] is a map.
  bool isMap(List<Object> key) => this[key] is Map;

  /// The length of the list at [key], or 0.
  int length(List<Object> key) {
    final value = this[key];
    return value is List ? value.length : 0;
  }

  /// The child widget at [key], or an error widget when there is none.
  Widget child(List<Object> key) =>
      optionalChild(key) ??
      ErrorWidget.withDetails(message: 'Expected a widget at $key');

  /// The child widget at [key], or `null`.
  Widget? optionalChild(List<Object> key) {
    final value = this[key];
    return value is Widget ? value : null;
  }

  /// The widgets of the list at [key]; entries that are not widgets become
  /// error widgets.
  List<Widget> childList(List<Object> key) {
    final value = this[key];
    if (value is! List) return const <Widget>[];
    return [
      for (final item in value)
        item is Widget
            ? item
            : ErrorWidget.withDetails(message: 'Expected a widget in $key'),
    ];
  }

  /// A callback for the Lua function at [key], or `null` when there is none.
  VoidCallback? voidHandler(List<Object> key) => handler<VoidCallback>(
    key,
    (trigger) =>
        () => trigger(),
  );

  /// A callback of type [T] for the Lua function at [key], or `null`.
  ///
  /// [generator] receives a trigger that calls the Lua function and must
  /// return a function of type [T] that calls it with the Flutter
  /// callback's parameters, for example
  /// `(trigger) => (double value) => trigger([value])`.
  T? handler<T extends Function>(
    List<Object> key,
    T Function(LuaHandlerTrigger trigger) generator,
  ) {
    final value = this[key];
    if (value is! Map || value[handlerKey] is! int) return null;
    final id = value[handlerKey] as int;
    return generator(([arguments = const []]) => _events(id, arguments));
  }

  /// A builder of type [T] for the Lua builder function at [key], or
  /// `null`. [generator] receives a trigger that runs the Lua function and
  /// returns its widget, for example
  /// `(build) => (context, index) => build([null, index])`.
  ///
  /// Each call's output is a component instance of its own in Lua, so the
  /// state it reads re-renders only that output, and Lua releases it when
  /// Flutter disposes the widget.
  T? builder<T extends Function>(
    List<Object> key,
    T Function(LuaBuilderTrigger build) generator,
  ) {
    final value = this[key];
    final builds = _builds;
    if (builds == null || value is! Map || value[builderKey] is! int) {
      return null;
    }
    final id = value[builderKey] as int;
    return generator((arguments) => builds(id, arguments));
  }

  /// An [IndexedWidgetBuilder] for the Lua function at [key], called as
  /// `function(context, index)` with a zero-based index, or `null`.
  IndexedWidgetBuilder? indexedBuilder(List<Object> key) =>
      builder<IndexedWidgetBuilder>(
        key,
        (build) =>
            (context, index) => build([null, index]),
      );
}

/// The key under which Lua sends a handler reference.
const String handlerKey = r'$h';

/// The key under which Lua sends a builder reference.
const String builderKey = r'$b';
