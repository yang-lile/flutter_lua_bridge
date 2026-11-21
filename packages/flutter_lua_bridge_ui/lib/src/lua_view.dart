import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import 'core_library.dart';
import 'library.dart';
import 'store.dart';
import 'tree.dart';
import 'ui_lua.dart';

/// Builds the widget shown instead of a Lua view that failed.
typedef LuaViewErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
);

/// Lets the host call the methods of a [LuaView]'s app.
class LuaViewController {
  _LuaViewState? _state;

  /// Whether the controller is attached to a mounted [LuaView].
  bool get isAttached => _state != null;

  /// Calls `methods[name](store, arguments)` of the app, renders the
  /// components whose state changed and returns the method's result
  /// (tables as Dart `Map` or `List`). Lua errors are thrown as
  /// [LuaBridgeException].
  Object? call(String name, [Object? arguments]) {
    final state = _state;
    if (state == null) throw StateError('The controller is not attached');
    return state._callMethod(name, arguments);
  }

  /// Renders the whole view again.
  void refresh() => _state?._remount();
}

/// Shows the widget tree that a Lua app returns.
///
/// [source] is a Lua chunk that returns `ui.app{...}` from the `flb.ui`
/// module, which the view loads into [runtime]:
///
/// ```lua
/// local ui = require("flb.ui")
///
/// local Counter = ui.component(function(props)
///   local state = ui.state { count = 0 }
///   return function(props)
///     return ui.GestureDetector {
///       onTap = function() state.count = state.count + 1 end,
///       child = ui.Text { props.label .. ": " .. state.count },
///     }
///   end
/// end)
///
/// return ui.app {
///   store = { title = "Counters" },
///   view = function(store, props)
///     return ui.Column {
///       ui.Text { store.title },
///       Counter { key = "a", label = "a" },
///       Counter { key = "b", label = "b" },
///     }
///   end,
/// }
/// ```
///
/// State is reactive: a component records the keys of `ui.state` and of the
/// store that it reads while rendering, and only the components that read a
/// changed key render again. Lua sends only their output; each component is
/// a [LuaComponentWidget] that rebuilds on its own, so an update costs the
/// size of the changed components, not of the whole tree.
///
/// Lua runs synchronously on the calling isolate; set a memory limit on
/// [runtime] for code you do not trust.
class LuaView extends StatefulWidget {
  const LuaView({
    super.key,
    required this.runtime,
    required this.source,
    this.name = 'LuaView',
    this.libraries = const [],
    this.props = const {},
    this.controller,
    this.store,
    this.fallback,
    this.onError,
  });

  /// The runtime the app runs in. The view does not close it.
  final LuaRuntime runtime;

  /// The Lua chunk that returns the app.
  final String source;

  /// The chunk name used in Lua error messages.
  final String name;

  /// The widget libraries Lua can use. [coreLibrary] is added when no
  /// library is named `core`. Keep the list and its libraries across
  /// rebuilds: a different list renders everything again.
  final List<LuaWidgetLibrary> libraries;

  /// Passed to `view(store, props)` as a table; a change renders the root
  /// component again.
  final Map<String, Object?> props;

  /// Calls app methods from the host.
  final LuaViewController? controller;

  /// A Dart mirror of the app's store, synced in both directions.
  final LuaStore? store;

  /// Shown when loading or rendering fails. Defaults to an [ErrorWidget].
  final LuaViewErrorBuilder? fallback;

  /// Receives errors from loading, rendering and event handlers. Defaults to
  /// [FlutterError.reportError].
  final void Function(Object error, StackTrace stack)? onError;

  @override
  State<LuaView> createState() => _LuaViewState();
}

class _LuaViewState extends State<LuaView> {
  late LuaTree _tree;
  LuaTable? _app;
  final Map<String, LuaFunction> _api = {};
  Object? _error;

  static const _functions = [
    'render',
    'update',
    'dispatch',
    'call',
    'set',
    'snapshot',
  ];

  @override
  void initState() {
    super.initState();
    _tree = _newTree();
    widget.controller?._state = this;
    _load();
  }

  @override
  void didUpdateWidget(LuaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller!._state = null;
      }
      widget.controller?._state = this;
    }
    if (oldWidget.store != widget.store) {
      oldWidget.store?.detach(_writeStore);
      _attachStore();
    }
    if (oldWidget.runtime != widget.runtime ||
        oldWidget.source != widget.source ||
        oldWidget.name != widget.name) {
      _release(oldWidget.runtime);
      _tree = _newTree();
      _load();
    } else if (!listEquals(oldWidget.libraries, widget.libraries)) {
      _tree = _newTree();
    } else if (!mapEquals(oldWidget.props, widget.props) &&
        _tree.root != null) {
      _run('update', [widget.props]);
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller!._state = null;
    widget.store?.detach(_writeStore);
    _release(widget.runtime);
    super.dispose();
  }

  LuaTree _newTree() {
    final libraries = widget.libraries;
    return LuaTree(
      mergeLibraries([
        if (!libraries.any((library) => library.name == 'core')) coreLibrary(),
        ...libraries,
      ]),
      _onEvent,
    );
  }

  void _load() {
    _error = null;
    try {
      final runtime = widget.runtime;
      runtime.ensureModule(uiLuaModule, source: uiLuaSource);
      final results = runtime.run(widget.source, name: widget.name);
      final app = results.isEmpty ? null : results.first;
      if (app is! LuaTable) {
        throw LuaBridgeException(
          '${widget.name} must return ui.app{...}, got ${app ?? 'nothing'}',
        );
      }
      _app = app;
      for (final name in _functions) {
        _api[name] = app[name] as LuaFunction;
      }
      _attachStore();
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  void _attachStore() {
    final store = widget.store;
    final snapshot = _api['snapshot'];
    if (store == null || snapshot == null) return;
    store.attach(_plain(snapshot.call().firstOrNull), _writeStore);
  }

  void _writeStore(List<Object> luaPath, Object? value) =>
      _run('set', [luaPath, value], rethrowErrors: true);

  void _release(LuaRuntime runtime) {
    if (!runtime.isClosed) {
      for (final ref in [..._api.values, ?_app]) {
        ref.release();
      }
    }
    _api.clear();
    _app = null;
  }

  void _fail(Object error, StackTrace stack) {
    _error = error;
    final onError = widget.onError;
    if (onError != null) {
      onError(error, stack);
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_lua_bridge_ui',
          context: ErrorDescription('in the Lua view ${widget.name}'),
        ),
      );
    }
  }

  /// Calls an api function that returns an update and applies it.
  Map<Object?, Object?>? _run(
    String name,
    List<Object?> arguments, {
    bool rethrowErrors = false,
  }) {
    final function = _api[name];
    if (function == null || widget.runtime.isClosed) return null;
    try {
      final result = _plain(function.call(arguments).firstOrNull);
      if (result is! Map<Object?, Object?>) return null;
      widget.store?.applyChanges(result['changes']);
      try {
        _tree.apply(result);
      } on ComponentMiss {
        _remount();
      }
      return result;
    } catch (error, stack) {
      if (rethrowErrors) rethrow;
      _fail(error, stack);
      if (mounted) setState(() {});
      return null;
    }
  }

  void _remount() {
    if (mounted) setState(() => _tree.root = null);
  }

  void _onEvent(int id, Map<String, Object?>? arguments) =>
      _run('dispatch', [id, arguments]);

  Object? _callMethod(String name, Object? arguments) {
    if (_api['call'] == null) throw StateError('The Lua app is not loaded');
    return _run('call', [name, arguments], rethrowErrors: true)?['value'];
  }

  void _mountRoot() {
    final result = _plain(_api['render']!.call([widget.props]).firstOrNull);
    if (result is! Map) throw StateError('render returned $result');
    widget.store?.applyChanges(result['changes']);
    _tree.mount(result['root']);
  }

  @override
  Widget build(BuildContext context) {
    if (_error == null && _tree.root == null && _api.isNotEmpty) {
      try {
        _mountRoot();
      } catch (error, stack) {
        _fail(error, stack);
      }
    }
    final error = _error;
    if (error != null) {
      return widget.fallback?.call(context, error) ?? ErrorWidget(error);
    }
    return _tree.root ?? const SizedBox.shrink();
  }
}

/// Copies a Lua table into Dart data and releases its handle.
Object? _plain(Object? value) {
  if (value is! LuaTable) return value;
  try {
    return value.toDart();
  } finally {
    value.release();
  }
}
