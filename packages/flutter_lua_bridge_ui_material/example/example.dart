// A Material counter whose screen is written in Lua.
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_lua_bridge_ui_material/flutter_lua_bridge_ui_material.dart';
import 'package:material_ui/material_ui.dart';

const source = r'''
return App {
  store = { count = 0 },
  view = function(store)
    return Scaffold {
      appBar = AppBar { title = Text { "Lua counter" } },
      body = Center { child = Text {
        "pressed " .. store.count .. " times",
        style = TextStyle { fontSize = 20 },
      } },
      floatingActionButton = FloatingActionButton {
        tooltip = "Increment",
        onPressed = function() store.count = store.count + 1 end,
        child = Icon { Icons.add },
      },
    }
  end,
}
''';

void main() {
  final lua = LuaRuntime.create(memoryLimit: 16 << 20);
  final libraries = [
    coreLibrary(icons: const {'add': Icons.add}),
    materialLibrary(),
  ];
  runApp(
    MaterialApp(
      home: LuaView(runtime: lua, source: source, libraries: libraries),
    ),
  );
}
