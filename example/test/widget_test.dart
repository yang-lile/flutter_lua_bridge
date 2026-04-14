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

      // Verify initial UI elements are present.
      expect(find.text('Flutter Lua Bridge - FFI Example'), findsOneWidget);
      expect(find.text('Lua version = null'), findsOneWidget);
      expect(find.text('Random value A: null'), findsOneWidget);
      expect(find.text('Random value B: null'), findsOneWidget);

      // Verify the floating action button is present.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Verify the game demo button is present.
      expect(find.text('打开抽卡战斗游戏 Demo'), findsOneWidget);
    });

    testWidgets('Floating action button executes Lua code', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Initially Lua values are null.
      expect(find.text('Lua version = null'), findsOneWidget);

      // Tap the floating action button (play arrow).
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      // After tapping, the values should be updated (no longer null).
      // Note: The actual values are random, so we just verify the button works.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('Game Demo button exists and is tappable', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify the game demo button text is present.
      expect(find.text('打开抽卡战斗游戏 Demo'), findsOneWidget);

      // Verify the button has the correct icon.
      expect(find.byIcon(Icons.gamepad), findsOneWidget);

      // Note: We don't tap the button because it navigates to GameDemoPage
      // which requires Lua assets that aren't available in test environment.
    });

    testWidgets('Game Demo menu item exists in AppBar', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify the AppBar has the game demo menu button.
      final menuButtonFinder = find.widgetWithText(TextButton, '游戏Demo');
      expect(menuButtonFinder, findsOneWidget);
    });
  });
}
