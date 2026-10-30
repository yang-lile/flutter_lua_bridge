import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lua_bridge_example/main.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Game Demo Tests', () {
    testWidgets('Game Demo list tile exists and is tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('抽卡战斗游戏测试'), findsOneWidget);
      expect(find.byIcon(Icons.gamepad), findsOneWidget);
    });

    testWidgets('Game Demo list tile is wired to a tap handler', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final tileFinder = find.ancestor(
        of: find.text('抽卡战斗游戏测试'),
        matching: find.byType(ListTile),
      );
      expect(tileFinder, findsOneWidget);

      final tile = tester.widget<ListTile>(tileFinder);
      expect(tile.onTap, isNotNull);
      expect(
        find.descendant(
          of: tileFinder,
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsOneWidget,
      );
    });
  });
}
