## 0.2.0

- Require Dart 3.14 (Flutter 3.50), `analyzer` 14.7, `build` 5 and
  `source_gen` 4.3.
- `dart run build_runner build` no longer needs `--force-jit`.

## 0.1.1

- Support `analyzer` 8.4 to 14 and `build` 4 or 5. The reader no longer uses
  the `isSynthetic` getters that analyzer 10 deprecates and 14 removes.

## 0.1.0

- Initial release.
- `build_runner` builders for `flutter_lua_bridge` contracts: `bridge`
  generates the Dart part file (clients, host registration, codecs and the
  embedded Lua glue), `teal_types` the Teal declarations
  (`lua/types/<name>_bridge.d.tl`), and `teal` compiles `lua/src` to
  `assets/lua` (Teal compiled, Lua copied).
- Teal 0.24.8 is bundled (`lib/src/teal/tl.lua`) and runs on
  `flutter_lua_bridge`'s own Lua runtime; no Lua toolchain is installed.
- Safety levels `O1` (validators and `pcall`, `LuaCallResult<T>`), `O2`
  (`pcall` only) and `O3` (direct calls, `LuaBridgeException`), set in
  `build.yaml` or per interface.
- Contract interfaces may implement plain abstract interfaces, so one set of
  methods can be bound at several safety levels.
- `dart run flutter_lua_bridge_codegen:init` scaffolds the directories,
  `build.yaml`, `tlconfig.lua` and `lua/test/main.tl`.
- `dart run flutter_lua_bridge_codegen:run` runs Lua and Teal entries
  (`main.tl`, `*_test.tl`) without the app, with `--watch`.
