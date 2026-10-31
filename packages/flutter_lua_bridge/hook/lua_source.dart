import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

/// User-define keys read from the consuming application's pubspec.
const luaSourceUserDefine = 'lua_source';
const luaVersionUserDefine = 'lua_version';
const luaSha256UserDefine = 'lua_sha256';

/// The Lua library sources required by the bridge.
///
/// Keep this list explicit. The Lua source directory also contains the
/// standalone `lua.c` and `luac.c` programs, which must not be compiled into
/// the native asset.
const luaLibrarySources = <String>[
  'lapi.c',
  'lauxlib.c',
  'lbaselib.c',
  'lcode.c',
  'lcorolib.c',
  'lctype.c',
  'ldblib.c',
  'ldebug.c',
  'ldo.c',
  'ldump.c',
  'lfunc.c',
  'lgc.c',
  'linit.c',
  'liolib.c',
  'llex.c',
  'lmathlib.c',
  'lmem.c',
  'loadlib.c',
  'lobject.c',
  'lopcodes.c',
  'loslib.c',
  'lparser.c',
  'lstate.c',
  'lstring.c',
  'lstrlib.c',
  'ltable.c',
  'ltablib.c',
  'ltm.c',
  'lundump.c',
  'lutf8lib.c',
  'lvm.c',
  'lzio.c',
];

/// A validated local or downloaded Lua source tree.
final class LuaSource {
  LuaSource._({required this.root, required this.sourceDirectory});

  /// The Lua source tree root, containing the `src/` directory.
  final Uri root;

  /// The directory containing Lua headers and C sources.
  final Uri sourceDirectory;

  List<Uri> get sourceFiles => [
    for (final name in luaLibrarySources) sourceDirectory.resolve(name),
  ];

  /// Resolves and validates a Lua source tree without imposing a version.
  factory LuaSource.fromRoot(Uri root) {
    final rootDirectory = Directory.fromUri(root).absolute;
    if (!rootDirectory.existsSync()) {
      throw FormatException(
        'Lua source directory does not exist: ${rootDirectory.path}',
      );
    }

    final sourceDirectory = rootDirectory.uri.resolve('src/');
    final sourceDirectoryFile = Directory.fromUri(sourceDirectory);
    if (!sourceDirectoryFile.existsSync()) {
      throw FormatException(
        'Lua source directory must contain src/: ${rootDirectory.path}',
      );
    }

    final header = File.fromUri(sourceDirectory.resolve('lua.h'));
    if (!header.existsSync()) {
      throw FormatException('Lua source is missing src/lua.h: ${header.path}');
    }

    final missing = <String>[];
    for (final name in luaLibrarySources) {
      if (!File.fromUri(sourceDirectory.resolve(name)).existsSync()) {
        missing.add(name);
      }
    }
    if (missing.isNotEmpty) {
      throw FormatException(
        'Lua source is missing required library files in '
        '${sourceDirectoryFile.path}: ${missing.join(', ')}',
      );
    }

    return LuaSource._(
      root: rootDirectory.uri,
      sourceDirectory: sourceDirectory,
    );
  }
}

/// Resolves a local source tree or downloads and extracts an archive.
Future<LuaSource> resolveLuaSource({
  required Uri packageRoot,
  required Uri outputDirectoryShared,
  Uri? configuredRoot,
  String? configuredSource,
  String? version,
  String? sha256,
}) async {
  final source = configuredSource?.trim();
  if (source == null || source.isEmpty) {
    return LuaSource.fromRoot(
      configuredRoot ?? packageRoot.resolve('lua_src/'),
    );
  }

  final uri = Uri.tryParse(source);
  final isWindowsDrivePath = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(source);
  if (!isWindowsDrivePath &&
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https')) {
    return _downloadLuaSource(
      uri: uri,
      version: version,
      expectedSha256: sha256,
      outputDirectoryShared: outputDirectoryShared,
    );
  }
  if (!isWindowsDrivePath && uri != null && uri.scheme == 'file') {
    return LuaSource.fromRoot(uri);
  }
  if (!isWindowsDrivePath && uri != null && uri.scheme.isNotEmpty) {
    throw FormatException(
      'Unsupported Lua source URI scheme: ${uri.scheme}. '
      'Use a local path or an http(s) archive URL.',
    );
  }

  return LuaSource.fromRoot(configuredRoot ?? packageRoot.resolve(source));
}

Future<LuaSource> _downloadLuaSource({
  required Uri uri,
  required String? version,
  required String? expectedSha256,
  required Uri outputDirectoryShared,
}) async {
  final cacheVersion = _validateVersion(version);
  final digest = _validateSha256(expectedSha256);
  final cacheKey = digest ?? _sha256(uri.toString().codeUnits);
  final cacheRoot = Directory.fromUri(
    outputDirectoryShared.resolve(
      'flutter_lua_bridge/lua/$cacheVersion/$cacheKey/',
    ),
  );
  final archiveFile = File.fromUri(cacheRoot.uri.resolve('source.archive'));
  final extractedDirectory = Directory.fromUri(
    cacheRoot.uri.resolve('source/'),
  );
  await cacheRoot.create(recursive: true);

  // The URL plus version is the cache identity. A digest adds integrity
  // verification; omitting it trusts the cached bytes until the version or
  // URL changes.
  List<int> bytes;
  if (archiveFile.existsSync()) {
    final cachedBytes = archiveFile.readAsBytesSync();
    if (digest == null || _sha256(cachedBytes) == digest) {
      bytes = cachedBytes;
    } else {
      bytes = await _download(uri);
    }
  } else {
    bytes = await _download(uri);
  }
  final actual = _sha256(bytes);
  if (digest != null && actual != digest) {
    throw FormatException(
      'Lua archive SHA-256 mismatch for $uri; '
      'expected $digest, found $actual.',
    );
  }
  if (!archiveFile.existsSync() ||
      actual != _sha256(archiveFile.readAsBytesSync())) {
    await archiveFile.writeAsBytes(bytes, flush: true);
  }

  if (extractedDirectory.existsSync()) {
    final cached = _findLuaSource(extractedDirectory.uri);
    if (cached != null) return cached;
    await extractedDirectory.delete(recursive: true);
  }
  await extractedDirectory.create(recursive: true);
  _extractArchive(bytes, uri, extractedDirectory);

  return _findLuaSource(extractedDirectory.uri) ??
      (throw FormatException(
        'Downloaded Lua archive does not contain a source tree with src/lua.h '
        'and the required library sources: $uri',
      ));
}

Future<List<int>> _download(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
        'Could not download Lua source from $uri '
        '(HTTP ${response.statusCode}).',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return bytes;
  } finally {
    client.close(force: true);
  }
}

void _extractArchive(List<int> bytes, Uri uri, Directory destination) {
  final path = uri.path.toLowerCase();
  final archive = switch (true) {
    _ when path.endsWith('.zip') || _looksLikeZip(bytes) =>
      ZipDecoder().decodeBytes(bytes),
    _
        when path.endsWith('.tar.gz') ||
            path.endsWith('.tgz') ||
            _looksLikeGzip(bytes) =>
      TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes)),
    _ => TarDecoder().decodeBytes(bytes),
  };

  for (final file in archive.files) {
    if (file.isSymbolicLink) {
      throw FormatException(
        'Lua archive contains an unsupported symlink: ${file.name}',
      );
    }
    final name = file.name.replaceAll('\\', '/');
    if (name.isEmpty || name == '.' || name.endsWith('/')) {
      if (name.split('/').contains('..')) {
        throw FormatException(
          'Lua archive contains an unsafe path: ${file.name}',
        );
      }
      if (name.isNotEmpty) {
        _archiveDirectory(destination, name);
      }
      continue;
    }
    final segments = name.split('/');
    if (name.startsWith('/') ||
        segments.contains('..') ||
        segments.first.contains(':')) {
      throw FormatException(
        'Lua archive contains an unsafe path: ${file.name}',
      );
    }
    final target = destination.uri.resolve(name).toFilePath();
    final output = File(target);
    output.parent.createSync(recursive: true);
    output.writeAsBytesSync(file.content as List<int>);
  }
}

void _archiveDirectory(Directory destination, String name) {
  Directory.fromUri(destination.uri.resolve(name)).createSync(recursive: true);
}

LuaSource? _findLuaSource(Uri extractionRoot) {
  final root = Directory.fromUri(extractionRoot);
  final candidates = <Directory>[
    root,
    ...root.listSync(recursive: true).whereType<Directory>(),
  ];
  for (final candidate in candidates) {
    if (File.fromUri(candidate.uri.resolve('src/lua.h')).existsSync()) {
      try {
        return LuaSource.fromRoot(candidate.uri);
      } on FormatException {
        // Keep searching in case this is an unrelated src/lua.h.
      }
    }
  }
  return null;
}

String _validateVersion(String? version) {
  final value = version?.trim();
  if (value == null ||
      value.isEmpty ||
      !RegExp(r'^[A-Za-z0-9._+-]+$').hasMatch(value)) {
    throw const FormatException(
      'lua_version is required for URL sources and must be a safe version label.',
    );
  }
  return value;
}

String? _validateSha256(String? value) {
  final digest = value?.trim().toLowerCase();
  if (digest == null || digest.isEmpty) return null;
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
    throw const FormatException(
      'lua_sha256 must be a 64-character SHA-256 digest when provided.',
    );
  }
  return digest;
}

String _sha256(List<int> bytes) => sha256.convert(bytes).toString();

bool _looksLikeZip(List<int> bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4b &&
    bytes[2] == 0x03 &&
    bytes[3] == 0x04;

bool _looksLikeGzip(List<int> bytes) =>
    bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
