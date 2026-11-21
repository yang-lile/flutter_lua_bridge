import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

/// Where a Lua bundle is read from: `bundle.json` and the module files, by
/// path relative to the bundle root.
abstract class LuaBundleSource {
  const LuaBundleSource();

  /// The bytes of the file at [path]. Throws when it cannot be read.
  Future<List<int>> read(String path);

  /// Describes the source in errors.
  String get description;

  @override
  String toString() => description;
}

/// Reads a bundle over HTTP(S) from [base], which should end with `/`.
class HttpBundleSource extends LuaBundleSource {
  HttpBundleSource(
    this.base, {
    this.client,
    this.headers = const {},
    this.timeout = const Duration(seconds: 15),
  });

  final Uri base;

  /// Sent with every request, for example an authorization header.
  final Map<String, String> headers;

  /// The limit for each request.
  final Duration timeout;

  /// The client to use; by default each read opens and closes its own.
  final HttpClient? client;

  @override
  String get description => base.toString();

  @override
  Future<List<int>> read(String path) async {
    final client = this.client ?? HttpClient();
    try {
      final uri = base.resolve(path);
      final request = await client.getUrl(uri).timeout(timeout);
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final builder = BytesBuilder(copy: false);
      await response.timeout(timeout).forEach(builder.add);
      return builder.takeBytes();
    } finally {
      if (this.client == null) client.close();
    }
  }
}

/// Reads a bundle from a directory, for example one the app downloaded or
/// unpacked itself.
class DirectoryBundleSource extends LuaBundleSource {
  const DirectoryBundleSource(this.directory);

  final Directory directory;

  @override
  String get description => directory.path;

  @override
  Future<List<int>> read(String path) =>
      File('${directory.path}/$path').readAsBytes();
}

/// Reads a bundle shipped in the app's assets under [prefix], such as
/// `assets/bundle/`: the built-in version to fall back to.
class AssetBundleSource extends LuaBundleSource {
  AssetBundleSource(this.prefix, {this.bundle});

  final String prefix;

  /// The asset bundle; defaults to `rootBundle`.
  final AssetBundle? bundle;

  @override
  String get description => 'assets $prefix';

  @override
  Future<List<int>> read(String path) async {
    final data = await (bundle ?? rootBundle).load('$prefix$path');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}

/// Serves files from memory, for tests and for bundles built in the app.
class MemoryBundleSource extends LuaBundleSource {
  MemoryBundleSource(this.files, {this.description = 'memory'});

  /// File contents by path; strings are encoded as UTF-8.
  final Map<String, Object> files;

  @override
  final String description;

  /// The paths read so far, in order.
  final List<String> reads = [];

  @override
  Future<List<int>> read(String path) async {
    reads.add(path);
    final file = files[path];
    return switch (file) {
      String() => utf8.encode(file),
      List<int>() => file,
      _ => throw FileSystemException('No such file in $description', path),
    };
  }
}
