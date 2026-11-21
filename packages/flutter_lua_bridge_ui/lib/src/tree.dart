import 'package:flutter/widgets.dart';

import 'args.dart';
import 'library.dart';

/// Lua referred to a component instance that Dart does not have.
class ComponentMiss implements Exception {
  ComponentMiss(this.id);
  final Object? id;
  @override
  String toString() => 'ComponentMiss($id)';
}

/// Turns the node tables Lua returns into widgets and keeps one
/// [ValueNotifier] per component instance.
///
/// A node is a map `{t = type, a = args, k = key}`. `{c = id, n = node}` is
/// the output of component instance `id`: it becomes a [LuaComponentWidget]
/// that listens to the instance's notifier. `{$c = id}` is an instance whose
/// output did not change, so its existing widget is reused and Flutter skips
/// it. A patch from Lua only replaces the notifier value of the instances
/// that rendered again, so only their elements rebuild.
class LuaTree {
  LuaTree(this.widgets, this.events);

  final Map<String, LuaWidgetBuilder> widgets;
  final LuaEventSink events;
  final Map<Object, _Instance> _instances = {};

  /// The root component, or `null` before the first render.
  Widget? root;

  /// Number of component instances, for tests and benchmarks.
  int get instanceCount => _instances.length;

  /// Replaces everything with the root component node [node].
  void mount(Object? node) {
    _instances.clear();
    root = null;
    final widget = _convert(node);
    if (widget is! LuaComponentWidget) {
      throw StateError('Lua must render a root component');
    }
    root = widget;
  }

  /// Applies the `patches` and `removed` of a Lua update.
  void apply(Map<Object?, Object?> result) {
    final patches = result['patches'];
    if (patches is List) {
      for (final patch in patches) {
        if (patch is! Map) continue;
        final id = patch['id'];
        final instance = _instances[id] ?? (throw ComponentMiss(id));
        instance.notifier.value = _widget(patch['tree']);
      }
    }
    final removed = result['removed'];
    if (removed is List) {
      for (final id in removed) {
        _instances.remove(id);
      }
    }
  }

  Widget _widget(Object? node) {
    final widget = _convert(node);
    if (widget is Widget) return widget;
    return ErrorWidget.withDetails(
      message: 'A view must return a widget node, got ${_describe(node)}',
    );
  }

  /// Replaces every node inside [value] by its widget.
  Object? _convert(Object? value) {
    switch (value) {
      case Map<Object?, Object?>():
        final type = value['t'];
        if (type is String) return _node(type, value);
        final id = value['c'];
        if (id != null) return _component(id, value['n']);
        final ref = value[_refKey];
        if (ref != null) {
          return (_instances[ref] ?? (throw ComponentMiss(ref))).widget;
        }
        for (final entry in value.entries) {
          final item = entry.value;
          if (item is Map || item is List) value[entry.key] = _convert(item);
        }
        return value;
      case List<Object?>():
        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map || item is List) value[i] = _convert(item);
        }
        return value;
      default:
        return value;
    }
  }

  Widget _component(Object id, Object? node) {
    final child = _widget(node);
    final existing = _instances[id];
    if (existing != null) {
      existing.notifier.value = child;
      return existing.widget;
    }
    final notifier = ValueNotifier<Widget>(child);
    final widget = LuaComponentWidget(
      key: ValueKey<Object>(id),
      id: id,
      notifier: notifier,
    );
    _instances[id] = _Instance(notifier, widget);
    return widget;
  }

  Widget _node(String type, Map<Object?, Object?> node) {
    final name = type.contains('.') ? type : 'core.$type';
    final rawArgs = node['a'];
    final args = rawArgs is Map<Object?, Object?>
        ? _convert(rawArgs) as Map<Object?, Object?>
        : const <Object?, Object?>{};
    final key = node['k'];
    final builder = widgets[name];
    if (builder == null) {
      return ErrorWidget.withDetails(message: 'Unknown widget $name');
    }
    return LuaNodeWidget(
      name: name,
      builder: builder,
      args: LuaWidgetArgs(args, events),
      key: key == null ? null : ValueKey<Object>(key),
    );
  }
}

class _Instance {
  _Instance(this.notifier, this.widget);
  final ValueNotifier<Widget> notifier;
  final LuaComponentWidget widget;
}

const String _refKey = r'$c';

String _describe(Object? value) => switch (value) {
  null => 'nil',
  Map() => 'a table without a widget type',
  _ => value.runtimeType.toString(),
};

/// One Lua component instance. It rebuilds alone when Lua sends a new
/// output for it.
class LuaComponentWidget extends StatefulWidget {
  const LuaComponentWidget({
    super.key,
    required this.id,
    required this.notifier,
  });

  /// The instance id, such as `root/3`.
  final Object id;
  final ValueNotifier<Widget> notifier;

  @override
  State<LuaComponentWidget> createState() => _LuaComponentState();
}

class _LuaComponentState extends State<LuaComponentWidget> {
  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_changed);
  }

  @override
  void didUpdateWidget(LuaComponentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      oldWidget.notifier.removeListener(_changed);
      widget.notifier.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.notifier.value;
}

/// One Lua node. Building it runs the registered builder.
class LuaNodeWidget extends StatelessWidget {
  const LuaNodeWidget({
    super.key,
    required this.name,
    required this.builder,
    required this.args,
  });

  /// The full widget name, such as `core.Column`.
  final String name;
  final LuaWidgetBuilder builder;
  final LuaWidgetArgs args;

  @override
  Widget build(BuildContext context) {
    try {
      return builder(context, args);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_lua_bridge_ui',
          context: ErrorDescription('while building the Lua widget $name'),
        ),
      );
      return ErrorWidget.withDetails(message: '$name: $error');
    }
  }
}
