# flutter_lua_bridge_ui

Build Flutter widget trees from Lua, on
[`flutter_lua_bridge`](https://pub.dev/packages/flutter_lua_bridge). A Lua app
returns nodes; `LuaView` turns them into widgets from registered libraries.
State is reactive: after an event, only the components that read a changed
value render again in Lua, cross to Dart and rebuild in Flutter.

The package depends on `package:flutter/widgets.dart` only. Material and
Cupertino widgets are registered the same way as application widgets, from
packages of their own, so a core-only app never pulls them in.

## Usage

```dart
final lua = LuaRuntime.create(memoryLimit: 16 << 20);

LuaView(
  runtime: lua,
  source: luaSource, // from an asset, a file or the network
  libraries: [coreLibrary(icons: {'add': Icons.add})],
  store: store,           // optional LuaStore, mirrored both ways
  controller: controller, // optional LuaViewController
  fallback: (context, error) => const Text('Unavailable'),
)
```

```lua
local ui = require("flb.ui")

-- setup runs once per instance and returns the render function.
local Item = ui.component(function(props)
  local local_state = ui.state { pressed = false }
  return function(props)
    return ui.GestureDetector {
      onTap = function() props.item.done = not props.item.done end,
      child = ui.Text { (props.item.done and "✓ " or "") .. props.item.title },
    }
  end
end)

return ui.app {
  store = { todos = { { title = "Write the docs", done = false } } },
  methods = {
    add = function(store, title) table.insert(store.todos, { title = title, done = false }) end,
  },
  view = function(store, props)
    local children = {}
    for i, todo in ipairs(store.todos) do
      children[i] = Item { key = i, item = todo }
    end
    return ui.Column { spacing = 8, children = children }
  end,
}
```

- **Nodes.** `ui.Column{...}`, `ui.node("library.Widget", {...})`. Positional
  entries are children (and a single one is also `child`); a string as the
  only entry of `Text` is its text; functions are event handlers; `key` is
  the widget key.
- **Components.** `ui.component(setup)`. An instance renders again only when
  reactive state it read changed, or when its parent passes props that
  differ field by field. Otherwise Lua sends a reference and Flutter skips
  the instance.
- **State.** `ui.state{}` inside setup, and the app `store`. Both are
  reactive proxies: reads are tracked per component and key, writes
  re-render the readers. `table.insert`, `#t`, `ipairs` and `pairs` work on
  them; `ui.pairs` works on every Lua release, and `ui.raw` returns the
  plain table. Keep state to data (no functions in the store).
- **Store sync.** Writes to the store from Lua reach the Dart `LuaStore`
  with the update that renders them; `store.set(path, value)` writes into
  Lua; `store.watch(path)` is a `ValueListenable`. Dart paths use zero-based
  list indices.
- **Methods.** `controller.call('add', 'Ship')` runs `methods.add(store, args)`
  and renders what changed.

Each event, method call or store write is one synchronous Lua call that
returns only the changed components; each component instance is a
`LuaComponentWidget` with its own notifier.

## Libraries

Lua names a widget `library.Widget`; without a library it means `core`.
`coreLibrary` registers `Align`, `AspectRatio`, `Center`, `ClipRRect`,
`ColoredBox`, `Column`, `Container`, `DecoratedBox`, `DefaultTextStyle`,
`Expanded`, `Flexible`, `GestureDetector`, `Icon`, `Image`, `ListView`,
`Opacity`, `Padding`, `Positioned`, `Row`, `SafeArea`,
`SingleChildScrollView`, `SizedBox`, `Spacer`, `Stack`, `Text` and `Wrap`.

A widget is in the app only because a registered builder references it, so
the Dart tree shaker keeps exactly what is registered. Icons are registered
by name with constant `IconData`, so the icon font tree shaker keeps working
(no `--no-tree-shake-icons`).

Other libraries, including the planned `flutter_lua_bridge_ui_material`
(depending on `material_ui`) and `flutter_lua_bridge_ui_cupertino`
(depending on `cupertino_ui`), are a name and a map of builders:

```dart
final material = LuaWidgetLibrary(
  name: 'material',
  widgets: {
    'ElevatedButton': (context, args) => ElevatedButton(
      onPressed: args.voidHandler(['onPressed']),
      child: args.optionalChild(['child']),
    ),
    'Switch': (context, args) => Switch(
      value: args.v<bool>(['value']) ?? false,
      onChanged: args.handler(['onChanged'],
          (trigger) => (bool value) => trigger({'value': value})),
    ),
  },
);
```

```lua
local material = ui.library("material", { "ElevatedButton", "Switch" })
material.Switch { value = store.on, onChanged = function(e) store.on = e.value end }
```

`LuaWidgetArgs` reads arguments by key path, as `DataSource` does in
`package:rfw`: `args.v<double>(['style', 'fontSize'])`, `args.childList(['children'])`.
`LuaDecoders` turns Lua values into colors (`0xAARRGGBB`, `"#RRGGBB"`), edge
insets, alignments, border radii, decorations, gradients, text styles,
enums (by name), durations (milliseconds) and images.

## Teal

`lua/types/flb/ui.d.tl` declares the module. Add the package's `lua/types`
to `include_dir` in `tlconfig.lua`. Teal table types cannot mix array and
map entries, so Teal code writes `children = {...}` and `text = ...` instead
of positional entries.

## Performance

macOS profile build, a list of N items of 6 nodes each, time on the UI thread
for one interaction (Lua, copying, building widgets, then the frame's build
and layout), median of 10:

| Items | Whole tree renders | Components, 1 item changes | Components, root re-renders |
| --- | --- | --- | --- |
| 200 | 11.1 ms | 1.4 ms | 5.5 ms |
| 1000 | 83.5 ms | 6.3 ms | 9.5 ms |

With components, the Lua side of a one-item change stays at 0.02 ms for any
list size. Swapping the whole library in `package:rfw` costs about 100 ms
for 1000 such items. The benchmark is
`examples/lua_canvas_host/lib/bench_lua_view.dart`.

Lua runs synchronously on the isolate that created the runtime. Give the
runtime a memory limit for code you do not trust, and keep long work out of
event handlers.
