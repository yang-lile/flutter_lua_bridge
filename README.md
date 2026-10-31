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

The package responsibilities and test tiers are listed in
[`docs/testing-matrix.md`](docs/testing-matrix.md).

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
that project in [`examples/flutter_lua_bridge_example/lua`](examples/flutter_lua_bridge_example/lua): Cyan checks every Teal source and
writes Lua 5.4 modules into `examples/flutter_lua_bridge_example/lua/build`.

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
cd examples/flutter_lua_bridge_example/lua
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

The native hook builds the bundled Lua 5.4 source by default for the target platform.
The four scenario tests in `examples/flutter_lua_bridge_example/test/scenarios` cover Lua-first, Teal-first,
dynamic Lua and Dart-host implementations.

The Lua source tree can be overridden by the consuming application's workspace
`pubspec.yaml`:

```yaml
hooks:
  user_defines:
    flutter_lua_bridge:
      lua_source: third_party/lua-5.4
      # Or an immutable archive URL:
      # lua_source: https://example.com/lua-5.5.tar.gz
      # lua_version: 5.5.0
      # Optional: lua_sha256: <64-character SHA-256 digest>
```

The hook keeps a fixed Lua library source manifest, validates
the required headers and sources, and compiles the selected tree through the
stable `flb_*` bridge ABI. URL sources require a fixed version label and may
optionally verify the archive with SHA-256. Without a digest, the URL and
version label are used as the cache key. Lua version-specific API differences are handled by the C
bridge and the selected source tree; the hook does not impose a Lua version.
The default remains `packages/flutter_lua_bridge/lua_src`.

The daily pull request gate is available locally as `./tool/ci_light.sh`. It
runs the analyzer, code generator tests, generated contract checks and a small
example unit test. The full `./tool/ci.sh` gate is reserved for the release
workflow and adds Cyan, native bridge and Flutter integration checks.
`actionlint` can validate the workflow files themselves. Full workflow
emulation with `act` requires a Docker-compatible daemon.

If Podman is available, `tool/ci_podman.sh` wraps the `act` options needed to
run the workflow against the Podman machine:

```sh
./tool/ci_podman.sh dry-run       # parse the workflow and list its jobs
./tool/ci_podman.sh light         # run the daily lightweight workflow
./tool/ci_podman.sh release       # run the release integration workflow
```

The release workflow uses a temporary x64 Flutter configuration in the local
Podman wrapper because Flutter 3.38.10 does not publish a Linux arm64 archive.
On Apple Silicon, the native ASan test may still fail under amd64 emulation;
use `./tool/ci.sh` on the host or the GitHub release workflow for the
authoritative native check.

## rfw hot-update example

The workspace also includes [`examples/lua_canvas_host`](examples/lua_canvas_host),
a Flutter host that turns Lua output into an `rfw` remote widget library. It
uses the local `packages/flutter_lua_bridge` package and keeps the Lua, canvas,
widget-tree and interaction checks together:

```sh
cd examples/lua_canvas_host
make test
make run
```

## Local playground

For a disposable end-to-end test, generate the ignored `playground/` directory:

```sh
./tool/create_playground.sh
dart run playground/bin/demo.dart
```

It creates a small O1 contract, its Teal implementation, generated bridge code
and a Dart runner. The expected output is `O1 success: 42`; the generated files
are intentionally excluded from Git.
