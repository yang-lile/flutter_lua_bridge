# flutter_lua_bridge_codegen

`build_runner` builders for
[`flutter_lua_bridge`](https://pub.dev/packages/flutter_lua_bridge): describe
an API in Dart, implement it in Teal or Lua, and call it with generated, typed
code in both directions. Teal is compiled by a bundled compiler; no Lua
toolchain is installed and only Lua is shipped.

```yaml
dependencies:
  flutter_lua_bridge: ^0.1.0
dev_dependencies:
  build_runner: ^2.10.0
  flutter_lua_bridge_codegen: ^0.1.0
```

```sh
dart run flutter_lua_bridge_codegen:init      # once: directories, build.yaml, tlconfig.lua
dart run build_runner build                   # or: watch
dart run flutter_lua_bridge_codegen:run       # run lua/test without the app
```

## How it works

1. Write a contract under `lib/bridge/`:

   ```dart
   import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

   part 'battle.g.dart';

   class Fighter {
     const Fighter({required this.attack, required this.defense});
     final int attack;
     final int defense;
   }

   @LuaApi(module: 'battle')            // implemented in Lua, called from Dart
   abstract class BattleApi {
     int calculateDamage(Fighter attacker, Fighter defender);
   }

   @DartApi(module: 'host')             // implemented in Dart, called from Lua
   abstract class HostApi {
     void log(String message);
   }
   ```

2. Implement it in `lua/src/battle.tl`, type checked against the generated
   declarations:

   ```lua
   local bridge = require("battle_bridge")
   local host = bridge.getHostApi()

   local implementation: bridge.BattleApi = {
     calculateDamage = function(attacker: bridge.Fighter, defender: bridge.Fighter): integer
       host.log("attack")
       return math.max(0, attacker.attack - defender.defense)
     end,
   }
   return bridge.bindBattleApi(implementation)
   ```

3. Call it from Dart:

   ```dart
   final lua = LuaRuntime.create();
   registerHostApi(MyHost(), runtime: lua);
   final battle = BattleApiClient.load(
     runtime: lua,
     source: await rootBundle.loadString('assets/lua/battle.lua'),
   );
   final damage = battle.calculateDamage(attacker, defender); // LuaCallResult<int>
   ```

## What you write and what is generated

```text
my_app/
├── pubspec.yaml                  you      add `assets/lua/` under flutter: assets:
├── build.yaml                    init     then yours; adds lua/** to the build
├── tlconfig.lua                  init     then yours; for the editor and `run`
├── lib/
│   ├── bridge/
│   │   ├── battle.dart           you      the contract
│   │   └── battle.g.dart         builder  BattleApiClient, registerHostApi, codecs
│   └── ...                       you      app code, and the Dart class implementing HostApi
├── lua/
│   ├── src/battle.tl             you      the implementation (.tl or .lua)
│   ├── test/main.tl, *_test.tl   you      Lua-side tests (init writes main.tl)
│   └── types/battle_bridge.d.tl  builder  what require("battle_bridge") returns
└── assets/lua/battle.lua         builder  compiled Lua, the only Lua shipped
```

- **You write** the contract, the Lua/Teal implementation of every `@LuaApi`
  interface, a Dart class implementing every `@DartApi` interface, and the
  Lua-side tests.
- **The builder writes** `*.g.dart`, `lua/types/` and `assets/lua/`. Never
  edit them: a contract change regenerates the first two, a change under
  `lua/src` regenerates `assets/lua`. Keep `build_runner watch` running while
  you work, and commit the generated files like any `*.g.dart`, so the app
  builds without running the generator first.
- **Not a file**: the `<name>_bridge` Lua module (`bindBattleApi`,
  `getHostApi`) is embedded in `battle.g.dart` and loaded into the runtime
  by the client; only its declarations exist under `lua/types/`.

Supported types are `bool`, `int`, `double`, `String`, enums, your own data
classes, `List<T>`, `Map<String, T>` and their nullable forms.

## Safety levels

| Level | Lua type checks | `pcall` | Dart result |
| --- | --- | --- | --- |
| `O1` (default) | yes | yes | `LuaCallResult<T>` (`LuaSuccess` / `LuaFailure`) |
| `O2` | no | yes | `LuaCallResult<T>` |
| `O3` | no | no | `T`, throws `LuaBridgeException` |

Set the default with `optimization` in `build.yaml`, or per interface with
`@LuaApi(module: 'battle', optimization: LuaOptimization.o3)`.

## More

- [Code generator reference](https://github.com/yang-lile/flutter_lua_bridge/blob/main/docs/codegen-guide.md):
  generated API, contract rules, interface inheritance, `build.yaml` options,
  `tlconfig.lua`, the `run` command and the bundled Teal compiler.
- [Example app](https://github.com/yang-lile/flutter_lua_bridge/tree/main/examples/flutter_lua_bridge_example):
  a card battle game with every safety level and a benchmark.
