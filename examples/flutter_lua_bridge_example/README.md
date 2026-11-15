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

The game demo exercises `LuaRuntime` directly, while `test/scenarios` covers
four typed bridge strategies: handwritten Lua, Teal compiled to Lua, dynamic
Lua and Lua calling registered Dart functions.

在 macOS 上可用下面的脚本构建。它会先生成 Flutter 配置并安装 CocoaPods，
然后依次构建 Pods 和 Runner，避开 Xcode 27 对 Flutter workspace 的兼容问题：

```sh
bash tools/build_macos.sh debug
```
