import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_lua_bridge_ui_cupertino/flutter_lua_bridge_ui_cupertino.dart';
import 'package:flutter_lua_bridge_ui_material/flutter_lua_bridge_ui_material.dart';
import 'package:material_ui/material_ui.dart';

import 'remote_page.dart';

/// The Lua screens of the gallery, by route name. Every route runs its
/// script in a runtime of its own (see [LuaPage]).
const luaRoutes = {
  '/': 'assets/lua/home.lua',
  '/core': 'assets/lua/core.lua',
  '/material': 'assets/lua/material.lua',
  '/cupertino': 'assets/lua/cupertino.lua',
  '/routes': 'assets/lua/routes/hub.lua',
  '/routes/picker': 'assets/lua/routes/picker.lua',
};

/// Reads the scripts of [luaRoutes].
Future<Map<String, String>> loadScripts(AssetBundle bundle) async => {
  for (final MapEntry(key: route, value: asset) in luaRoutes.entries)
    route: await bundle.loadString(asset, cache: false),
};

/// The icons Lua may name. Constant [IconData] keeps icon tree shaking.
const galleryIcons = {
  'add': Icons.add,
  'alt_route': Icons.alt_route,
  'arrow_back': Icons.arrow_back,
  'check': Icons.check,
  'chevron_right': Icons.chevron_right,
  'cloud_download': Icons.cloud_download,
  'color_lens': Icons.color_lens,
  'delete': Icons.delete,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'home': Icons.home,
  'layers': Icons.layers,
  'palette': Icons.palette,
  'phone_iphone': Icons.phone_iphone,
  'refresh': Icons.refresh,
  'remove': Icons.remove,
  'send': Icons.send,
  'star': Icons.star,
  'swap_horiz': Icons.swap_horiz,
  'widgets': Icons.widgets,
};

/// Dart functions of the gallery that Lua calls as `Gallery.*`:
///
/// * `Gallery.instances()` returns the routes whose Lua runtime is alive,
///   at once;
/// * `Gallery.fetchQuote(n)` answers after a delay, like a network call:
///   the calling handler waits for it;
/// * `Gallery.showSnackBar(text)` shows a Material snack bar.
LuaWidgetLibrary galleryLibrary() => LuaWidgetLibrary(
  name: 'gallery',
  widgets: const {},
  functions: {
    'Gallery.instances': (context, args) => [...LuaPage.alive],
    'Gallery.fetchQuote': (context, args) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final n = (args.firstOrNull as num?)?.toInt() ?? 0;
      return _quotes[n % _quotes.length];
    },
    'Gallery.showSnackBar': (context, args) {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text('${args.firstOrNull}')));
      return null;
    },
  },
  luaModules: const {
    'gallery': '''
return require("flb.ui").functions("gallery", {
  "Gallery.instances", "Gallery.fetchQuote", "Gallery.showSnackBar",
})
''',
  },
  luaGlobals: 'gallery',
);

const _quotes = [
  'Lua 负责描述界面，Flutter 负责画出来。',
  '只有读到变化数据的组件才会重新渲染。',
  '每个路由都是一个独立的 Lua 实例。',
];

/// The gallery app: every route of [scripts] is a [LuaPage]; `/remote` is
/// the Dart page that serves and loads remote bundles.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key, required this.scripts, this.remoteCache});

  /// Lua source by route name, see [loadScripts].
  final Map<String, String> scripts;

  /// The cache directory of the remote page; see [RemotePage].
  final Directory? remoteCache;

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  // One list for every page: LuaView renders everything again when it gets
  // a different list.
  final libraries = [
    coreLibrary(icons: galleryIcons),
    materialLibrary(),
    cupertinoLibrary(),
    galleryLibrary(),
  ];

  Route<Object?>? _route(RouteSettings settings) {
    final name = settings.name ?? '/';
    if (name == '/remote') {
      return MaterialPageRoute(
        settings: settings,
        builder: (context) => RemotePage(
          libraries: libraries,
          cacheDirectory: widget.remoteCache,
        ),
      );
    }
    final source = widget.scripts[name];
    if (source == null) return null;
    Widget page(BuildContext context) => LuaPage(
      route: name,
      source: source,
      arguments: settings.arguments,
      libraries: libraries,
    );
    return name.startsWith('/cupertino')
        ? CupertinoPageRoute(settings: settings, builder: page)
        : MaterialPageRoute(settings: settings, builder: page);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lua UI gallery',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    onGenerateRoute: _route,
    onUnknownRoute: (settings) => MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No route ${settings.name}')),
      ),
    ),
  );
}

/// One route: [source] runs in a [LuaRuntime] of its own, created with the
/// page and closed when the route is gone. The script gets
/// `props.route` and `props.arguments` (the `arguments` of
/// `Navigator.pushNamed`).
class LuaPage extends StatefulWidget {
  const LuaPage({
    super.key,
    required this.route,
    required this.source,
    required this.libraries,
    this.arguments,
  });

  final String route;
  final String source;
  final Object? arguments;
  final List<LuaWidgetLibrary> libraries;

  /// The routes whose runtime is open, oldest first.
  static List<String> get alive => [
    for (final state in _alive) state.widget.route,
  ];
  static final List<_LuaPageState> _alive = [];

  @override
  State<LuaPage> createState() => _LuaPageState();
}

class _LuaPageState extends State<LuaPage> {
  final runtime = LuaRuntime.create(memoryLimit: 32 << 20);

  @override
  void initState() {
    super.initState();
    LuaPage._alive.add(this);
  }

  @override
  void dispose() {
    LuaPage._alive.remove(this);
    super.dispose();
    runtime.close();
  }

  @override
  Widget build(BuildContext context) => LuaView(
    runtime: runtime,
    name: '@${luaRoutes[widget.route]}',
    source: widget.source,
    libraries: widget.libraries,
    props: {'route': widget.route, 'arguments': widget.arguments},
    fallback: (context, error) => Scaffold(
      appBar: AppBar(title: Text(widget.route)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$error', style: const TextStyle(color: Colors.red)),
      ),
    ),
  );
}
