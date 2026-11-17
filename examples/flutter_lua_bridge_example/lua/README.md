# Lua sources

| Directory | Content |
| --- | --- |
| `src/` | Editable Teal (`.tl`) and Lua (`.lua`) modules |
| `types/` | Generated `<contract>_bridge.d.tl` declarations; do not edit |
| `test/` | Entries that run the Lua side without the app |

`dart run build_runner build`, run from the package root, type checks and
compiles `src/*.tl` and copies `src/*.lua` into `../assets/lua/`, which Flutter
packages as assets. A module reaches its contract with
`require("<contract>_bridge")`, for example `require("battle_bridge")`.

The compiler is the `tl.lua` bundled in `flutter_lua_bridge_codegen`.
`../tlconfig.lua` lets editor tooling such as the Teal language server find
`src/`, `types/` and `test/`; the build does not read it. It sits in the
package root because the language server only reads the opened folder.

## Running the Lua side alone

From the package root (`examples/flutter_lua_bridge_example`):

```sh
dart run flutter_lua_bridge_codegen:run                         # every entry in lua/test
dart run flutter_lua_bridge_codegen:run lua/test/cards_test.tl  # one entry
dart run flutter_lua_bridge_codegen:run lua/test/main.tl -- mage_001  # with arguments
dart run flutter_lua_bridge_codegen:run --watch                 # again on every change
```

Each entry (`main.tl|lua`, `*_test.tl|lua`) runs in a fresh Lua state and
passes when it returns without an error; use `assert`. Teal is type checked as
in the build. Outside the app the generated `<contract>_bridge` glue is not
loaded, so the runner stubs it: `bindXxx(t)` returns `t`, so the functions are
called directly without the safety-level checks, and `getXxx()` returns a
table the entry fills with stand-ins for the Dart functions
([`test/dart_host_test.lua`](test/dart_host_test.lua)). The bridge itself is
tested by the Dart tests in `../test/`.

| Entry | Shows |
| --- | --- |
| [`test/main.tl`](test/main.tl) | A scratch entry with arguments |
| [`test/formulas_test.tl`](test/formulas_test.tl) | Pure functions |
| [`test/cards_test.tl`](test/cards_test.tl) | A module bound with `bindCardApi` |
| [`test/dart_host_test.lua`](test/dart_host_test.lua) | Stand-ins for a `@DartApi` |
