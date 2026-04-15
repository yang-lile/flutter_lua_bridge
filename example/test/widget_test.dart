// Flutter Lua Bridge Example Widget Tests
//
// This file contains widget tests for the example application.

import 'package:flutter/material.dart';
import 'package:flutter_lua_bridge_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomePage Tests', () {
    testWidgets('App displays correct title and initial state', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the app title is displayed.
      expect(find.text('Flutter Lua Bridge Demo'), findsOneWidget);

      // Verify list title and description.
      expect(find.text('Flutter Lua Bridge - 测试列表'), findsOneWidget);
      expect(find.text('点击下方列表项运行对应测试'), findsOneWidget);

      // Verify both test list tiles are present.
      expect(find.text('Bridge 基础测试'), findsOneWidget);
      expect(find.text('抽卡战斗游戏测试'), findsOneWidget);

      // Verify the play icon for bridge test is present.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('Bridge test list tile executes Lua code and updates UI', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Initially Lua version text is null inside the list tile.
      expect(find.text('Lua version = null'), findsOneWidget);

      // Tap the play arrow icon button inside the Bridge 基础测试 list tile.
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // After tapping, the values should be updated (no longer null).
      expect(find.text('Lua version = null'), findsNothing);
      expect(find.textContaining('Lua version ='), findsOneWidget);
      expect(find.textContaining('Random value A:'), findsOneWidget);
      expect(find.textContaining('Random value B:'), findsOneWidget);
    });

    testWidgets('Game demo list tile navigates to GameDemoPage', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Tap the 抽卡战斗游戏测试 list tile.
      await tester.tap(find.text('抽卡战斗游戏测试'));
      await tester.pumpAndSettle();

      // Verify navigation occurred by checking the GameDemoPage app bar title.
      expect(find.text('抽卡战斗游戏 Demo'), findsOneWidget);
    });
  });
}
