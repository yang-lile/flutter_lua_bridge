import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lua_ui_gallery/gallery.dart';
import 'package:material_ui/material_ui.dart';

/// Drives every screen of the gallery the way a user would.
void main() {
  late Map<String, String> scripts;
  late Directory cache;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('lua_ui_gallery');
  });
  tearDown(() async {
    if (await cache.exists()) await cache.delete(recursive: true);
  });

  Future<void> start(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1200, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    scripts = (await tester.runAsync(() => loadScripts(rootBundle)))!;
    await tester.pumpWidget(GalleryApp(scripts: scripts, remoteCache: cache));
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  /// For screens with a spinner, which never settles: lets transitions
  /// finish.
  Future<void> tapAndWait(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('routes run separate Lua instances and pass results back', (
    tester,
  ) async {
    await start(tester);
    expect(LuaPage.alive, ['/']);

    await tap(tester, '路由跳转');
    expect(find.text('路由：第 1 层'), findsOneWidget);
    await tap(tester, '计数 +1（只影响本实例）');
    expect(find.text('这个实例的计数：1，颜色：未选择'), findsOneWidget);

    // The same script again, as a new instance with its own state.
    await tap(tester, '再开一层：同一脚本的新实例');
    expect(find.text('路由：第 2 层'), findsOneWidget);
    expect(LuaPage.alive, ['/', '/routes', '/routes']);
    expect(find.text('这个实例的计数：0，颜色：未选择'), findsOneWidget);
    await tap(tester, '计数 +1（只影响本实例）');
    await tap(tester, '计数 +1（只影响本实例）');
    await tap(tester, '返回上一层，带回计数');

    // The first instance kept its state and got the result.
    expect(find.text('路由：第 1 层'), findsOneWidget);
    expect(find.text('这个实例的计数：1，颜色：未选择'), findsOneWidget);
    expect(find.text('第 2 层返回：第 2 层，计数 2'), findsOneWidget);
    expect(LuaPage.alive, ['/', '/routes']);

    await tap(tester, '选颜色：等另一个实例返回');
    expect(find.text('选一个颜色'), findsOneWidget);
    await tap(tester, '蓝');
    expect(find.text('这个实例的计数：1，颜色：蓝'), findsOneWidget);
    expect(find.text('选色页返回：蓝'), findsOneWidget);

    // Replacing completes the home screen's pushNamed with `result`.
    await tap(tester, '替换为新实例（pushReplacementNamed）');
    expect(find.text('来自：替换前的第 1 层，canPop = true'), findsOneWidget);
    expect(LuaPage.alive, ['/', '/routes']);
    await tap(tester, '返回上一层，带回计数');
    expect(find.text('已打开 1 次。路由跳转 返回：被替换了'), findsOneWidget);
    expect(LuaPage.alive, ['/']);
  });

  testWidgets('Material widgets and Dart functions', (tester) async {
    await start(tester);
    await tap(tester, 'Material');

    await tap(tester, 'Filled');
    expect(find.text('按钮：按了 1 次'), findsOneWidget);
    await tap(tester, '已打开');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('已关闭'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Dart');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Chip, 'Dart'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );

    // Gallery.fetchQuote returns a Future; the handler waits for it.
    await tester.tap(find.text('取一句话'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('只有读到变化数据的组件才会重新渲染。'), findsOneWidget);

    await tap(tester, '完成');
    expect(find.text('已打开 1 次。Material 返回：按了 1 次'), findsOneWidget);
  });

  testWidgets('Cupertino widgets', (tester) async {
    await start(tester);
    // CupertinoActivityIndicator spins, so this screen never settles.
    await tapAndWait(tester, 'Cupertino');

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('开'), findsOneWidget);
    await tapAndWait(tester, '日');
    expect(find.text('按日'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoTextField), 'Ada');
    await tester.pump();
    expect(find.text('你好，Ada'), findsOneWidget);

    await tapAndWait(tester, '返回并带回名字');
    expect(find.text('已打开 1 次。Cupertino 返回：Ada'), findsOneWidget);
  });

  testWidgets('the core list builds lazily and keeps store state', (
    tester,
  ) async {
    await start(tester);
    await tap(tester, 'Core 组件');
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#500'), findsNothing);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();
    expect(find.text('收藏 1 项'), findsOneWidget);
    await tester.tap(find.text('#2'));
    await tester.pumpAndSettle();
    expect(find.text('本地点击 1 次'), findsOneWidget);

    // Scrolled away, items are released; the store keeps the favorite.
    await tester.drag(find.text('#3'), const Offset(0, -20000));
    await tester.pumpAndSettle();
    expect(find.text('#1'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 40000));
    await tester.pumpAndSettle();
    expect(find.text('#1'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('本地点击 1 次'), findsNothing);
  });

  testWidgets('remote bundles: download, bad version, offline, built-in', (
    tester,
  ) async {
    // The test binding answers every HTTP request with 400; this test talks
    // to the page's real local server.
    final overrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = overrides);
    await start(tester);
    await tapAndWait(tester, '远程下发');
    Future<void> until(Finder finder) async {
      for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        // Real time for IO, fake time for the page's timers.
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(finder, findsOneWidget);
    }

    await until(find.text('来自服务器的 v1'));
    await until(find.text('可用版本：1.0.0'));

    // v3 fails its first render: marked bad, back to the cached v1.
    await tester.tap(find.textContaining('3.0.0'));
    await until(find.text('坏版本：3.0.0'));
    await until(find.text('正在显示：1.0.0（来自缓存）'));

    await tester.tap(find.textContaining('2.0.0'));
    await until(find.text('来自服务器的 v2'));
    await until(find.text('可用版本：2.0.0、1.0.0'));

    // Offline: the newest good version from the cache.
    await tester.tap(find.byType(Switch));
    await until(find.text('正在显示：2.0.0（来自缓存）'));

    // Offline without a cache: the built-in bundle.
    await tester.tap(find.text('清空缓存'));
    await until(find.text('内置版本 0.9.0'));
  });
}
