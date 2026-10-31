# Flutter example

`bridge/basic_api.dart` and `bridge/battle.dart` are application contracts.
Generate their Dart proxies, Lua companions and Teal declarations with:

```sh
dart run flutter_lua_bridge_codegen --input bridge/basic_api.dart
```

The editable Teal implementation is [`lua/src/basic.tl`](lua/src/basic.tl).
Build it with Cyan from the Lua project directory:

```sh
cd lua
cyan build
```

The resulting `lua/build/basic.lua` is packaged as a Flutter asset and loaded
by `BasicBridgeDemo`; Teal and Cyan are not needed on the device. Generated
files carry a `Do not edit` header.

The game demo continues to exercise the raw API, while `test/scenarios` covers
four typed bridge strategies: handwritten Lua, Teal compiled to Lua, dynamic
Lua and Lua calling registered Dart functions.

在 macOS 上可用下面的脚本构建。它会先生成 Flutter 配置并安装 CocoaPods，
然后依次构建 Pods 和 Runner，避开 Xcode 27 对 Flutter workspace 的兼容问题：

```sh
bash tools/build_macos.sh debug
```
