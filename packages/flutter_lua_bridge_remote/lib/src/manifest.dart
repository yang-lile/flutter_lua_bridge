import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The bundle format version this package reads. A manifest that requires a
/// newer `api` is not loaded.
const int luaBundleApi = 1;

/// One Lua module of a bundle.
class LuaBundleModule {
  const LuaBundleModule({required this.path, required this.sha256});

  /// The file, relative to the bundle root, using `/`.
  final String path;

  /// The lowercase hex SHA-256 of the file.
  final String sha256;
}

/// The `bundle.json` of a Lua bundle:
///
/// ```json
/// {
///   "name": "shop",
///   "version": "1.4.0",
///   "entry": "app",
///   "modules": {
///     "app": {"path": "app.lua", "sha256": "…"},
///     "cart": {"path": "cart.lua", "sha256": "…"}
///   },
///   "requires": {"libraries": ["core", "material"], "api": 1}
/// }
/// ```
///
/// `entry` names the module that returns `App {...}`; the other modules are
/// available to `require`. `requires.libraries` are the widget libraries the
/// host must register, and `requires.api` the bundle format version.
class LuaBundleManifest {
  LuaBundleManifest({
    required this.name,
    required this.version,
    required this.entry,
    required this.modules,
    this.libraries = const ['core'],
    this.api = luaBundleApi,
  }) {
    _checkSegment('name', name);
    _checkSegment('version', version);
    if (!modules.containsKey(entry)) {
      throw FormatException('The entry module "$entry" is not in modules');
    }
    for (final MapEntry(key: module, value: file) in modules.entries) {
      if (!RegExp(r'^[A-Za-z_][\w]*(\.[A-Za-z_][\w]*)*$').hasMatch(module)) {
        throw FormatException('Invalid module name "$module"');
      }
      _checkPath(file.path);
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(file.sha256)) {
        throw FormatException('Invalid sha256 for module "$module"');
      }
    }
  }

  /// Parses and validates `bundle.json`.
  factory LuaBundleManifest.parse(String json) {
    final Object? data;
    try {
      data = jsonDecode(json);
    } on FormatException catch (error) {
      throw FormatException('bundle.json is not JSON: ${error.message}');
    }
    if (data is! Map<String, Object?>) {
      throw const FormatException('bundle.json must be an object');
    }
    T field<T>(Map<String, Object?> map, String key) {
      final value = map[key];
      if (value is T) return value;
      throw FormatException('bundle.json: "$key" is missing or not a $T');
    }

    final modules = <String, LuaBundleModule>{};
    for (final MapEntry(:key, :value) in field<Map<String, Object?>>(
      data,
      'modules',
    ).entries) {
      if (value is! Map<String, Object?>) {
        throw FormatException('bundle.json: module "$key" must be an object');
      }
      modules[key] = LuaBundleModule(
        path: field<String>(value, 'path'),
        sha256: field<String>(value, 'sha256').toLowerCase(),
      );
    }
    final requires = data['requires'];
    final libraries = requires is Map<String, Object?>
        ? (requires['libraries'] as List?)?.cast<String>()
        : null;
    final api = requires is Map<String, Object?> ? requires['api'] : null;
    return LuaBundleManifest(
      name: field<String>(data, 'name'),
      version: field<String>(data, 'version'),
      entry: field<String>(data, 'entry'),
      modules: modules,
      libraries: libraries ?? const ['core'],
      api: api is int ? api : luaBundleApi,
    );
  }

  /// Builds the manifest of [sources] (module name to Lua source).
  factory LuaBundleManifest.fromSources({
    required String name,
    required String version,
    required String entry,
    required Map<String, String> sources,
    List<String> libraries = const ['core'],
  }) => LuaBundleManifest(
    name: name,
    version: version,
    entry: entry,
    libraries: libraries,
    modules: {
      for (final MapEntry(key: module, value: source) in sources.entries)
        module: LuaBundleModule(
          path: '${module.replaceAll('.', '/')}.lua',
          sha256: sha256Hex(utf8.encode(source)),
        ),
    },
  );

  final String name;
  final String version;
  final String entry;
  final Map<String, LuaBundleModule> modules;
  final List<String> libraries;
  final int api;

  /// The manifest as `bundle.json`.
  String toJson() => const JsonEncoder.withIndent('  ').convert({
    'name': name,
    'version': version,
    'entry': entry,
    'modules': {
      for (final MapEntry(:key, :value) in modules.entries)
        key: {'path': value.path, 'sha256': value.sha256},
    },
    'requires': {'libraries': libraries, 'api': api},
  });
}

/// The lowercase hex SHA-256 of [bytes].
String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

void _checkSegment(String what, String value) {
  if (!RegExp(r'^[\w][\w.+-]*$').hasMatch(value) || value.contains('..')) {
    throw FormatException('Invalid bundle $what "$value"');
  }
}

/// A module path must stay inside the bundle: relative, `/`-separated, no
/// `..` or empty segments.
void _checkPath(String path) {
  final segments = path.split('/');
  final valid =
      path.isNotEmpty &&
      !path.startsWith('/') &&
      !path.contains('\\') &&
      segments.every(
        (s) => s.isNotEmpty && s != '.' && s != '..' && !s.contains(':'),
      );
  if (!valid) throw FormatException('Invalid module path "$path"');
}
