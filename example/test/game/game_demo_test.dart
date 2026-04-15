import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/main.dart';

void main() {
  group('Game Demo Tests', () {
    testWidgets('Game Demo list tile exists and is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('抽卡战斗游戏测试'), findsOneWidget);
      expect(find.byIcon(Icons.gamepad), findsOneWidget);
    });

    testWidgets('Game Demo menu item exists in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final menuButtonFinder = find.widgetWithText(TextButton, '游戏Demo');
      expect(menuButtonFinder, findsOneWidget);
    });
  });
}
