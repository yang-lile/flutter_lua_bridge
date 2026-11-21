# flutter_lua_bridge_ui_material

Material widgets for
[`flutter_lua_bridge_ui`](https://pub.dev/packages/flutter_lua_bridge_ui):
a widget registry for `package:material_ui` and the `flb.ui.material` Lua
module, so Lua scripts write Material screens the way Flutter does.

```dart
LuaView(
  runtime: lua,
  source: luaSource,
  libraries: [
    coreLibrary(icons: {'add': Icons.add, 'search': Icons.search}),
    materialLibrary(),
  ],
)
```

```lua
return App {
  store = { count = 0, dark = false },
  view = function(store)
    return Scaffold {
      appBar = AppBar { title = Text { "Counter" }, backgroundColor = Colors.indigo },
      body = ListView { children = {
        ListTile {
          title = Text { "Dark mode" },
          trailing = Switch {
            value = store.dark,
            onChanged = function(value) store.dark = value end,
          },
        },
        Card { color = Colors.amber.shade100, child = Text { "count " .. store.count } },
      } },
      floatingActionButton = FloatingActionButton {
        onPressed = function() store.count = store.count + 1 end,
        child = Icon { Icons.add },
      },
    }
  end,
}
```

## Widgets

`AppBar`, `Card`, `Checkbox`, `Chip`, `CircularProgressIndicator`, `Divider`,
`ElevatedButton` (and `.icon`), `FilledButton` (and `.icon`, `.tonal`),
`FloatingActionButton` (and `.extended`), `IconButton` (and `.filled`),
`InkWell`, `LinearProgressIndicator`, `ListTile`, `Material`,
`OutlinedButton` (and `.icon`), `Scaffold`, `Slider`, `Switch`, `TextButton`
(and `.icon`) and `TextField`.

Arguments have their Flutter names; callbacks receive the Flutter callback
parameters (`onChanged = function(value) ... end`). Lua also gets `Colors`
(with shades: `Colors.red.shade100`, `Colors.red[100]`), `InputDecoration`,
`OutlineInputBorder`, `UnderlineInputBorder`, `InputBorder.none` and
`TextInputType`.

Differences from Flutter, because Lua cannot hold Dart objects:

- `TextField` takes `text`, the value to show: the field keeps its own
  controller and only takes `text` when it differs from what is shown, so
  `onChanged` plus `text` gives a controlled field that Lua can clear.
- `Scaffold.appBar` gets the standard toolbar height.
- Icons are core `Icon` nodes; register them with `coreLibrary(icons:)`.

## Teal

`lua/types/flb/ui/material.d.tl` declares the module and
`lua/types/flb/ui/material/prelude.d.tl` its globals: add this package's
`lua/types` and `lua`, and those of `flutter_lua_bridge_ui`, to
`include_dir`, and start Teal scripts with
`local ui = require("flb.ui.material.prelude")`. Wrong argument names,
callback types and color names are type errors.
