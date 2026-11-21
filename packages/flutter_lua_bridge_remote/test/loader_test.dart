import 'dart:io';

import 'package:flutter_lua_bridge_remote/flutter_lua_bridge_remote.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundles.dart';

void main() {
  late Directory cache;
  setUp(
    () async => cache = await Directory.systemTemp.createTemp('lua_bundle'),
  );
  tearDown(() async => cache.delete(recursive: true));

  LuaBundleLoader loader(LuaBundleSource source, {LuaBundleSource? fallback}) =>
      LuaBundleLoader(
        source: source,
        cacheDirectory: cache,
        fallback: fallback,
      );

  test('downloads, verifies and caches a version', () async {
    final source = MemoryBundleSource(bundleFiles('1.0.0', labelApp('one')));
    final bundle = await loader(source).load();
    expect(bundle.origin, LuaBundleOrigin.source);
    expect(bundle.version, '1.0.0');
    expect(bundle.modules['label'], contains('one'));
    expect(source.reads, ['bundle.json', 'app.lua', 'label.lua']);
    expect(File('${cache.path}/versions/1.0.0/label.lua').existsSync(), isTrue);

    // The next load only asks for the manifest.
    source.reads.clear();
    await loader(source).load();
    expect(source.reads, ['bundle.json']);
  });

  test(
    'a module that does not match its sha256 falls back to the cache',
    () async {
      final v1 = loader(
        MemoryBundleSource(bundleFiles('1.0.0', labelApp('one'))),
      );
      await v1.load();
      await v1.markGood('1.0.0');

      final files = bundleFiles('2.0.0', labelApp('two'));
      files['label.lua'] = 'return { text = "tampered" }';
      final bundle = await loader(MemoryBundleSource(files)).load();
      expect(bundle.origin, LuaBundleOrigin.cache);
      expect(bundle.version, '1.0.0');
      expect(bundle.problems.single.toString(), contains('sha256'));
      expect(Directory('${cache.path}/versions/2.0.0').existsSync(), isFalse);
    },
  );

  test('offline, the last good version is used', () async {
    final v1 = loader(
      MemoryBundleSource(bundleFiles('1.0.0', labelApp('one'))),
    );
    await v1.load();
    await v1.markGood('1.0.0');
    final bundle = await loader(OfflineSource()).load();
    expect(bundle.origin, LuaBundleOrigin.cache);
    expect(bundle.modules['label'], contains('one'));
  });

  test('a version needing a library the host lacks is skipped', () async {
    final source = MemoryBundleSource(
      bundleFiles('1.0.0', labelApp('one'), libraries: ['core', 'material']),
    );
    final fallback = MemoryBundleSource(
      bundleFiles('0.1.0', labelApp('built-in')),
    );
    final bundle = await loader(source, fallback: fallback).load();
    expect(bundle.origin, LuaBundleOrigin.fallback);
    expect(bundle.problems.single.toString(), contains('material'));

    final withMaterial = await loader(source)
        .load(libraries: {'core', 'material'});
    expect(withMaterial.origin, LuaBundleOrigin.source);
  });

  test('a version marked bad is not loaded again', () async {
    final source = MemoryBundleSource(bundleFiles('1.0.0', labelApp('one')));
    final fallback = MemoryBundleSource(
      bundleFiles('0.1.0', labelApp('built-in')),
    );
    final l = loader(source, fallback: fallback);
    await l.load();
    await l.markBad('1.0.0');
    final bundle = await l.load();
    expect(bundle.origin, LuaBundleOrigin.fallback);
    expect(bundle.problems.single.toString(), contains('marked bad'));
    expect((await l.versions()).bad, ['1.0.0']);
  });

  test('only keepVersions good versions stay in the cache', () async {
    for (final version in ['1.0.0', '1.1.0', '1.2.0']) {
      final l = loader(
        MemoryBundleSource(bundleFiles(version, labelApp(version))),
      );
      await l.load();
      await l.markGood(version);
    }
    final kept = Directory('${cache.path}/versions')
        .listSync()
        .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .toSet();
    expect(kept, {'1.2.0', '1.1.0'});
    expect((await loader(OfflineSource()).versions()).good, ['1.2.0', '1.1.0']);
  });

  test('without any usable candidate the load throws', () async {
    expect(
      loader(OfflineSource()).load(),
      throwsA(
        isA<LuaBundleException>().having(
          (e) => e.toString(),
          'message',
          contains('network is unreachable'),
        ),
      ),
    );
  });

  test('verify can reject a manifest', () async {
    final l = LuaBundleLoader(
      source: MemoryBundleSource(bundleFiles('1.0.0', labelApp('one'))),
      cacheDirectory: cache,
      verify: (bytes) async => throw StateError('bad signature'),
    );
    expect(l.load(), throwsA(isA<LuaBundleException>()));
  });

  test('manifests cannot point outside the bundle', () {
    expect(
      () => LuaBundleManifest(
        name: 'demo',
        version: '1.0.0',
        entry: 'app',
        modules: {
          'app': LuaBundleModule(path: '../../etc/passwd', sha256: 'a' * 64),
        },
      ),
      throwsFormatException,
    );
    expect(
      () => LuaBundleManifest.parse(
        '{"name": "demo", "version": "../x", "entry": "app", "modules": {}}',
      ),
      throwsFormatException,
    );
  });

  test('HttpBundleSource reads over HTTP with headers', () async {
    final files = bundleFiles('1.0.0', labelApp('http'));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final seen = <String?>[];
    server.listen((request) {
      seen.add(request.headers.value('authorization'));
      final file = files[request.uri.path.substring('/demo/'.length)];
      if (file is String) {
        request.response.write(file);
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      request.response.close();
    });
    addTearDown(server.close);
    final source = HttpBundleSource(
      Uri.parse('http://127.0.0.1:${server.port}/demo/'),
      headers: {'authorization': 'Bearer t'},
    );
    final bundle = await loader(source).load();
    expect(bundle.modules['label'], contains('http'));
    expect(seen, everyElement('Bearer t'));
    await expectLater(
      source.read('missing.lua'),
      throwsA(isA<HttpException>()),
    );
  });
}
