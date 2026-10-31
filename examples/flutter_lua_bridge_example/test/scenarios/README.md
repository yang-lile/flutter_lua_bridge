# Four bridge scenarios

Each test uses the generated contract in `bridge/scenarios.dart` and a
different Lua implementation:

| Test | Source | What it demonstrates |
| --- | --- | --- |
| `pure_lua_test.dart` | `assets/scenarios/pure_lua.lua` | Dart calls handwritten Lua |
| `pure_teal_test.dart` | `lua/src/pure_teal.tl` → `lua/build/pure_teal.lua` | Teal checks and compiles a module |
| `dynamic_lua_test.dart` | `assets/scenarios/dynamic_lua.lua` | Lua selects a runtime formula |
| `dart_host_test.dart` | `assets/scenarios/dart_host.lua` | Lua calls registered Dart functions |

Run them with `flutter test test/scenarios`. The bridge companion and `.d.tl`
declaration are generated from the Dart contract; business files remain the
editable source.
