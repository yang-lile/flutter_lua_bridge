import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_lua_bridge_remote/flutter_lua_bridge_remote.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bundles.dart';

Widget host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

/// Lets the loader's file and source futures run, then pumps frames, until
/// [until] is shown (or a long while passed).
Future<void> settle(WidgetTester tester, Finder until) async {
  for (var i = 0; i < 500 && until.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}

void main() {
  late Directory cache;
  setUp(() async => cache = await Directory.systemTemp.createTemp('lua_view'));
  tearDown(() async => cache.delete(recursive: true));

  testWidgets('shows a bundle and marks it good after the first frame', (
    tester,
  ) async {
    final loader = LuaBundleLoader(
      source: MemoryBundleSource(bundleFiles('1.0.0', labelApp('remote one'))),
      cacheDirectory: cache,
    );
    final loaded = <LoadedLuaBundle>[];
    await tester.pumpWidget(
      host(
        RemoteLuaView(
          loader: loader,
          loading: (context) => const Text('loading'),
          onLoaded: loaded.add,
        ),
      ),
    );
    expect(find.text('loading'), findsOneWidget);
    await settle(tester, find.text('remote one'));
    expect(find.text('remote one'), findsOneWidget);
    // Let the post-frame markGood finish.
    for (var i = 0; i < 50; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)),
      );
    }
    expect(loaded.single.origin, LuaBundleOrigin.source);
    expect((await tester.runAsync(loader.versions))!.good, ['1.0.0']);
  });

  testWidgets(
    'a version that fails to render falls back to the last good one',
    (tester) async {
      final good = LuaBundleLoader(
        source: MemoryBundleSource(bundleFiles('1.0.0', labelApp('good'))),
        cacheDirectory: cache,
      );
      await tester.runAsync(() async {
        await good.load();
        await good.markGood('1.0.0');
      });

      final broken = LuaBundleLoader(
        source: MemoryBundleSource(
          bundleFiles('2.0.0', {
            'app':
                'return App { view = function() error("broken release") end }',
          }),
        ),
        cacheDirectory: cache,
      );
      final errors = <Object>[];
      final loaded = <String>[];
      await tester.pumpWidget(
        host(
          RemoteLuaView(
            loader: broken,
            onError: (error, stack) => errors.add(error),
            onLoaded: (bundle) => loaded.add(bundle.version),
          ),
        ),
      );
      await settle(tester, find.text('good'));
      expect(find.text('good'), findsOneWidget);
      expect(loaded, ['2.0.0', '1.0.0']);
      expect(errors.single.toString(), contains('broken release'));
      final versions = (await tester.runAsync(broken.versions))!;
      expect(versions.bad, ['2.0.0']);
      expect(versions.good, ['1.0.0']);
    },
  );

  testWidgets('the packed example bundle runs from a directory', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        RemoteLuaView(
          loader: LuaBundleLoader(
            source: DirectoryBundleSource(Directory('example/bundle')),
            cacheDirectory: cache,
          ),
        ),
      ),
    );
    await settle(tester, find.text('Hello from a Lua bundle'));
    await tester.tap(find.text('Hello from a Lua bundle'));
    await tester.pump();
    expect(find.text('Tapped 1 times'), findsOneWidget);
  });

  testWidgets('without any bundle the fallback is shown', (tester) async {
    await tester.pumpWidget(
      host(
        RemoteLuaView(
          loader: LuaBundleLoader(
            source: OfflineSource(),
            cacheDirectory: cache,
          ),
          onError: (error, stack) {},
          fallback: (context, error) => const Text('unavailable'),
        ),
      ),
    );
    await settle(tester, find.text('unavailable'));
    expect(find.text('unavailable'), findsOneWidget);
  });
}
