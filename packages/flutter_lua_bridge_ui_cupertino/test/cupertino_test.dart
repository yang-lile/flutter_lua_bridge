import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_lua_bridge_ui_cupertino/flutter_lua_bridge_ui_cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

final libraries = [cupertinoLibrary()];

Widget host(LuaRuntime lua, String source, LuaStore store) => CupertinoApp(
  home: LuaView(
    runtime: lua,
    source: source,
    libraries: libraries,
    store: store,
  ),
);

const settings = r'''
return App {
  store = { wifi = false, mode = 1, name = "", taps = 0 },
  view = function(store)
    return CupertinoPageScaffold {
      navigationBar = CupertinoNavigationBar { middle = Text { "Settings" } },
      child = CupertinoListSection.insetGrouped {
        children = {
          CupertinoListTile {
            title = Text { "Wi-Fi" },
            trailing = CupertinoSwitch {
              value = store.wifi,
              activeTrackColor = CupertinoColors.systemGreen,
              onChanged = function(value) store.wifi = value end,
            },
          },
          CupertinoSegmentedControl {
            groupValue = store.mode,
            children = {
              { value = 1, child = Text { "Day" } },
              { value = 2, child = Text { "Night" } },
            },
            onValueChanged = function(value) store.mode = value end,
          },
          CupertinoTextField {
            text = store.name,
            placeholder = "Name",
            onChanged = function(value) store.name = value end,
          },
          CupertinoButton.filled {
            onPressed = function() store.taps = store.taps + 1 end,
            child = Text { "taps " .. store.taps },
          },
        },
      },
    }
  end,
}
''';

void main() {
  late LuaRuntime lua;
  setUp(() => lua = LuaRuntime.create());
  tearDown(() => lua.close());

  testWidgets('Cupertino controls send their values to Lua', (tester) async {
    final store = LuaStore();
    await tester.pumpWidget(host(lua, settings, store));
    expect(find.text('Settings'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoSwitch>(find.byType(CupertinoSwitch))
          .activeTrackColor,
      const Color(0xFF34C759),
    );

    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pumpAndSettle();
    expect(store.get(['wifi']), true);

    await tester.tap(find.text('Night'));
    await tester.pumpAndSettle();
    // A number value comes back as a number.
    expect(store.get(['mode']), 2);

    await tester.enterText(find.byType(CupertinoTextField), 'Ada');
    await tester.pump();
    expect(store.get(['name']), 'Ada');

    store.set(['name'], '');
    await tester.pump();
    expect(
      tester
          .widget<CupertinoTextField>(find.byType(CupertinoTextField))
          .controller!
          .text,
      '',
    );

    await tester.tap(find.text('taps 0'));
    await tester.pump();
    expect(find.text('taps 1'), findsOneWidget);
  });
}
