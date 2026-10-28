# flutter_lua_bridge

`flutter_lua_bridge` is a typed, synchronous Dart/Lua 5.4 bridge for Flutter.
The repository is a Dart workspace with three packages:

| Package | Responsibility |
| --- | --- |
| [`flutter_lua_bridge`](packages/flutter_lua_bridge) | Lua runtime, codecs, native assets and the low level migration API |
| [`flutter_lua_bridge_codegen_annotation`](packages/flutter_lua_bridge_codegen_annotation) | Small, dependency free contract annotations |
| [`flutter_lua_bridge_codegen`](packages/flutter_lua_bridge_codegen) | Dart AST validation and Dart/Lua/Teal artifact generation |

The runtime package does not depend on the generator. Applications depend on
the runtime at run time, and keep the annotation and generator packages in
their development toolchain.

## Contract and generated artifacts

An application contract imports the annotation package:

```dart
import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

@ConfigureLuaBridge(
  dartOut: 'lib/bridge/basic_api.g.dart',
  luaOut: 'lua/src/basic_bridge.lua',
  tealOut: 'lua/src/basic_bridge.d.tl',
)
@LuaApi(module: 'basic')
abstract class BasicApi {
  RandomResult run();
}
```

The generator emits a Dart proxy, a Lua protocol companion and a Teal
declaration file from the same contract:

```sh
./tool/generate_example.sh
```

The generated Lua companion contains protocol validation/error handling and
the contract fingerprint. Business logic lives in an editable `.tl` file. The example keeps
that project in [`example/lua`](example/lua): Cyan checks every Teal source and
writes Lua 5.4 modules into `example/lua/build`.

Generated calls use GCC-style safety levels. `O1` is the default and emits Lua
type validators plus `pcall`, returning `LuaCallResult<T>` with
`LuaResultStatus.ok` or `LuaResultStatus.error`. `O2` keeps the `pcall` result
fallback but omits Lua validators. `O3` emits the original direct call path;
uncaught Lua failures propagate as `LuaBridgeException`.

Select a level on the command line or in `@ConfigureLuaBridge`:

```sh
dart run flutter_lua_bridge_codegen --input bridge/basic_api.dart -O1
```

```sh
cd example/lua
cyan build
```

Flutter packages the compiled Lua files as assets. Generated Dart code embeds
the companion source and loads the compiled module through `LuaRuntime`, so the
application does not need a separate Lua interpreter or a Teal compiler at
runtime.

## Development checks

```sh
dart pub get
dart analyze --fatal-infos
dart test --no-test-randomize-ordering-seed
python3 packages/flutter_lua_bridge/tool/test_native.py
```

The native hook builds the bundled Lua 5.4 source for the target platform.
The four scenario tests in `example/test/scenarios` cover Lua-first, Teal-first,
dynamic Lua and Dart-host implementations.

## Local playground

For a disposable end-to-end test, generate the ignored `playground/` directory:

```sh
./tool/create_playground.sh
dart run playground/bin/demo.dart
```

It creates a small O1 contract, its Teal implementation, generated bridge code
and a Dart runner. The expected output is `O1 success: 42`; the generated files
are intentionally excluded from Git.
