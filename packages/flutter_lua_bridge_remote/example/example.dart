// Shows a Lua app served as a bundle, with a built-in copy in the assets.
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge_remote/flutter_lua_bridge_remote.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';

void main() {
  final loader = LuaBundleLoader(
    source: HttpBundleSource(Uri.parse('https://example.com/lua/hello/')),
    cacheDirectory: Directory('${Directory.systemTemp.path}/lua/hello'),
    fallback: AssetBundleSource('assets/lua/hello/'),
  );
  runApp(
    WidgetsApp(
      color: const Color(0xFF3F51B5),
      builder: (context, _) => RemoteLuaView(
        loader: loader,
        libraries: [coreLibrary()],
        loading: (context) => const Center(child: Text('Loading')),
        fallback: (context, error) => Center(child: Text('$error')),
      ),
    ),
  );
}
