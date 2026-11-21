// A Cupertino settings screen written in Lua.
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';
import 'package:flutter_lua_bridge_ui/flutter_lua_bridge_ui.dart';
import 'package:flutter_lua_bridge_ui_cupertino/flutter_lua_bridge_ui_cupertino.dart';

const source = r'''
return App {
  store = { wifi = true },
  view = function(store)
    return CupertinoPageScaffold {
      navigationBar = CupertinoNavigationBar { middle = Text { "Settings" } },
      child = CupertinoListSection.insetGrouped { children = {
        CupertinoListTile {
          title = Text { "Wi-Fi" },
          trailing = CupertinoSwitch {
            value = store.wifi,
            onChanged = function(value) store.wifi = value end,
          },
        },
      } },
    }
  end,
}
''';

void main() {
  final lua = LuaRuntime.create(memoryLimit: 16 << 20);
  runApp(
    CupertinoApp(
      home: LuaView(
        runtime: lua,
        source: source,
        libraries: [cupertinoLibrary()],
      ),
    ),
  );
}
