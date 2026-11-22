import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import 'core_library.dart';
import 'library.dart';
import 'lua_modules.dart';
import 'store.dart';
import 'tree.dart';

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
/// [source] is a Lua chunk that returns `App {...}`. Before running it, the
/// view loads the `flb.ui` module and the Lua modules of [libraries] into
/// [runtime] and installs their widgets and value types as globals, written
/// the way Flutter writes them:
///
/// ```lua
/// local Counter = ui.component(function(props)
///   local state = ui.state { count = 0 }
///   return function(props)
///     return GestureDetector {
///       onTap = function() state.count = state.count + 1 end,
///       child = Text { props.label .. ": " .. state.count },
///     }
///   end
/// end)
///
/// return App {
///   store = { title = "Counters" },
///   view = function(store, props)
///     return Column {
///       mainAxisAlignment = MainAxisAlignment.center,
///       children = {
///         Text { store.title, style = TextStyle { fontSize = 20 } },
///         Counter { key = "a", label = "a" },
///         Counter { key = "b", label = "b" },
///       },
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
  LuaTree? _treeOrNull;
  LuaTree get _tree => _treeOrNull!;
  set _tree(LuaTree tree) => _treeOrNull = tree;
  LuaTable? _app;
  final Map<String, LuaFunction> _api = {};
  Map<String, LuaHostFunction> _functions = const {};
  Object? _error;

  /// Changes whenever the app is loaded or released, so that a host Future
  /// of an earlier app does not resume into the current one.
  int _generation = 0;
  int _nextTask = 1;

  static const _apiNames = [
    'render',
    'update',
    'dispatch',
    'resume',
    'call',
    'set',
    'snapshot',
    'build',
    'release',
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
      try {
        _installModules(widget.runtime);
      } catch (error, stack) {
        _fail(error, stack);
      }
      _tree = _newTree();
    } else if (!mapEquals(oldWidget.props, widget.props) &&
        _tree.root != null) {
      _run('update', [widget.props]);
    }
  }

  @override
  void dispose() {
    _treeOrNull?.dispose();
    if (widget.controller?._state == this) widget.controller!._state = null;
    widget.store?.detach(_writeStore);
    _release(widget.runtime);
    super.dispose();
  }

  List<LuaWidgetLibrary> get _libraries {
    final libraries = widget.libraries;
    return [
      if (!libraries.any((library) => library.name == 'core')) coreLibrary(),
      ...libraries,
    ];
  }

  LuaTree _newTree() {
    _treeOrNull?.dispose();
    return LuaTree(
      mergeLibraries(_libraries),
      _onEvent,
      onBuild: _onBuild,
      onRelease: _onRelease,
    );
  }

  void _load() {
    _error = null;
    _generation++;
    try {
      final runtime = widget.runtime;
      _installModules(runtime);
      final results = _active(
        () => runtime.run(widget.source, name: widget.name),
      );
      final app = results.isEmpty ? null : results.first;
      if (app is! LuaTable) {
        throw LuaBridgeException(
          '${widget.name} must return App {...}, got ${app ?? 'nothing'}',
        );
      }
      _app = app;
      for (final name in _apiNames) {
        _api[name] = app[name] as LuaFunction;
      }
      _attachStore();
    } catch (error, stack) {
      _fail(error, stack);
    }
  }

  /// Loads `flb.ui` and the libraries' Lua modules, and installs their
  /// globals.
  void _installModules(LuaRuntime runtime) {
    _functions = mergeFunctions(_libraries);
    final globals = <String>[];
    for (final modules in [
      uiLuaModules,
      for (final library in _libraries) library.luaModules,
    ]) {
      for (final entry in modules.entries) {
        runtime.ensureModule(entry.key, source: entry.value);
      }
    }
    for (final library in _libraries) {
      if (library.luaGlobals case final module?) globals.add(module);
    }
    final install = runtime.load(_install, name: '=flb.ui.install');
    try {
      install.call([_HostDispatcher.of(runtime).function, ...globals]);
    } finally {
      install.release();
    }
  }

  static const _install = r'''
local ui = require("flb.ui")
ui.set_host((...))
ui.install()
for i = 2, select("#", ...) do ui.install((require((select(i, ...))))) end
''';

  void _attachStore() {
    final store = widget.store;
    final snapshot = _api['snapshot'];
    if (store == null || snapshot == null) return;
    store.attach(_plain(snapshot.call().firstOrNull), _writeStore);
  }

  void _writeStore(List<Object> luaPath, Object? value) =>
      _run('set', [luaPath, value], rethrowErrors: true);

  void _release(LuaRuntime runtime) {
    _generation++;
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
      final result = _plain(
        _active(() => function.call(arguments)).firstOrNull,
      );
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

  void _onEvent(int id, List<Object?> arguments) =>
      _run('dispatch', [id, arguments, arguments.length]);

  Map<Object?, Object?>? _onBuild(int id, List<Object?> arguments) {
    final function = _api['build'];
    if (function == null || widget.runtime.isClosed) return null;
    try {
      final result = _plain(
        _active(() => function.call([id, arguments, arguments.length]))
            .firstOrNull,
      );
      return result is Map<Object?, Object?> ? result : null;
    } catch (error, stack) {
      _fail(error, stack);
      return null;
    }
  }

  Map<Object?, Object?>? _onRelease(Object id) {
    final function = _api['release'];
    if (function == null || widget.runtime.isClosed) return null;
    try {
      final result = _plain(_active(() => function.call([id])).firstOrNull);
      return result is Map<Object?, Object?> ? result : null;
    } catch (error, stack) {
      _fail(error, stack);
      return null;
    }
  }

  Object? _callMethod(String name, Object? arguments) {
    if (_api['call'] == null) throw StateError('The Lua app is not loaded');
    return _run('call', [name, arguments], rethrowErrors: true)?['value'];
  }

  void _mountRoot() {
    final result = _plain(
      _active(() => _api['render']!.call([widget.props])).firstOrNull,
    );
    if (result is! Map) throw StateError('render returned $result');
    widget.store?.applyChanges(result['changes']);
    _tree.mount(result['root']);
  }

  /// Runs [body] with this view as the one whose host functions Lua calls.
  /// They run in the current zone: Lua calls them from a native callback,
  /// which would otherwise be in the root zone.
  T _active<T>(T Function() body) {
    final active = _HostDispatcher.of(widget.runtime).active
      ..add((this, Zone.current));
    try {
      return body();
    } finally {
      active.removeLast();
    }
  }

  /// Calls host function [name] for Lua; see [_HostDispatcher].
  Map<String, Object?> _invoke(String name, List<Object?> arguments) {
    final function = _functions[name];
    if (function == null) {
      throw LuaBridgeException(
        'There is no host function $name: register it in the functions of '
        'the LuaWidgetLibrary "${name.split('.').first}"',
      );
    }
    final result = function(context, arguments);
    if (result is! Future<Object?>) return {'v': result};
    final token = _nextTask++;
    final generation = _generation;
    result.then(
      (value) => _resume(generation, token, true, value),
      onError: (Object error, StackTrace stack) =>
          _resume(generation, token, false, error),
    );
    return {'p': token};
  }

  void _resume(int generation, int token, bool ok, Object? value) {
    if (!mounted || generation != _generation || widget.runtime.isClosed) {
      return;
    }
    _run('resume', [token, ok, ok ? value : '$value']);
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

/// Routes `ui.invoke` calls of one runtime to the [LuaView] that is running
/// Lua. Several views can share a runtime; Lua only runs inside one of
/// their calls at a time, the innermost being the last of [active].
class _HostDispatcher {
  _HostDispatcher(LuaRuntime runtime) {
    function = runtime.function(_call);
  }

  static final _dispatchers = Expando<_HostDispatcher>();

  static _HostDispatcher of(LuaRuntime runtime) =>
      _dispatchers[runtime] ??= _HostDispatcher(runtime);

  late final LuaFunction function;
  final List<(_LuaViewState, Zone)> active = [];

  /// `host(name, n, ...)`, see `ui.set_host` in `flb/ui.lua`.
  Object? _call(List<Object?> arguments) {
    final view = active.lastOrNull;
    final name = arguments.first;
    final count = arguments.length > 1 ? arguments[1] : 0;
    final values = [
      for (var i = 2; i < arguments.length; i++) _argument(arguments[i]),
    ];
    if (view == null) {
      throw LuaBridgeException(
        'ui.invoke($name) can only be called while a LuaView runs Lua',
      );
    }
    final (state, zone) = view;
    return zone.run(
      () => state._invoke('$name', [
        for (var i = 0; i < (count is int ? count : 0); i++)
          i < values.length ? values[i] : null,
      ]),
    );
  }

  static Object? _argument(Object? value) {
    if (value is LuaTable) return _plain(value);
    if (value is LuaRef) {
      value.release();
      throw LuaBridgeException(
        'Host functions take data, not a ${value.runtimeType}',
      );
    }
    return value;
  }
}
