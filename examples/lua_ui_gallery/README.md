# lua_ui_gallery

A macOS app whose screens are Lua scripts, to see
`flutter_lua_bridge_ui`, its Material and Cupertino packages and
`flutter_lua_bridge_remote` working:

```sh
fvm flutter run -d macos
```

| Screen | Script | What to try |
| --- | --- | --- |
| Home | `assets/lua/home.lua` | Each tile is `Navigator.pushNamed`; the handler waits for the route's result and shows it |
| Core | `assets/lua/core.lua` | Layout widgets and value types; a 1000-item `ListView.builder` whose items are components. Favorites are store state and survive scrolling; the per-item tap count is local state and is gone after the item scrolls away (Lua releases it) |
| Material | `assets/lua/material.lua` | Buttons, `Switch`, `Checkbox`, `Slider`, a `TextField` that Lua clears on submit, chips, `Colors`; `Gallery.fetchQuote` is a Dart `Future` the handler waits for |
| Cupertino | `assets/lua/cupertino.lua` | Navigation bar, grouped list, segmented control, switch, slider, text field; pops with a result |
| Routes | `assets/lua/routes/hub.lua`, `picker.lua` | See below |
| Remote | `lib/remote_page.dart`, `assets/remote/` | A local HTTP server publishes bundle v1, v2 or a broken v3; go offline; clear the cache |

## Routes between Lua instances

`Navigator.pushNamed`, `pushReplacementNamed`, `pop`, `maybePop` and
`canPop` are Dart functions of `coreLibrary()`; the app's own Dart functions
(`Gallery.instances`, `Gallery.fetchQuote`, `Gallery.showSnackBar`) are
registered the same way in `galleryLibrary()` (`lib/gallery.dart`):

```dart
LuaWidgetLibrary(
  name: 'gallery',
  widgets: const {},
  functions: {
    'Gallery.fetchQuote': (context, args) async { ... },  // a Future: Lua waits
  },
  luaModules: const {
    'gallery': 'return require("flb.ui").functions("gallery", { "Gallery.fetchQuote", ... })',
  },
  luaGlobals: 'gallery',
)
```

`onGenerateRoute` builds a `LuaPage` for every route: the route's script in
a `LuaRuntime` of its own, with `settings.arguments` as `props.arguments`.
On the routes screen:

- **Open another level** pushes `/routes` again: the same script, a new
  instance with its own state. The list of live instances comes from
  `Gallery.instances()`.
- **Pick a color** pushes `/routes/picker` and waits;
  `Navigator.pop({ name = ..., value = ... })` there is the value of
  `Navigator.pushNamed` here.
- **Replace** is `pushReplacementNamed` with a `result` for the screen
  below.
- **Back with the count** pops with a table the caller receives.

## Tests

`test/gallery_test.dart` drives every screen as widget tests (part of
`tool/ci_light.sh`). The same tests run in the macOS app with

```sh
fvm flutter test integration_test -d macos
```
