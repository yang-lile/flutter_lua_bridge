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

## Quick start

```yaml
dependencies:
  flutter_lua_bridge: ^0.1.0
dev_dependencies:
  build_runner: ^2.10.0
  flutter_lua_bridge_codegen: ^0.1.0
```

```dart
// lib/bridge/battle.dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'battle.g.dart';

@LuaApi(module: 'battle')
abstract class BattleApi {
  int damage(int attack, int defense);
}
```

```lua
-- lua/src/battle.tl
local bridge = require("battle_bridge")
return bridge.bindBattleApi({
  damage = function(attack: integer, defense: integer): integer
    return math.max(0, attack - defense)
  end,
})
```

```sh
dart run flutter_lua_bridge_codegen:init
dart run build_runner build
```

```dart
final lua = LuaRuntime.create();
final battle = BattleApiClient.load(
  runtime: lua,
  source: await rootBundle.loadString('assets/lua/battle.lua'),
);
if (battle.damage(12, 5) case LuaSuccess(:final value)) print(value); // 7
```

| You write | The builder generates (never edit) |
| --- | --- |
| `lib/bridge/battle.dart`: the contract | `lib/bridge/battle.g.dart`: client, host registration, codecs |
| `lua/src/battle.tl` (or `.lua`): the implementation | `lua/types/battle_bridge.d.tl`: Teal declarations |
| Dart classes implementing `@DartApi` interfaces | `assets/lua/battle.lua`: the compiled Lua that ships |
| `lua/test/*_test.tl`: Lua-side tests | |

`init` writes `build.yaml` and `tlconfig.lua` once; after that they are
yours. The [code generator README](packages/flutter_lua_bridge_codegen)
explains the layout, Dart APIs called from Lua and the safety levels.

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
| [`docs/codegen-guide.md`](docs/codegen-guide.md) | Generator reference: contract rules, options, the `run` command |
| [`docs/lua-source.md`](docs/lua-source.md) | Choosing the Lua release or source |
| [`docs/codegen-design.md`](docs/codegen-design.md) | Design of the generator (Chinese) |
| [`docs/development.md`](docs/development.md) | Checks, CI, VS Code and publishing for contributors |
| [`docs/testing-matrix.md`](docs/testing-matrix.md) | What each test tier covers |
