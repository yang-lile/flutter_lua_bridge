import 'dart:convert';
import 'dart:io';

import 'manifest.dart';
import 'source.dart';

/// Where a [LoadedLuaBundle] came from.
enum LuaBundleOrigin {
  /// Fetched from the source in this load (modules already in the cache
  /// were not downloaded again).
  source,

  /// The newest good version in the cache, because the source failed.
  cache,

  /// The built-in fallback source, because the source and the cache failed.
  fallback,
}

/// A bundle ready to run: its manifest and module sources.
class LoadedLuaBundle {
  LoadedLuaBundle({
    required this.manifest,
    required this.modules,
    required this.origin,
    this.problems = const [],
  });

  final LuaBundleManifest manifest;

  /// Lua source by module name.
  final Map<String, String> modules;

  final LuaBundleOrigin origin;

  /// Why the newer candidates were skipped, oldest first.
  final List<Object> problems;

  String get version => manifest.version;

  /// The source of the entry module.
  String get entrySource => modules[manifest.entry]!;

  /// The chunk name of [module] in Lua error messages.
  String chunkName(String module) =>
      '${manifest.name}@${manifest.version}/${manifest.modules[module]!.path}';
}

/// A bundle could not be loaded from any candidate.
class LuaBundleException implements Exception {
  LuaBundleException(this.message, [this.problems = const []]);

  final String message;
  final List<Object> problems;

  @override
  String toString() => [
    'LuaBundleException: $message',
    for (final problem in problems) '  - $problem',
  ].join('\n');
}

/// Checks the raw `bundle.json` before it is trusted, for example against a
/// signature the app fetched alongside it. Throw to reject the bundle.
typedef LuaBundleVerifier = Future<void> Function(List<int> manifestBytes);

/// Loads a Lua bundle from [source], verifies it and keeps it in
/// [cacheDirectory], falling back to the last good version.
///
/// [load] fetches `bundle.json` and every module that is not in the cache,
/// checks each module against the SHA-256 in the manifest and commits the
/// version to `cacheDirectory/versions/<version>/` only when all of it is
/// there. When the source fails (network, HTTP status, checksum, a
/// required library the host does not have, a version marked bad), it
/// returns the newest version marked good in the cache, then the version
/// in [fallback], and only throws when none of them works.
///
/// The host marks a version with [markGood] once it rendered, and with
/// [markBad] when it failed: a bad version is never returned again, so a
/// broken release falls back to the last good one. `RemoteLuaView` does
/// both. Use one cache directory per bundle.
///
/// SHA-256 sums in the manifest detect damaged downloads, not tampering:
/// serve bundles over HTTPS, and check a signature in [verify] when the
/// scripts must come from you.
class LuaBundleLoader {
  LuaBundleLoader({
    required this.source,
    required this.cacheDirectory,
    this.fallback,
    this.keepVersions = 2,
    this.verify,
    this.manifestPath = 'bundle.json',
  }) : assert(keepVersions >= 1);

  final LuaBundleSource source;
  final Directory cacheDirectory;

  /// The built-in bundle, usually an `AssetBundleSource`.
  final LuaBundleSource? fallback;

  /// How many good versions stay in the cache.
  final int keepVersions;

  final LuaBundleVerifier? verify;

  /// The path of the manifest in every source.
  final String manifestPath;

  Directory get _versions => Directory('${cacheDirectory.path}/versions');
  File get _stateFile => File('${cacheDirectory.path}/state.json');

  /// Loads the newest usable version for a host that registered the widget
  /// [libraries] (by library name).
  Future<LoadedLuaBundle> load({Set<String> libraries = const {'core'}}) async {
    final problems = <Object>[];
    final state = await _readState();
    try {
      final bundle = await _fetch(source, libraries, state, cache: true);
      return LoadedLuaBundle(
        manifest: bundle.manifest,
        modules: bundle.modules,
        origin: LuaBundleOrigin.source,
      );
    } catch (error) {
      problems.add('${source.description}: $error');
    }
    for (final version in state.good) {
      try {
        final bundle = await _readCached(version, libraries);
        return LoadedLuaBundle(
          manifest: bundle.manifest,
          modules: bundle.modules,
          origin: LuaBundleOrigin.cache,
          problems: problems,
        );
      } catch (error) {
        problems.add('cached $version: $error');
      }
    }
    final fallback = this.fallback;
    if (fallback != null) {
      try {
        final bundle = await _fetch(fallback, libraries, state, cache: false);
        return LoadedLuaBundle(
          manifest: bundle.manifest,
          modules: bundle.modules,
          origin: LuaBundleOrigin.fallback,
          problems: problems,
        );
      } catch (error) {
        problems.add('${fallback.description}: $error');
      }
    }
    throw LuaBundleException('No usable Lua bundle', problems);
  }

  /// Records that [version] rendered: it becomes the first cache fallback,
  /// and versions beyond [keepVersions] are deleted.
  Future<void> markGood(String version) async {
    final state = await _readState();
    state.good
      ..remove(version)
      ..insert(0, version);
    state.bad.remove(version);
    await _writeState(state);
    await _prune(state);
  }

  /// Records that [version] failed: it is not loaded again.
  Future<void> markBad(String version) async {
    final state = await _readState();
    state.good.remove(version);
    if (!state.bad.contains(version)) state.bad.add(version);
    await _writeState(state);
    final directory = Directory('${_versions.path}/$version');
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  /// The versions marked good, newest first, and those marked bad.
  Future<({List<String> good, List<String> bad})> versions() async {
    final state = await _readState();
    return (good: List.of(state.good), bad: List.of(state.bad));
  }

  Future<_Bundle> _fetch(
    LuaBundleSource from,
    Set<String> libraries,
    _State state, {
    required bool cache,
  }) async {
    final bytes = await from.read(manifestPath);
    await verify?.call(bytes);
    final manifest = LuaBundleManifest.parse(utf8.decode(bytes));
    _check(manifest, libraries);
    if (state.bad.contains(manifest.version)) {
      throw StateError('version ${manifest.version} is marked bad');
    }
    final cached = Directory('${_versions.path}/${manifest.version}');
    final modules = <String, String>{};
    final downloaded = <String, List<int>>{};
    for (final MapEntry(key: name, value: file) in manifest.modules.entries) {
      List<int>? data;
      if (cache) {
        final local = File('${cached.path}/${file.path}');
        if (await local.exists()) {
          final bytes = await local.readAsBytes();
          if (sha256Hex(bytes) == file.sha256) data = bytes;
        }
      }
      if (data == null) {
        data = await from.read(file.path);
        if (sha256Hex(data) != file.sha256) {
          throw FormatException('${file.path} does not match its sha256');
        }
        downloaded[file.path] = data;
      }
      modules[name] = utf8.decode(data);
    }
    if (cache && (downloaded.isNotEmpty || !await cached.exists())) {
      await _commit(manifest, bytes, modules);
    }
    return _Bundle(manifest, modules);
  }

  /// Writes the version to a temporary directory, then renames it into
  /// place, so a version directory is always complete.
  Future<void> _commit(
    LuaBundleManifest manifest,
    List<int> manifestBytes,
    Map<String, String> modules,
  ) async {
    await _versions.create(recursive: true);
    final target = Directory('${_versions.path}/${manifest.version}');
    final temporary = Directory(
      '${_versions.path}/.${manifest.version}.${DateTime.now().microsecondsSinceEpoch}',
    );
    await temporary.create();
    try {
      await File('${temporary.path}/$manifestPath').writeAsBytes(manifestBytes);
      for (final MapEntry(key: name, value: source) in modules.entries) {
        final file = File('${temporary.path}/${manifest.modules[name]!.path}');
        await file.parent.create(recursive: true);
        await file.writeAsString(source);
      }
      if (await target.exists()) await target.delete(recursive: true);
      await temporary.rename(target.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete(recursive: true);
      rethrow;
    }
  }

  Future<_Bundle> _readCached(String version, Set<String> libraries) async {
    final directory = Directory('${_versions.path}/$version');
    final bytes = await File('${directory.path}/$manifestPath').readAsBytes();
    final manifest = LuaBundleManifest.parse(utf8.decode(bytes));
    _check(manifest, libraries);
    final modules = <String, String>{};
    for (final MapEntry(key: name, value: file) in manifest.modules.entries) {
      final data = await File('${directory.path}/${file.path}').readAsBytes();
      if (sha256Hex(data) != file.sha256) {
        throw FormatException('${file.path} does not match its sha256');
      }
      modules[name] = utf8.decode(data);
    }
    return _Bundle(manifest, modules);
  }

  void _check(LuaBundleManifest manifest, Set<String> libraries) {
    if (manifest.api > luaBundleApi) {
      throw StateError(
        'version ${manifest.version} needs bundle api ${manifest.api}, '
        'this app reads $luaBundleApi',
      );
    }
    final missing = manifest.libraries.where((l) => !libraries.contains(l));
    if (missing.isNotEmpty) {
      throw StateError(
        'version ${manifest.version} needs the widget libraries '
        '${missing.join(', ')}',
      );
    }
  }

  Future<void> _prune(_State state) async {
    if (!await _versions.exists()) return;
    final keep = state.good.take(keepVersions).toSet();
    await for (final entry in _versions.list()) {
      final name = entry.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entry is Directory && !keep.contains(name)) {
        await entry.delete(recursive: true);
      }
    }
    if (state.good.length > keepVersions) {
      state.good.removeRange(keepVersions, state.good.length);
      await _writeState(state);
    }
  }

  Future<_State> _readState() async {
    try {
      final data = jsonDecode(await _stateFile.readAsString());
      if (data is Map<String, Object?>) {
        return _State(
          [...?(data['good'] as List?)?.cast<String>()],
          [...?(data['bad'] as List?)?.cast<String>()],
        );
      }
    } on FileSystemException {
      // No state yet.
    } on FormatException {
      // A damaged state file is treated as empty.
    }
    return _State([], []);
  }

  Future<void> _writeState(_State state) async {
    await cacheDirectory.create(recursive: true);
    final temporary = File('${_stateFile.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({'good': state.good, 'bad': state.bad}),
    );
    await temporary.rename(_stateFile.path);
  }
}

class _Bundle {
  _Bundle(this.manifest, this.modules);
  final LuaBundleManifest manifest;
  final Map<String, String> modules;
}

class _State {
  _State(this.good, this.bad);
  final List<String> good;
  final List<String> bad;
}
