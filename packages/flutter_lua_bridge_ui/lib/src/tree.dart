import 'package:flutter/foundation.dart';
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

/// Runs a Lua builder and returns `{node = , removed = }`, or `null` when
/// the builder is gone.
typedef LuaTreeBuild = Map<Object?, Object?>? Function(
  int id,
  List<Object?> arguments,
);

/// Releases the builder output [id] in Lua and returns `{removed = }`.
typedef LuaTreeRelease = Map<Object?, Object?>? Function(Object id);

/// Turns the node tables Lua returns into widgets and keeps one listenable
/// per component instance.
///
/// A node is a map `{t = type, a = args, k = key}`. `{c = id, n = node}` is
/// the output of component instance `id`: it becomes a [LuaComponentWidget]
/// that listens to the instance's content. `{$c = id}` is an instance whose
/// output did not change, so its existing widget is reused and Flutter skips
/// it. A patch from Lua only replaces the content of the instances that
/// rendered again, so only their elements rebuild.
class LuaTree {
  LuaTree(this.widgets, this.events, {this.onBuild, this.onRelease});

  final Map<String, LuaWidgetBuilder> widgets;
  final LuaEventSink events;
  final LuaTreeBuild? onBuild;
  final LuaTreeRelease? onRelease;
  final Map<Object, _Instance> _instances = {};
  bool _disposed = false;

  /// The root component, or `null` before the first render.
  Widget? root;

  /// Number of component instances, for tests and benchmarks.
  int get instanceCount => _instances.length;

  /// Stops releasing builder outputs in Lua; the tree is being replaced.
  void dispose() => _disposed = true;

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
        instance.content.replace(_widget(patch['tree']), notify: true);
      }
    }
    _remove(result['removed']);
  }

  void _remove(Object? removed) {
    if (removed is List) {
      for (final id in removed) {
        _instances.remove(id);
      }
    }
  }

  /// Runs the Lua builder [id]; this is the [LuaBuildSink] of the args.
  Widget build(int id, List<Object?> arguments) {
    final result = onBuild?.call(id, arguments);
    if (result == null) {
      return ErrorWidget.withDetails(message: 'The Lua builder $id is gone');
    }
    final node = result['node'];
    _remove(result['removed']);
    if (node is Map && node['c'] != null) {
      return _component(node['c']!, node['n'], item: true);
    }
    return _widget(node);
  }

  void _release(Object id, LuaComponentWidget widget) {
    if (_disposed || !identical(_instances[id]?.widget, widget)) return;
    _instances.remove(id);
    final result = onRelease?.call(id);
    if (result != null) _remove(result['removed']);
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

  /// The widget of instance [id] with output [node]. An existing instance
  /// gets the new content without a notification and a new widget: it is
  /// inside a subtree that is rebuilding anyway, which updates its element.
  Widget _component(Object id, Object? node, {bool item = false}) {
    final child = _widget(node);
    final existing = _instances[id];
    final content = existing?.content ?? _Content(child);
    if (existing != null) content.replace(child, notify: false);
    late final LuaComponentWidget widget;
    widget = LuaComponentWidget(
      key: ValueKey<Object>(id),
      id: id,
      content: content,
      onDispose: item ? () => _release(id, widget) : null,
    );
    _instances[id] = _Instance(content, widget);
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
      args: LuaWidgetArgs(args, events, build),
      key: key == null ? null : ValueKey<Object>(key),
    );
  }
}

class _Instance {
  _Instance(this.content, this.widget);
  final _Content content;
  final LuaComponentWidget widget;
}

/// The current output of one component instance.
class _Content extends ChangeNotifier implements ValueListenable<Widget> {
  _Content(this._value);
  Widget _value;

  @override
  Widget get value => _value;

  void replace(Widget value, {required bool notify}) {
    _value = value;
    if (notify) notifyListeners();
  }
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
    required this.content,
    this.onDispose,
  });

  /// The instance id, such as `root/3`.
  final Object id;

  /// The instance's current output.
  final ValueListenable<Widget> content;

  /// Called when the element is removed for good; builder outputs use it to
  /// release their Lua instance.
  final VoidCallback? onDispose;

  @override
  State<LuaComponentWidget> createState() => _LuaComponentState();
}

class _LuaComponentState extends State<LuaComponentWidget> {
  @override
  void initState() {
    super.initState();
    widget.content.addListener(_changed);
  }

  @override
  void didUpdateWidget(LuaComponentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      oldWidget.content.removeListener(_changed);
      widget.content.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.content.removeListener(_changed);
    widget.onDispose?.call();
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.content.value;
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
