import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../hook/lua_source.dart';

void main() {
  test('uses the bundled Lua source tree by default', () async {
    final cache = Directory.systemTemp.createTempSync('flb-lua-default-');
    addTearDown(() => cache.deleteSync(recursive: true));

    final source = await resolveLuaSource(
      packageRoot: _packageRoot(),
      outputDirectoryShared: cache.uri,
    );

    expect(source.sourceFiles.length, luaLibrarySources.length);
    expect(
      source.sourceDirectory.path,
      contains('${Platform.pathSeparator}lua_src${Platform.pathSeparator}src'),
    );
  });

  test('rejects a missing Lua source tree', () {
    final directory = Directory.systemTemp.createTempSync('flb-lua-missing-');
    addTearDown(() => directory.deleteSync(recursive: true));

    expect(
      () => LuaSource.fromRoot(directory.uri),
      throwsA(isA<FormatException>()),
    );
  });

  test('accepts a custom Lua source tree without version validation', () async {
    final directory = _createSourceTree(version: 505);
    final cache = Directory.systemTemp.createTempSync('flb-lua-custom-cache-');
    addTearDown(() => directory.deleteSync(recursive: true));
    addTearDown(() => cache.deleteSync(recursive: true));

    final source = await resolveLuaSource(
      packageRoot: _packageRoot(),
      outputDirectoryShared: cache.uri,
      configuredRoot: directory.uri,
      configuredSource: directory.path,
    );
    expect(source.sourceFiles.length, luaLibrarySources.length);
  });

  test('downloads and verifies a pinned Lua archive', () async {
    final bytes = _zipSourceTree();
    final digest = sha256.convert(bytes).toString();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requestCount = 0;
    final subscription = server.listen((request) {
      requestCount++;
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('application', 'zip')
        ..add(bytes);
      request.response.close();
    });
    final cache = Directory.systemTemp.createTempSync('flb-lua-url-cache-');
    addTearDown(subscription.cancel);
    addTearDown(() => server.close(force: true));
    addTearDown(() => cache.deleteSync(recursive: true));

    final source = await resolveLuaSource(
      packageRoot: _packageRoot(),
      outputDirectoryShared: cache.uri,
      configuredSource: 'http://127.0.0.1:${server.port}/lua.zip',
      version: '5.5-custom',
      sha256: digest,
    );
    expect(source.sourceFiles.length, luaLibrarySources.length);

    final cached = await resolveLuaSource(
      packageRoot: _packageRoot(),
      outputDirectoryShared: cache.uri,
      configuredSource: 'http://127.0.0.1:${server.port}/lua.zip',
      version: '5.5-custom',
      sha256: digest,
    );
    expect(cached.sourceFiles.length, luaLibrarySources.length);
    expect(requestCount, 1);
  });

  test('allows a URL source without a SHA-256 digest', () async {
    final bytes = _zipSourceTree();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var requestCount = 0;
    final subscription = server.listen((request) {
      requestCount++;
      request.response
        ..statusCode = HttpStatus.ok
        ..add(bytes);
      request.response.close();
    });
    final cache = Directory.systemTemp.createTempSync('flb-lua-url-cache-');
    addTearDown(subscription.cancel);
    addTearDown(() => server.close(force: true));
    addTearDown(() => cache.deleteSync(recursive: true));

    final source = await resolveLuaSource(
      packageRoot: _packageRoot(),
      outputDirectoryShared: cache.uri,
      configuredSource: 'http://127.0.0.1:${server.port}/lua.zip',
      version: '5.5-no-checksum',
    );
    expect(source.sourceFiles.length, luaLibrarySources.length);

    final cached = await resolveLuaSource(
      packageRoot: _packageRoot(),
      outputDirectoryShared: cache.uri,
      configuredSource: 'http://127.0.0.1:${server.port}/lua.zip',
      version: '5.5-no-checksum',
    );
    expect(cached.sourceFiles.length, luaLibrarySources.length);
    expect(requestCount, 1);
  });

  test('rejects a downloaded archive with the wrong SHA-256', () async {
    final bytes = _zipSourceTree();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) {
      request.response
        ..statusCode = HttpStatus.ok
        ..add(bytes);
      request.response.close();
    });
    final cache = Directory.systemTemp.createTempSync('flb-lua-url-cache-');
    addTearDown(subscription.cancel);
    addTearDown(() => server.close(force: true));
    addTearDown(() => cache.deleteSync(recursive: true));

    await expectLater(
      resolveLuaSource(
        packageRoot: _packageRoot(),
        outputDirectoryShared: cache.uri,
        configuredSource: 'http://127.0.0.1:${server.port}/lua.zip',
        version: '5.5-custom',
        sha256: List.filled(64, '0').join(),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Uri _packageRoot() {
  final current = Directory.current.absolute;
  if (Directory.fromUri(current.uri.resolve('lua_src/')).existsSync()) {
    return current.uri;
  }
  return Directory.fromUri(
    current.uri.resolve('packages/flutter_lua_bridge/'),
  ).absolute.uri;
}

Directory _createSourceTree({required int version}) {
  final root = Directory.systemTemp.createTempSync('flb-lua-custom-');
  final source = Directory.fromUri(root.uri.resolve('src/'))..createSync();
  File.fromUri(
    source.uri.resolve('lua.h'),
  ).writeAsStringSync('#define LUA_VERSION_NUM $version\n');
  for (final name in luaLibrarySources) {
    File.fromUri(source.uri.resolve(name)).createSync();
  }
  return root;
}

List<int> _zipSourceTree() {
  final archive = Archive();
  const root = 'lua-custom';
  final header = utf8.encode('#define LUA_VERSION_NUM 505\n');
  archive.addFile(ArchiveFile('$root/src/lua.h', header.length, header));
  for (final name in luaLibrarySources) {
    archive.addFile(ArchiveFile('$root/src/$name', 0, <int>[]));
  }
  return ZipEncoder().encode(archive)!;
}
