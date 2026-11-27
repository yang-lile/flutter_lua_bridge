# flutter_lua_bridge_ui

Build Flutter widget trees from Lua, on
[`flutter_lua_bridge`](https://pub.dev/packages/flutter_lua_bridge). Lua
scripts read like Flutter code with braces instead of parentheses, and
state is reactive: after an event, only the components that read a changed
value render again in Lua, cross to Dart and rebuild in Flutter.

The package depends on `package:flutter/widgets.dart` only. Material and
Cupertino widgets come from
[`flutter_lua_bridge_ui_material`](https://pub.dev/packages/flutter_lua_bridge_ui_material)
and
[`flutter_lua_bridge_ui_cupertino`](https://pub.dev/packages/flutter_lua_bridge_ui_cupertino),
registered the same way as application widgets, so a core-only app never
pulls them in. To deliver scripts over the network, see
[`flutter_lua_bridge_remote`](https://pub.dev/packages/flutter_lua_bridge_remote).

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
-- setup runs once per instance and returns the render function.
local TodoItem = ui.component(function(props)
  local local_state = ui.state { pressed = false }
  return function(props)
    return GestureDetector {
      onTap = function() props.todo.done = not props.todo.done end,
      child = Padding {
        padding = EdgeInsets.symmetric { horizontal = 16, vertical = 8 },
        child = Text {
          (props.todo.done and "✓ " or "") .. props.todo.title,
          style = TextStyle { fontWeight = FontWeight.w500 },
        },
      },
    }
  end
end)

return App {
  store = { todos = { { title = "Write the docs", done = false } } },
  methods = {
    add = function(store, title) table.insert(store.todos, { title = title, done = false }) end,
  },
  view = function(store, props)
    return ListView.builder {
      itemCount = #store.todos,
      itemBuilder = function(context, index)
        return TodoItem { key = index, todo = store.todos[index + 1] }
      end,
    }
  end,
}
```

## Writing views

`LuaView` installs the widgets, the value types and `App` as globals, and
`ui` for the helpers below.

- **Widgets** take one table: `Column { mainAxisAlignment = ..., children = {...} }`.
  Arguments have their Flutter names. Array entries are the Flutter
  positional parameters only (`Text { "hi" }`, `Icon { Icons.add }`,
  `Image.network { url }`); children are always `child = ...` or
  `children = {...}`. Named constructors are fields:
  `ListView.builder {...}`, `SizedBox.shrink {}`. `key` is the widget key.
- **Values** are written like Flutter: `EdgeInsets.all(8)`,
  `EdgeInsets.symmetric { horizontal = 16 }`, `BorderRadius.circular(8)`,
  `Color(0xFF2196F3)`, `Color.fromARGB(255, 0, 0, 0)`, `Alignment.center`,
  `Offset(0, 2)`, `BoxDecoration {...}`, `TextStyle {...}`,
  `Duration { milliseconds = 300 }`, `NetworkImage(url)`. Enums are tables
  of names (`MainAxisAlignment.spaceBetween`, `FontWeight.w600`); a
  misspelled member is an error. `end` is a Lua keyword: write
  `CrossAxisAlignment["end"]` or `CrossAxisAlignment.end_`.
- **Events.** A function argument is an event handler and receives the
  Flutter callback's parameters (`onChanged = function(value) ... end`).
- **Builders.** A function argument whose name ends in `builder`/`Builder`
  is called by Flutter when it needs the widget, with `nil` for the
  `BuildContext` and Flutter's other parameters (`itemBuilder =
  function(context, index)`, zero-based). Each output is a component
  instance of its own: it renders again alone when state it read changes,
  and Lua releases it when Flutter disposes it.
- **Components.** `ui.component(setup)`. An instance renders again only
  when reactive state it read changed, or when its parent passes props that
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
- **Dart functions.** Lua calls Dart through the `functions` of a library
  (see below). Event handlers and methods run as Lua coroutines, so when a
  Dart function returns a `Future`, the handler waits for it and continues
  with its value: `local result = Navigator.pushNamed("/edit")` reads like
  `await`. A failed `Future` is a Lua error at the call (catch it with
  `pcall`). Called while rendering, a `Future` result is `nil`. Only the
  `functions` of a library wait this way: a `lua.function` of the core
  runtime that returns a `Future` raises an error in a handler.

Each event, method call or store write is one synchronous Lua call that
returns only the changed components; each component instance is a
`LuaComponentWidget` with its own listenable.

## Libraries

Lua names a widget `library.Widget`. `coreLibrary` registers `Align`,
`AspectRatio`, `Center`, `ClipRRect`, `ColoredBox`, `Column`, `Container`,
`DecoratedBox`, `DefaultTextStyle`, `Expanded`, `Flexible`,
`GestureDetector`, `Icon`, `Image` (and `.asset`, `.network`), `ListView`
(and `.builder`, `.separated`), `Opacity`, `Padding`, `Positioned`, `Row`,
`SafeArea`, `SingleChildScrollView`, `SizedBox` (and `.expand`, `.shrink`),
`Spacer`, `Stack`, `Text` and `Wrap`.

A widget is in the app only because a registered builder references it, so
the Dart tree shaker keeps exactly what is registered. Icons are registered
by name with constant `IconData`, so the icon font tree shaker keeps working
(no `--no-tree-shake-icons`).

Application widgets are a name, builders and optionally Lua constructors:

```dart
final app = LuaWidgetLibrary(
  name: 'app',
  widgets: {
    'Avatar': (context, args) => Avatar(
      url: args.v<String>(['url']),
      onTap: args.voidHandler(['onTap']),
    ),
    'Rating': (context, args) => Rating(
      value: args.v<int>(['value']) ?? 0,
      onChanged: args.handler(['onChanged'],
          (trigger) => (int value) => trigger([value])),
    ),
  },
  luaModules: {
    'app.widgets': 'return require("flb.ui").library("app", { "Avatar", "Rating" })',
  },
  luaGlobals: 'app.widgets', // its table becomes globals: Avatar {...}
);
```

A library can also give Lua Dart functions. Each receives the
`BuildContext` of the calling `LuaView` and the Lua arguments as plain
data; its result goes back to Lua, and a `Future` result makes the
calling handler wait:

```dart
final api = LuaWidgetLibrary(
  name: 'app',
  widgets: const {},
  functions: {
    'Api.fetchUser': (context, args) => repository.user(args[0]! as int),
    'Api.toast': (context, args) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${args[0]}')));
      return null;
    },
  },
  luaModules: {
    'app.api': 'return require("flb.ui").functions("app", { "Api.fetchUser", "Api.toast" })',
  },
  luaGlobals: 'app.api',
);
```

```lua
onPressed = function()
  store.loading = true
  local user = Api.fetchUser(42)   -- waits for the Future
  store.name, store.loading = user.name, false
  Api.toast("Loaded " .. user.name)
end,
```

`coreLibrary` has the `Navigator` functions, written like Flutter's static
methods without the `BuildContext`: `Navigator.pushNamed(name, { arguments
= ... })` returns the route's result, `Navigator.pushReplacementNamed(name,
{ arguments = ..., result = ... })`, `Navigator.pop(result)`,
`Navigator.maybePop(result)` and `Navigator.canPop()`. With
`onGenerateRoute` building a `LuaView` per route, each in its own
`LuaRuntime` with `settings.arguments` as props, every screen is an
independent Lua instance and results travel through `pop`:

```lua
-- In the list screen:
local picked = Navigator.pushNamed("/color", { arguments = { current = store.color } })
if picked then store.color = picked end
-- In the /color screen:
onTap = function() Navigator.pop(Colors.red.value) end
```

`examples/lua_ui_gallery` is a runnable app with these routes, the Material
and Cupertino widgets and remote bundles.

`LuaWidgetArgs` reads arguments by key path, as `DataSource` does in
`package:rfw`: `args.v<double>(['style', 'fontSize'])`,
`args.childList(['children'])`, `args.indexedBuilder(['itemBuilder'])`.
`LuaDecoders` turns Lua values into colors, edge insets, alignments, border
radii, decorations, gradients, text styles, enums, durations and images.
`LuaControlledText` keeps a `TextEditingController` for text fields whose
text Lua controls.

## Teal

`lua/types/flb/ui.d.tl` declares the module, with a record of arguments per
widget, and `lua/types/flb/ui/prelude.d.tl` its globals. Add the package's
`lua/types` and `lua` to `include_dir` in `tlconfig.lua` and start Teal
scripts with `local ui = require("flb.ui.prelude")`: misspelled arguments,
enum values and callback types are type errors. `App` is generic over the
store, so `view = function(s: Store, props: ui.Props): ui.Node` types the
store as your record.

## Performance

macOS profile build, a list of N items of 6 nodes each, time on the UI thread
for one interaction (Lua, copying, building widgets, then the frame's build
and layout), median of 10:

| Items | Whole tree renders | 1 item changes, `Column` | 1 item, `ListView` | 1 item, `ListView.builder` | Root re-renders, `ListView.builder` |
| --- | --- | --- | --- | --- | --- |
| 200 | 8.9 ms | 3.0–5.1 ms | 0.9–1.3 ms | 0.8–1.2 ms | 1.3–1.9 ms |
| 1000 | 58.7 ms | 4.5–5.9 ms | 0.5–0.7 ms | 0.9–1.0 ms | 2.1–2.3 ms |

The Lua side of a one-item change stays at 0.02–0.03 ms for any list size.
What grows with a `Column` is Flutter laying out every child; `ListView`
lays out the visible ones and `ListView.builder` also builds only those.
Swapping the whole library in `package:rfw` costs about 100 ms for 1000
such items. The benchmark is `examples/lua_canvas_host/lib/bench_lua_view.dart`.

Lua runs synchronously on the isolate that created the runtime. Give the
runtime a memory limit for code you do not trust, and keep long work out of
event handlers.
