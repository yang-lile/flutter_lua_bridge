import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_lua_bridge_ui_material/flutter_lua_bridge_ui_material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final libraries = [
  coreLibrary(icons: const {'add': Icons.add}),
  materialLibrary(),
];

Widget host(LuaRuntime lua, String source, {LuaStore? store}) => MaterialApp(
  home: LuaView(
    runtime: lua,
    source: source,
    libraries: libraries,
    store: store,
  ),
);

void main() {
  late LuaRuntime lua;
  setUp(() => lua = LuaRuntime.create());
  tearDown(() => lua.close());

  testWidgets('a Scaffold with an AppBar and a FloatingActionButton', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(lua, r'''
return App {
  store = { count = 0 },
  view = function(store)
    return Scaffold {
      appBar = AppBar { title = Text { "Counter" }, backgroundColor = Colors.blue },
      body = Center { child = Text { "count " .. store.count } },
      floatingActionButton = FloatingActionButton {
        tooltip = "add",
        onPressed = function() store.count = store.count + 1 end,
        child = Icon { Icons.add },
      },
    }
  end,
}
'''),
    );
    expect(find.text('Counter'), findsOneWidget);
    expect(
      tester.widget<AppBar>(find.byType(AppBar)).backgroundColor,
      Color(Colors.blue.toARGB32()),
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);
  });

  testWidgets('Switch, Checkbox and Slider send their values to Lua', (
    tester,
  ) async {
    final store = LuaStore();
    await tester.pumpWidget(
      host(lua, store: store, r'''
return App {
  store = { on = false, checked = false, level = 0.0 },
  view = function(store)
    return Scaffold { body = Column { children = {
      Switch { value = store.on, onChanged = function(v) store.on = v end },
      Checkbox { value = store.checked, onChanged = function(v) store.checked = v end },
      Slider { value = store.level, onChanged = function(v) store.level = v end },
    } } }
  end,
}
'''),
    );
    await tester.tap(find.byType(Switch));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(store.get(['on']), true);
    expect(store.get(['checked']), true);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tapAt(tester.getCenter(find.byType(Slider)));
    await tester.pump();
    expect(store.get(['level']), closeTo(0.5, 0.05));
  });

  testWidgets('TextField reports typing and follows text from Lua', (
    tester,
  ) async {
    final store = LuaStore();
    await tester.pumpWidget(
      host(lua, store: store, r'''
return App {
  store = { draft = "", sent = {} },
  view = function(store)
    return Scaffold { body = Column { children = {
      TextField {
        text = store.draft,
        decoration = InputDecoration { labelText = "Message", border = OutlineInputBorder {} },
        onChanged = function(value) store.draft = value end,
        onSubmitted = function(value)
          table.insert(store.sent, value)
          store.draft = ""
        end,
      },
      Text { "sent " .. #store.sent },
    } } }
  end,
}
'''),
    );
    expect(find.text('Message'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(store.get(['draft']), 'hello');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('sent 1'), findsOneWidget);
    expect(store.get(['sent', 0]), 'hello');
    // Lua cleared the draft: the field follows.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('buttons, list tiles and swatches', (tester) async {
    await tester.pumpWidget(
      host(lua, r'''
return App {
  store = { log = "" },
  view = function(store)
    local function log(s) return function() store.log = store.log .. s end end
    return Scaffold { body = ListView { children = {
      ElevatedButton { onPressed = log("e"), child = Text { "elevated" } },
      FilledButton.tonal { onPressed = log("f"), child = Text { "tonal" } },
      TextButton.icon { onPressed = log("t"), icon = Icon { Icons.add }, label = Text { "text" } },
      ListTile { title = Text { "tile" }, onTap = log("l") },
      Card { color = Colors.red.shade100, child = Text { "card" } },
      Divider { color = Colors.grey[300] },
      Text { "log " .. store.log },
    } } }
  end,
}
'''),
    );
    for (final label in ['elevated', 'tonal', 'text', 'tile']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }
    expect(find.text('log eftl'), findsOneWidget);
    expect(
      tester.widget<Card>(find.byType(Card)).color,
      Color(Colors.red.shade100.toARGB32()),
    );
    expect(
      tester.widget<Divider>(find.byType(Divider)).color,
      Color(Colors.grey[300]!.toARGB32()),
    );
  });
}
