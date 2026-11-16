import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/game/battle_arena_page.dart';
import 'package:flutter_lua_bridge_example/game/formulas.dart';
import 'package:flutter_lua_bridge_example/game/game_demo_page.dart';
import 'package:flutter_lua_bridge_example/game/game_scripts.dart';
import 'package:flutter_lua_bridge_example/game/safety_levels_page.dart';
import 'package:flutter_lua_bridge_example/l10n/app_localizations.dart';

Widget app(Widget home) => MaterialApp(
  locale: const Locale('zh'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void useLargeView(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Pumps until [finder] matches; asset loading needs real async time.
Future<void> pumpUntil(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(finder, findsWidgets);
}

void main() {
  testWidgets('the game page switches backends and simulates instantly', (
    tester,
  ) async {
    useLargeView(tester, const Size(1200, 2400));
    await tester.pumpWidget(app(const GameDemoPage()));
    await pumpUntil(tester, find.text('狂暴战士'));

    expect(find.text('公式实现'), findsOneWidget);
    for (final backend in FormulaBackend.values) {
      expect(find.text(backend.label), findsOneWidget);
    }
    await tester.tap(find.text('O3'));
    await tester.pump();
    expect(find.text(FormulaBackend.o3.description), findsOneWidget);

    await tester.tap(find.text('播放战斗动画'));
    await tester.pump();
    await tester.ensureVisible(find.text('平衡对战'));
    await tester.tap(find.text('平衡对战'));
    await tester.pump();
    expect(find.text('战斗结果'), findsOneWidget);
    expect(find.textContaining('O3：模拟耗时'), findsOneWidget);
  });

  testWidgets('the safety level page shows how each level reports bugs', (
    tester,
  ) async {
    useLargeView(tester, const Size(1200, 4000));
    await tester.pumpWidget(app(const SafetyLevelsPage()));
    await pumpUntil(tester, find.textContaining('LuaSuccess(Damage'));
    expect(find.byIcon(Icons.error), findsNothing);

    await tester.tap(find.text('有缺陷的 formulas_faulty.lua'));
    await pumpUntil(tester, find.textContaining('LuaFailure(type)'));
    expect(find.textContaining('LuaFailure(runtime)'), findsWidgets);
    expect(find.textContaining('throws LuaTypeException'), findsWidgets);
    expect(find.textContaining('throws LuaBridgeException'), findsOneWidget);
  });

  late GameSources sources;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sources = await GameSources.load(rootBundle);
  });

  testWidgets('the arena plays the simulator events', (tester) async {
    useLargeView(tester, const Size(1400, 1000));
    final scripts = GameScripts.create(sources);
    addTearDown(scripts.close);
    final catalog = scripts.catalog();
    await tester.pumpWidget(
      app(
        BattleArenaPage(
          scripts: scripts,
          backend: FormulaBackend.o2,
          teamA: [catalog[0]],
          teamB: [catalog[3]],
          seed: 1,
        ),
      ),
    );
    expect(find.text('战斗竞技场 · O2'), findsOneWidget);
    await tester.tap(find.text('开始'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    // Turns advance and attacks are logged; the assassin's stealth (turn 0)
    // has already scrolled out of the log by now.
    expect(find.textContaining('第 3 回合'), findsOneWidget);
    expect(find.textContaining('重击 → 暗影刺客'), findsWidgets);
    // Leave the page so the battle loop stops.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
