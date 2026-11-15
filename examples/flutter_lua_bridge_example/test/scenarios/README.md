# Four bridge scenarios

Each test uses the generated contract in `lib/bridge/scenarios.dart` and a
different Lua implementation:

| Test | Source | What it demonstrates |
| --- | --- | --- |
| `pure_lua_test.dart` | `lua/src/pure_lua.lua` | Dart calls handwritten Lua |
| `pure_teal_test.dart` | `lua/src/pure_teal.tl` | Teal is checked and compiled to Lua |
| `dynamic_lua_test.dart` | `lua/src/dynamic_lua.lua` | Lua selects a runtime formula |
| `dart_host_test.dart` | `lua/src/dart_host.lua` | Lua calls registered Dart functions |

The tests read the built modules from `assets/lua/`. Run them with
`flutter test test/scenarios`; after changing a source, run
`dart run build_runner build` first.
