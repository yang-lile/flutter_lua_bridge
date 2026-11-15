# Lua sources

| Directory | Content |
| --- | --- |
| `src/` | Editable Teal (`.tl`) and Lua (`.lua`) modules |
| `types/` | Generated `<contract>_bridge.d.tl` declarations; do not edit |

`dart run build_runner build`, run from the package root, type checks and
compiles `src/*.tl` and copies `src/*.lua` into `../assets/lua/`, which Flutter
packages as assets. A module reaches its contract with
`require("<contract>_bridge")`, for example `require("battle_bridge")`.

The compiler is the `tl.lua` bundled in `flutter_lua_bridge_codegen`.
`tlconfig.lua` exists only so that editor tooling such as the Teal language
server finds `src/` and `types/`; the build does not read it.
