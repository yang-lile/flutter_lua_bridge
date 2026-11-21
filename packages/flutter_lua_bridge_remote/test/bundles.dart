import 'package:flutter_lua_bridge_remote/flutter_lua_bridge_remote.dart';

/// The files of a bundle with [sources] (module name to Lua source).
Map<String, Object> bundleFiles(
  String version,
  Map<String, String> sources, {
  String entry = 'app',
  List<String> libraries = const ['core'],
}) {
  final manifest = LuaBundleManifest.fromSources(
    name: 'demo',
    version: version,
    entry: entry,
    sources: sources,
    libraries: libraries,
  );
  return {
    'bundle.json': manifest.toJson(),
    for (final MapEntry(:key, :value) in manifest.modules.entries)
      value.path: sources[key]!,
  };
}

/// An app whose view shows [text], using module `label` for it.
Map<String, String> labelApp(String text) => {
  'app': '''
local label = require("label")
return App { view = function() return Text { label.text } end }
''',
  'label': 'return { text = "$text" }',
};

/// A source that always fails, like a device without network.
class OfflineSource extends LuaBundleSource {
  @override
  String get description => 'offline';

  @override
  Future<List<int>> read(String path) async =>
      throw const SocketExceptionLike('network is unreachable');
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike(this.message);
  final String message;
  @override
  String toString() => message;
}
