// Writes bundle.json for a directory of Lua modules:
//
//   dart run flutter_lua_bridge_remote:pack <dir> --name shop --version 1.4.0 \
//       [--entry app] [--library material ...]
//
// Every `*.lua` under <dir> is a module named by its path (`ui/cart.lua` is
// `ui.cart`). Serve the directory as is; the loader reads bundle.json first.
import 'dart:io';

import 'package:flutter_lua_bridge_remote/src/manifest.dart';

void main(List<String> args) {
  String? dir, name, version;
  var entry = 'app';
  final libraries = <String>['core'];
  for (var i = 0; i < args.length; i++) {
    String next() => i + 1 < args.length ? args[++i] : _usage();
    switch (args[i]) {
      case '--name':
        name = next();
      case '--version':
        version = next();
      case '--entry':
        entry = next();
      case '--library':
        final library = next();
        if (!libraries.contains(library)) libraries.add(library);
      case final value when !value.startsWith('-') && dir == null:
        dir = value;
      default:
        _usage();
    }
  }
  if (dir == null || name == null || version == null) _usage();
  final root = Directory(dir);
  final sources = <String, String>{};
  for (final file in root.listSync(recursive: true).whereType<File>()) {
    final relative = file.path
        .substring(root.path.length)
        .replaceAll(Platform.pathSeparator, '/')
        .replaceFirst(RegExp('^/'), '');
    if (!relative.endsWith('.lua')) continue;
    final module = relative
        .substring(0, relative.length - 4)
        .replaceAll('/', '.');
    sources[module] = file.readAsStringSync();
  }
  final manifest = LuaBundleManifest.fromSources(
    name: name,
    version: version,
    entry: entry,
    sources: sources,
    libraries: libraries,
  );
  File('${root.path}/bundle.json').writeAsStringSync('${manifest.toJson()}\n');
  stdout.writeln(
    '${root.path}/bundle.json: $name $version, ${sources.length} modules',
  );
}

Never _usage() {
  stderr.writeln(
    'Usage: dart run flutter_lua_bridge_remote:pack <dir> --name <name> '
    '--version <version> [--entry app] [--library <name> ...]',
  );
  exit(64);
}
