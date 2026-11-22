import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_lua_bridge_remote/flutter_lua_bridge_remote.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The bundles the local server can publish, under `assets/remote/`.
const remoteVersions = {
  'v1': '1.0.0：计数器',
  'v2': '2.0.0：加了跳转和异步调用',
  'v3': '3.0.0：首帧报错的坏版本',
};

/// Serves a Lua bundle over HTTP on the loopback interface and shows it
/// with [RemoteLuaView], so the loader's checks, cache and fallbacks can be
/// tried by hand: publish another version, go offline, reload.
///
/// The built-in fallback is `assets/remote/builtin/`.
class RemotePage extends StatefulWidget {
  const RemotePage({super.key, required this.libraries, this.cacheDirectory});

  final List<LuaWidgetLibrary> libraries;

  /// Where verified versions are kept; defaults to a directory under the
  /// system temporary directory.
  final Directory? cacheDirectory;

  @override
  State<RemotePage> createState() => RemotePageState();
}

class RemotePageState extends State<RemotePage> {
  HttpServer? _server;

  /// RemoteLuaView marks versions good or bad after their first frame;
  /// the page polls the loader to show it.
  Timer? _poll;
  late final Directory _cache =
      widget.cacheDirectory ??
      Directory('${Directory.systemTemp.path}/lua_ui_gallery/remote');
  LuaBundleLoader? _loader;

  /// The version the server publishes, a key of [remoteVersions].
  String published = 'v1';
  bool offline = false;
  LoadedLuaBundle? bundle;
  ({List<String> good, List<String> bad}) versions = (good: [], bad: []);
  final List<String> log = [];

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    _poll?.cancel();
    unawaited(_server?.close(force: true));
    super.dispose();
  }

  Future<void> _start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (!mounted) {
      await server.close(force: true);
      return;
    }
    _server = server;
    server.listen(_serve);
    setState(() => _loader = _newLoader());
    _poll = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) => refreshVersions(),
    );
  }

  Future<void> _serve(HttpRequest request) async {
    final response = request.response;
    final path = request.uri.path.replaceFirst('/', '');
    if (offline) {
      response.statusCode = HttpStatus.serviceUnavailable;
    } else {
      try {
        final data = await rootBundle.load('assets/remote/$published/$path');
        response.add(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } catch (_) {
        response.statusCode = HttpStatus.notFound;
      }
    }
    await response.close();
  }

  LuaBundleLoader _newLoader() => LuaBundleLoader(
    source: HttpBundleSource(
      Uri.parse('http://127.0.0.1:${_server!.port}/'),
      timeout: const Duration(seconds: 3),
    ),
    cacheDirectory: _cache,
    fallback: AssetBundleSource('assets/remote/builtin/'),
  );

  /// Loads again from the server: [RemoteLuaView] reloads for a new loader.
  void reload() {
    if (_server == null) return;
    setState(() => _loader = _newLoader());
  }

  Future<void> refreshVersions() async {
    final loader = _loader;
    if (loader == null) return;
    final value = await loader.versions();
    if (mounted) setState(() => versions = value);
  }

  void publish(String version) {
    setState(() => published = version);
    reload();
  }

  void setOffline(bool value) {
    setState(() => offline = value);
    reload();
  }

  Future<void> clearCache() async {
    if (await _cache.exists()) await _cache.delete(recursive: true);
    if (!mounted) return;
    setState(() => log.clear());
    reload();
    await refreshVersions();
  }

  void _loaded(LoadedLuaBundle value) {
    setState(() {
      bundle = value;
      log.insert(
        0,
        '载入 ${value.version}（${_origin(value.origin)}）'
        '${value.problems.isEmpty ? '' : '，跳过：${value.problems.join('；')}'}',
      );
    });
  }

  // A failing first render reports while the view builds: log it after the
  // frame.
  void _error(Object error, StackTrace stack) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => log.insert(0, '错误：${'$error'.split('\n').first}'));
      }
    });
  }

  static String _origin(LuaBundleOrigin origin) => switch (origin) {
    LuaBundleOrigin.source => '来自服务器',
    LuaBundleOrigin.cache => '来自缓存',
    LuaBundleOrigin.fallback => '内置版本',
  };

  @override
  Widget build(BuildContext context) {
    final loader = _loader;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('远程下发'),
        actions: [
          IconButton(
            tooltip: '重新加载',
            onPressed: reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('服务器发布的版本', style: theme.textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              for (final MapEntry(key: id, value: label)
                  in remoteVersions.entries)
                ChoiceChip(
                  label: Text(label),
                  selected: published == id,
                  onSelected: (_) => publish(id),
                ),
            ],
          ),
          SwitchListTile(
            title: const Text('断网（服务器返回 503）'),
            value: offline,
            onChanged: setOffline,
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: clearCache,
                icon: const Icon(Icons.delete),
                label: const Text('清空缓存'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '正在显示：${bundle == null ? '—' : '${bundle!.version}（${_origin(bundle!.origin)}）'}',
            style: theme.textTheme.titleMedium,
          ),
          Text('可用版本：${versions.good.join('、')}'),
          Text('坏版本：${versions.bad.join('、')}'),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 260,
              child: loader == null
                  ? const Center(child: CircularProgressIndicator())
                  : RemoteLuaView(
                      loader: loader,
                      libraries: widget.libraries,
                      onLoaded: _loaded,
                      onError: _error,
                      loading: (context) =>
                          const Center(child: CircularProgressIndicator()),
                      fallback: (context, error) =>
                          Center(child: Text('没有可用版本：$error')),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text('日志', style: theme.textTheme.titleSmall),
          for (final line in log) Text(line, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
