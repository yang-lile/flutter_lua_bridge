# Flutter example

`lib/bridge/basic_api.dart`, `lib/bridge/battle.dart` and
`lib/bridge/scenarios.dart` are application contracts. Their Dart part files,
Teal declarations and compiled Lua are generated with:

```sh
dart run build_runner build
```

| Path | Content |
| --- | --- |
| `lib/bridge/*.g.dart` | Generated clients, host registration and codecs |
| `lua/types/*_bridge.d.tl` | Generated Teal declarations |
| `lua/src/` | Editable Teal and Lua, for example [`lua/src/basic.tl`](lua/src/basic.tl) |
| `assets/lua/` | Compiled Teal and copied Lua, packaged as Flutter assets |

`BasicBridgeDemo` loads `assets/lua/basic.lua` through `BasicApiClient.load`.
The Teal compiler is bundled in the generator; no Lua toolchain is installed
and nothing is compiled on the device. Generated files carry a `Do not edit`
header.

`test/scenarios` covers four typed bridge strategies: handwritten Lua, Teal
compiled to Lua, dynamic Lua and Lua calling registered Dart functions.

## Card battle game

The game is the example of a larger contract, `lib/bridge/battle.dart`:

| Lua module | Contract | Content |
| --- | --- | --- |
| `lua/src/cards.tl` | `CardApi` | The card catalog (`CardSpec` with enums, nested data and nullable fields), passives and skill effects |
| `lua/src/formulas.tl` | — | Damage, heal and action order, as pure functions |
| `lua/src/formulas_o1.tl`, `_o2`, `_o3` | `FormulasO1Api`, `O2Api`, `O3Api` | The same formulas bound at each safety level |
| `lua/src/formulas_faulty.lua` | — | A buggy replacement for `formulas.lua`, for the comparison page |

The three formula APIs implement one plain interface, `BattleFormulas`,
declared once in the contract. `lib/game/formulas.dart` adapts the O1/O2
clients (which return `LuaCallResult<T>`) to it, the O3 client implements it
directly, and `DartFormulas` mirrors the Lua formulas in Dart. The battle
(`lib/game/battle_simulator.dart`) only depends on `BattleFormulas`; random
numbers are drawn in Dart and passed in, so a seed replays the same battle
with every backend, which `test/game/battle_simulator_test.dart` checks.

On the game page a switch selects Dart, O1, O2 or O3 for the battles, which
can be animated or simulated instantly with their run time. The safety level
page calls every formula once per level, with the correct or the faulty
script, and runs a benchmark of every backend in a background isolate.

在 macOS 上可用下面的脚本构建。它会先生成 Flutter 配置并安装 CocoaPods，
然后依次构建 Pods 和 Runner，避开 Xcode 27 对 Flutter workspace 的兼容问题：

```sh
bash tools/build_macos.sh debug
```
