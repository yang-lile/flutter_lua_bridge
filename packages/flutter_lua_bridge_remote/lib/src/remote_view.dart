import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';

import 'loader.dart';

/// Creates the runtime for one bundle version.
typedef LuaRuntimeFactory = LuaRuntime Function();

/// Shows a Lua app delivered as a bundle.
///
/// The view asks [loader] for the newest usable version, runs it in a fresh
/// runtime from [createRuntime] with the bundle's modules available to
/// `require`, and shows its entry module in a [LuaView]. When the first
/// render of a version succeeds, the version is marked good; when loading
/// or the first render fails, it is marked bad and the view falls back to
/// the next candidate (the last good version, then the loader's built-in
/// bundle). Errors after the first frame, such as in event handlers, go to
/// [onError] without changing versions.
///
/// ```dart
/// RemoteLuaView(
///   loader: LuaBundleLoader(
///     source: HttpBundleSource(Uri.parse('https://example.com/shop/')),
///     cacheDirectory: Directory('${support.path}/lua/shop'),
///     fallback: AssetBundleSource('assets/shop/'),
///   ),
///   libraries: [coreLibrary(icons: icons), materialLibrary()],
///   loading: (context) => const Center(child: Text('Loading')),
/// )
/// ```
class RemoteLuaView extends StatefulWidget {
  const RemoteLuaView({
    super.key,
    required this.loader,
    this.createRuntime = _defaultRuntime,
    this.libraries = const [],
    this.props = const {},
    this.controller,
    this.store,
    this.loading,
    this.fallback,
    this.onError,
    this.onLoaded,
  });

  final LuaBundleLoader loader;

  /// Creates a runtime per version; the view closes it. The default has a
  /// 32 MB memory limit.
  final LuaRuntimeFactory createRuntime;

  /// As [LuaView.libraries]. Their names are the libraries a bundle may
  /// require.
  final List<LuaWidgetLibrary> libraries;

  final Map<String, Object?> props;
  final LuaViewController? controller;
  final LuaStore? store;

  /// Shown while a bundle loads. Defaults to an empty box.
  final WidgetBuilder? loading;

  /// Shown when no version can be loaded or rendered.
  final LuaViewErrorBuilder? fallback;

  /// Receives every error, including those that made the view fall back.
  final void Function(Object error, StackTrace stack)? onError;

  /// Called with each bundle the view starts to show.
  final void Function(LoadedLuaBundle bundle)? onLoaded;

  @override
  State<RemoteLuaView> createState() => _RemoteLuaViewState();
}

LuaRuntime _defaultRuntime() => LuaRuntime.create(memoryLimit: 32 << 20);

class _RemoteLuaViewState extends State<RemoteLuaView> {
  LoadedLuaBundle? _bundle;
  LuaRuntime? _runtime;
  Object? _error;
  bool _failed = false;
  bool _good = false;
  int _generation = 0;

  Set<String> get _libraryNames => {
    'core',
    for (final library in widget.libraries) library.name,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RemoteLuaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) _load();
  }

  @override
  void dispose() {
    _generation++;
    _closeRuntime();
    super.dispose();
  }

  void _closeRuntime() {
    final runtime = _runtime;
    _runtime = null;
    if (runtime != null && !runtime.isClosed) runtime.close();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    try {
      final bundle = await widget.loader.load(libraries: _libraryNames);
      if (!mounted || generation != _generation) return;
      final runtime = widget.createRuntime();
      try {
        _preload(runtime, bundle);
      } catch (_) {
        runtime.close();
        rethrow;
      }
      setState(() {
        _closeRuntime();
        _bundle = bundle;
        _runtime = runtime;
        _error = null;
        _failed = false;
        _good = false;
      });
      widget.onLoaded?.call(bundle);
      SchedulerBinding.instance.addPostFrameCallback(
        (_) => _firstFrame(bundle, generation),
      );
    } catch (error, stack) {
      if (!mounted || generation != _generation) return;
      _report(error, stack);
      final bundle = _bundle;
      if (bundle != null && error is! LuaBundleException) {
        // The modules of a new version did not load: try the next one.
        await _reject(bundle);
      } else {
        setState(() => _error = error);
      }
    }
  }

  /// Makes every module of [bundle] available to `require`.
  void _preload(LuaRuntime runtime, LoadedLuaBundle bundle) {
    final register = runtime.load(
      'local name, fn = ...\n'
      'package.loaded[name] = nil\n'
      'package.preload[name] = fn',
      name: '=flb.remote.preload',
    );
    try {
      for (final MapEntry(key: name, value: source) in bundle.modules.entries) {
        if (name == bundle.manifest.entry) continue;
        final chunk = runtime.load(source, name: '@${bundle.chunkName(name)}');
        try {
          register.call([name, chunk]);
        } finally {
          chunk.release();
        }
      }
    } finally {
      register.release();
    }
  }

  Future<void> _firstFrame(LoadedLuaBundle bundle, int generation) async {
    if (!mounted || generation != _generation || _bundle != bundle) return;
    if (_failed) {
      await _reject(bundle);
    } else {
      _good = true;
      await widget.loader.markGood(bundle.version);
    }
  }

  Future<void> _reject(LoadedLuaBundle bundle) async {
    await widget.loader.markBad(bundle.version);
    if (!mounted) return;
    if (bundle.origin == LuaBundleOrigin.fallback) {
      // Nothing older to fall back to.
      setState(() {
        _closeRuntime();
        _bundle = null;
        _error ??= StateError('The built-in bundle failed');
      });
      return;
    }
    await _load();
  }

  void _report(Object error, StackTrace stack) {
    final onError = widget.onError;
    if (onError != null) {
      onError(error, stack);
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'flutter_lua_bridge_remote',
          context: ErrorDescription('while showing a Lua bundle'),
        ),
      );
    }
  }

  void _viewError(Object error, StackTrace stack) {
    if (!_good) _failed = true;
    _error = error;
    _report(error, stack);
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    final runtime = _runtime;
    if (bundle == null || runtime == null) {
      final error = _error;
      if (error != null) {
        return widget.fallback?.call(context, error) ?? ErrorWidget(error);
      }
      return widget.loading?.call(context) ?? const SizedBox.shrink();
    }
    return LuaView(
      key: ObjectKey(runtime),
      runtime: runtime,
      source: bundle.entrySource,
      name: '@${bundle.chunkName(bundle.manifest.entry)}',
      libraries: widget.libraries,
      props: widget.props,
      controller: widget.controller,
      store: widget.store,
      // Before the first frame a failure switches versions; after it, the
      // version stays and shows the fallback.
      fallback: (context, error) => _good
          ? widget.fallback?.call(context, error) ?? ErrorWidget(error)
          : widget.loading?.call(context) ?? const SizedBox.shrink(),
      onError: _viewError,
    );
  }
}
