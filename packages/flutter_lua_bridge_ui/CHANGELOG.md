## 0.1.0

- First release: `LuaView`, `LuaWidgetLibrary`, `LuaWidgetArgs`,
  `LuaDecoders`, `LuaStore`, `LuaControlledText` and the `core` widget
  registry, with the `flb.ui` Lua module.
- Lua writes widgets and values like Flutter (`Column { children = {...} }`,
  `EdgeInsets.all(8)`, `MainAxisAlignment.center`), installed as globals;
  array entries are Flutter positional parameters only.
- Reactive components and store: only the components that read a changed
  value render again. Handler ids are stable across renders.
- Builders (`ListView.builder { itemBuilder = ... }`) run when Flutter needs
  an item; each output is a component instance released on dispose.
- Teal declarations with a record of arguments per widget.
- Dart functions for Lua: `LuaWidgetLibrary.functions`, called with
  `ui.invoke` or the wrappers of `ui.functions`. Event handlers and methods
  run as coroutines and wait for a `Future` result. `coreLibrary` has
  `Navigator.pushNamed`, `pushReplacementNamed`, `pop`, `maybePop` and
  `canPop`.
