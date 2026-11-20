// Drives the real app on a device or desktop and fails on any uncaught
// exception or Flutter error:
//
//   flutter test integration_test -d macos
import 'package:material_ui/material_ui.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_example/game/formulas.dart';
import 'package:flutter_lua_bridge_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Pumps frames until [finder] matches, in real time.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      fail('Timed out waiting for $finder');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls the first scrollable until [finder] is built and visible, then
/// taps it.
Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home: the basic bridge and the language switch', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('运行 Bridge 测试'));
    await waitFor(tester, find.text('Lua version = ${LuaRuntime.luaVersion}'));

    await tester.tap(find.byTooltip('切换语言'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Run Bridge Test'), findsOneWidget);
    await tester.tap(find.byTooltip('Run Bridge Test'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Switch Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('中文').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('运行 Bridge 测试'), findsOneWidget);
  });

  testWidgets('game: every scene with every formula backend', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('抽卡战斗游戏测试'));
    await waitFor(tester, find.text('狂暴战士'));
    await tester.pumpAndSettle();

    // Instant simulation, so each battle runs to the end at once.
    await scrollAndTap(tester, find.text('播放战斗动画'));
    await tester.pumpAndSettle();

    for (final backend in FormulaBackend.values) {
      await scrollAndTap(tester, find.text(backend.label));
      await tester.pumpAndSettle();
      for (final scene in ['平衡对战', '治疗测试', '速度测试', '坦克测试']) {
        await scrollAndTap(tester, find.text(scene));
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing, reason: '$backend $scene');
        await waitFor(tester, find.textContaining('${backend.label}：模拟耗时'));
      }
    }
  });

  testWidgets('game: animated arena, pause, reset and leave mid-battle', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('抽卡战斗游戏测试'));
    await waitFor(tester, find.text('狂暴战士'));
    await tester.pumpAndSettle();

    for (final backend in [FormulaBackend.o1, FormulaBackend.o3]) {
      await scrollAndTap(tester, find.text(backend.label));
      await tester.pumpAndSettle();
      await scrollAndTap(tester, find.text('治疗测试'));
      await waitFor(tester, find.text('战斗竞技场 · ${backend.label}'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('开始'));
      await waitFor(tester, find.textContaining('第 2 回合'));
      await tester.tap(find.text('暂停'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('继续'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byTooltip('重置'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('开始'));
      await tester.pump(const Duration(seconds: 1));
      // Leave while the battle is still running.
      await back(tester);
      await tester.pump(const Duration(seconds: 2));
    }
  });

  testWidgets('game: card details and the card editor', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('抽卡战斗游戏测试'));
    await waitFor(tester, find.text('狂暴战士'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('元素法师').first);
    await tester.pumpAndSettle();
    expect(find.text('关闭'), findsOneWidget);
    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('狂暴战士').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('编辑')),
    );
    await tester.pumpAndSettle();
    expect(find.text('编辑 狂暴战士'), findsOneWidget);

    // An invalid value is rejected, a valid one is saved.
    final hp = find.descendant(
      of: find.widgetWithText(Row, '生命值 (HP)'),
      matching: find.byType(EditableText),
    );
    // On desktop, typing goes through the real platform text input; route
    // it through the test text input so enterText can type repeatedly.
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
    Future<void> typeHp(String value) async {
      await tester.ensureVisible(hp);
      await tester.pumpAndSettle();
      await tester.enterText(hp, value);
      await tester.pump();
      expect(tester.widget<EditableText>(hp).controller.text, value);
    }

    await typeHp('abc');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('编辑 狂暴战士'), findsOneWidget);
    expect(find.text('请输入整数'), findsOneWidget);
    await typeHp('1500');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('狂暴战士 已保存'), findsOneWidget);

    // The edited card fights.
    await scrollAndTap(tester, find.text('播放战斗动画'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('平衡对战'));
    await waitFor(tester, find.textContaining('模拟耗时'));
  });

  testWidgets('safety levels: both scripts and a benchmark', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('抽卡战斗游戏测试'));
    await waitFor(tester, find.text('狂暴战士'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('安全级别对比'));
    await waitFor(tester, find.textContaining('LuaSuccess(Damage'));
    expect(find.byIcon(Icons.error), findsNothing);

    await tester.tap(find.text('有缺陷的 formulas_faulty.lua'));
    await waitFor(tester, find.textContaining('LuaFailure(type)'));
    // The O3 card sits further down the lazily built list.
    await tester.scrollUntilVisible(
      find.textContaining('throws LuaBridgeException'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('throws LuaBridgeException'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('正常的 formulas.lua'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('正常的 formulas.lua'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('正常的 formulas.lua'));
    await waitFor(tester, find.textContaining('LuaSuccess(Damage'));

    await scrollAndTap(tester, find.text('×1000'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, find.text('运行基准'));
    await waitFor(
      tester,
      find.byType(DataTable),
      timeout: const Duration(seconds: 60),
    );
    await tester.pumpAndSettle();
    for (final backend in FormulaBackend.values) {
      expect(
        find.descendant(
          of: find.byType(DataTable),
          matching: find.text(backend.label),
        ),
        findsOneWidget,
      );
    }
    await back(tester);
  });
}
