# flutter_lua_bridge_ui_cupertino

Cupertino widgets for
[`flutter_lua_bridge_ui`](https://pub.dev/packages/flutter_lua_bridge_ui):
a widget registry for `package:cupertino_ui` and the `flb.ui.cupertino` Lua
module. It does not depend on Material.

```dart
LuaView(runtime: lua, source: luaSource, libraries: [cupertinoLibrary()])
```

```lua
return App {
  store = { wifi = true, mode = "day" },
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
        CupertinoSegmentedControl {
          groupValue = store.mode,
          children = {
            { value = "day", child = Text { "Day" } },
            { value = "night", child = Text { "Night" } },
          },
          onValueChanged = function(value) store.mode = value end,
        },
      } },
    }
  end,
}
```

## Widgets

`CupertinoActivityIndicator`, `CupertinoButton` (and `.filled`),
`CupertinoListSection` (and `.insetGrouped`), `CupertinoListTile`,
`CupertinoNavigationBar`, `CupertinoPageScaffold`,
`CupertinoSegmentedControl`, `CupertinoSlider`, `CupertinoSwitch` and
`CupertinoTextField`, with their Flutter argument names. Lua also gets
`CupertinoColors`.

Differences from Flutter, because of Lua:

- `CupertinoSegmentedControl.children` is a list of
  `{ value = ..., child = ... }`: Lua tables have no order.
- `CupertinoColors` holds the light variant of each dynamic color.
- `CupertinoTextField` takes `text`, as `TextField` does in
  `flutter_lua_bridge_ui_material`.

## Teal

`lua/types/flb/ui/cupertino.d.tl` and `lua/types/flb/ui/cupertino/prelude.d.tl`
declare the module and its globals; start Teal scripts with
`local ui = require("flb.ui.cupertino.prelude")`.
