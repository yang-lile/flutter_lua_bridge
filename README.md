# flutter_lua_bridge

A typed, synchronous Dart/Lua bridge for Flutter. Describe an API in Dart,
implement it in Teal or Lua, and call it in both directions through generated
code. Lua 5.3, 5.4 and 5.5 are bundled and compiled from source; no Lua
toolchain is installed, and only Lua is shipped with the app.

| Package | Content |
| --- | --- |
| [`flutter_lua_bridge`](packages/flutter_lua_bridge) | The runtime: `LuaRuntime`, codecs and the Lua build hook |
| [`flutter_lua_bridge_codegen`](packages/flutter_lua_bridge_codegen) | `build_runner` builders: Dart clients, Teal declarations, Teal compiler |
| [`flutter_lua_bridge_codegen_annotation`](packages/flutter_lua_bridge_codegen_annotation) | Contract annotations, re-exported by the runtime |
| [`flutter_lua_bridge_ui`](packages/flutter_lua_bridge_ui) | Widget trees from Lua: `LuaView`, reactive components, widget registries |

## Quick start

The full walkthrough, with what each step does and why, is
[Getting started](docs/getting-started.md). In short (Flutter 3.50 or later):

1. **Add the packages.** The runtime ships with the app; the generator only
   runs at development time.

   ```sh
   flutter pub add flutter_lua_bridge
   flutter pub add dev:build_runner dev:flutter_lua_bridge_codegen
   ```

2. **Scaffold.** `init` creates `lib/bridge/`, `lua/src/`, `lua/test/`,
   `assets/lua/`, a `build.yaml` that lets `build_runner` read `lua/`, and a
   `tlconfig.lua` for the Teal editor support. Then list the compiled Lua as
   an asset, so it ships with the app.

   ```sh
   dart run flutter_lua_bridge_codegen:init
   ```

   ```yaml
   # pubspec.yaml
   flutter:
     assets:
       - assets/lua/
   ```

3. **Describe the API in Dart.** The contract is the single source of both
   sides: `@LuaApi` is implemented in Lua and called from Dart, `@DartApi`
   the other way round.

   ```dart
   // lib/bridge/battle.dart
   import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

   part 'battle.g.dart';

   @LuaApi(module: 'battle')
   abstract class BattleApi {
     int damage(int attack, int defense);
   }
   ```

4. **Generate.** This writes `battle.g.dart` (the typed client) and
   `lua/types/battle_bridge.d.tl` (the Teal types of the contract). Keep
   `dart run build_runner watch` running while you work.

   ```sh
   dart run build_runner build
   ```

5. **Implement it in Teal** (or plain Lua). The build type-checks it
   against the contract and compiles it to `assets/lua/battle.lua`; a type
   error fails the build with its line and column. The module must return
   `bindBattleApi(...)`, which checks that every method is present.

   ```lua
   -- lua/src/battle.tl
   local bridge = require("battle_bridge")
   return bridge.bindBattleApi({
     damage = function(attack: integer, defense: integer): integer
       return math.max(0, attack - defense)
     end,
   })
   ```

6. **Test the Lua side** without the app: `dart run
   flutter_lua_bridge_codegen:run` runs every `lua/test/*_test.tl`.

7. **Call it from Dart.** Every call is synchronous and, at the default
   safety level, returns `LuaSuccess` or `LuaFailure` instead of throwing.

   ```dart
   final lua = LuaRuntime.create(); // sandboxed: no io, os or debug
   try {
     final battle = BattleApiClient.load(
       runtime: lua,
       source: await rootBundle.loadString('assets/lua/battle.lua'),
     );
     if (battle.damage(12, 5) case LuaSuccess(:final value)) print(value); // 7
   } finally {
     lua.close();
   }
   ```

8. **Run** with `flutter run`. A build hook compiles Lua 5.4 for the target
   platform; only the Lua in `assets/lua/` is shipped.

The Lua source can also come from a server, to change business logic
without an app release. A delivered script must implement the same contract
the app was built with; [Loading Lua at runtime](docs/dynamic-lua.md) lists
the conditions and a safe way to swap scripts.

| You write | The builder generates (never edit) |
| --- | --- |
| `lib/bridge/battle.dart`: the contract | `lib/bridge/battle.g.dart`: client, host registration, codecs |
| `lua/src/battle.tl` (or `.lua`): the implementation | `lua/types/battle_bridge.d.tl`: Teal declarations |
| Dart classes implementing `@DartApi` interfaces | `assets/lua/battle.lua`: the compiled Lua that ships |
| `lua/test/*_test.tl`: Lua-side tests | |

## Using it with an AI assistant

[`skills/flutter-lua-bridge/SKILL.md`](skills/flutter-lua-bridge/SKILL.md)
teaches an AI coding assistant to integrate and use this library: what to
write, what to regenerate, and the contract rules. For Claude Code, copy the
directory into your project:

```sh
mkdir -p .claude/skills
curl -L https://github.com/yang-lile/flutter_lua_bridge/archive/refs/heads/main.tar.gz \
  | tar -xz -C .claude --strip-components=1 flutter_lua_bridge-main/skills/flutter-lua-bridge
```

Other assistants can read the same file as instructions.

## Examples

- [`examples/flutter_lua_bridge_example`](examples/flutter_lua_bridge_example):
  a card battle game with every safety level, Lua-side tests and a benchmark.
- [`examples/lua_canvas_host`](examples/lua_canvas_host): Lua output turned
  into `rfw` remote widgets and canvas drawings, editable live.

## Documentation

| Document | Content |
| --- | --- |
| [`docs/getting-started.md`](docs/getting-started.md) | Step by step: what each step does and why |
| [`docs/dynamic-lua.md`](docs/dynamic-lua.md) | Loading Lua at runtime: conditions, versioning, a safe swap |
| [`docs/codegen-guide.md`](docs/codegen-guide.md) | Generator reference: contract rules, options, the `run` command |
| [`docs/lua-source.md`](docs/lua-source.md) | Choosing the Lua release or source |
| [`docs/codegen-design.md`](docs/codegen-design.md) | Design of the generator (Chinese) |
| [`docs/development.md`](docs/development.md) | Checks, CI, VS Code and publishing for contributors |
| [`docs/testing-matrix.md`](docs/testing-matrix.md) | What each test tier covers |
