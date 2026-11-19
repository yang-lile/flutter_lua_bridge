# flutter_lua_bridge

`flutter_lua_bridge` is a typed, synchronous Dart/Lua bridge for Flutter. It
bundles Lua 5.3, 5.4 and 5.5. The repository is a Dart workspace with three
packages:

| Package | Responsibility |
| --- | --- |
| [`flutter_lua_bridge`](packages/flutter_lua_bridge) | Lua runtime (`LuaRuntime`), codecs and native assets |
| [`flutter_lua_bridge_codegen_annotation`](packages/flutter_lua_bridge_codegen_annotation) | Dependency free contract annotations, re-exported by the runtime |
| [`flutter_lua_bridge_codegen`](packages/flutter_lua_bridge_codegen) | `build_runner` builders: Dart clients, Teal declarations and the Teal compiler |

Applications depend on the runtime, and add the generator and `build_runner`
as development dependencies. The runtime does not depend on the generator.

The design of the code generator is described in
[`docs/codegen-design.md`](docs/codegen-design.md); the package
responsibilities and test tiers are listed in
[`docs/testing-matrix.md`](docs/testing-matrix.md).

## Contracts and generated code

A contract is a plain Dart library under `lib/bridge/`. Interfaces and data
classes are written by hand; the generator adds a part file next to them:

```dart
// lib/bridge/battle.dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'battle.g.dart';

class Fighter {
  const Fighter({required this.attack, required this.defense});
  final int attack;
  final int defense;
}

/// Implemented in Lua or Teal, called from Dart.
@LuaApi(module: 'battle')
abstract class BattleApi {
  @LuaName('calculate_damage')
  int calculateDamage(Fighter attacker, Fighter defender);
}

/// Implemented in Dart, called from Lua (callbacks and host services).
@DartApi(module: 'host')
abstract class HostApi {
  void log(String message);
}
```

One command generates everything:

```sh
dart run build_runner build      # or: dart run build_runner watch
```

| Input | Output | Content |
| --- | --- | --- |
| `lib/bridge/battle.dart` | `lib/bridge/battle.g.dart` | `BattleApiClient`, `registerHostApi` and the codecs |
| `lib/bridge/battle.dart` | `lua/types/battle_bridge.d.tl` | Teal declarations of `require("battle_bridge")` |
| `lua/src/*.tl` | `assets/lua/*.lua` | Type checked and compiled Teal |
| `lua/src/*.lua` | `assets/lua/*.lua` | Handwritten Lua, copied |

The implementation is an editable Teal (or Lua) module:

```lua
-- lua/src/battle.tl
local bridge = require("battle_bridge")
local host = bridge.getHostApi()

local implementation: bridge.BattleApi = {
  calculate_damage = function(attacker: bridge.Fighter, defender: bridge.Fighter): integer
    host.log("attack")
    return math.max(0, attacker.attack - defender.defense)
  end,
}
return bridge.bindBattleApi(implementation)
```

and the application calls it through the generated client:

```dart
final lua = LuaRuntime.create();
registerHostApi(MyHost(), runtime: lua);
final battle = BattleApiClient.load(
  runtime: lua,
  source: await rootBundle.loadString('assets/lua/battle.lua'),
);
final result = battle.calculateDamage(attacker, defender); // LuaCallResult<int>
```

Teal is compiled by the `tl.lua` compiler bundled in the generator package,
running on the bundled Lua runtime. No LuaRocks, Cyan or system Lua is
involved, and the device never needs a Teal compiler: only the Lua files under
`assets/lua/` are shipped. A new package is prepared with
`dart run flutter_lua_bridge_codegen:init`.

Generated calls have three safety levels. `O1` is the default: generated Lua
validates argument and result types and wraps the call in `pcall`, and the
client returns `LuaCallResult<T>` (`LuaSuccess` or `LuaFailure`). `O2` keeps
`pcall` and the result envelope but omits the validators. `O3` is the direct
path: the client implements the contract interface, returns `T` and throws
`LuaBridgeException`. The default level is the `optimization` option in
`build.yaml`; `@LuaApi(module: 'battle', optimization: LuaOptimization.o3)`
overrides it for one interface.

## Running in VS Code

Open the repository root. `.vscode/launch.json` (Run and Debug, F5) has:

| Configuration | What it starts |
| --- | --- |
| Example app | `examples/flutter_lua_bridge_example` on the device picked in the status bar, after regenerating its Lua with `tool/generate_example.sh` |
| Example app (profile, for the benchmark) | The same in profile mode, for meaningful numbers on the safety level page |
| Lua Canvas Studio (macOS) | `examples/lua_canvas_host`, after syncing its asset list from `assets/lua/manifest.txt` |
| Lua Canvas Studio (macOS, flutter_driver) | The same with `lib/driver_main.dart` |
| Lua: run current file | The open `.tl`/`.lua` entry without an app |

`.vscode/settings.json` points the Dart extension at fvm's global Flutter
(`~/fvm/default`); change it if your SDK lives elsewhere. If the debugger
cannot attach to Lua Canvas Studio, the task "canvas: build and open
(tools/dev.sh)" builds it with Xcode and opens it. The other tasks
(Terminal > Run Task) run the Lua entries; see
[`examples/flutter_lua_bridge_example/lua/README.md`](examples/flutter_lua_bridge_example/lua/README.md).

## Development checks

```sh
dart pub get
dart analyze --fatal-infos
dart test --no-test-randomize-ordering-seed
python3 packages/flutter_lua_bridge/tool/test_native.py
```

The native hook builds the bundled Lua 5.4 source by default for the target platform.
Lua 5.3.6, 5.4.9 and 5.5.0 are bundled under
`packages/flutter_lua_bridge/third_party/`.
The four scenario tests in `examples/flutter_lua_bridge_example/test/scenarios` cover Lua-first, Teal-first,
dynamic Lua and Dart-host implementations.

The Lua source tree can be overridden by the consuming application's workspace
`pubspec.yaml`:

```yaml
hooks:
  user_defines:
    flutter_lua_bridge:
      # Pick one of the bundled release lines (5.3, 5.4 or 5.5):
      lua_version: "5.5"
      # Or a local Lua source tree:
      # lua_source: third_party/lua-5.4
      # Or an immutable archive URL:
      # lua_source: https://example.com/lua-5.5.tar.gz
      # lua_version: 5.5.0
      # Optional: lua_sha256: <64-character SHA-256 digest>
```

The hook keeps a fixed Lua library source manifest, validates
the required headers and sources, and compiles the selected tree together with the
`flb_*` shim (`native/flb.h`), the only native interface of the package; it is
the same for every supported Lua release. URL sources require a fixed version label and may
optionally verify the archive with SHA-256. Without a digest, the URL and
version label are used as the cache key. Lua version-specific API differences are handled inside
`native/flb.c`; the hook does not impose a Lua version.
Without any setting the hook builds the bundled Lua 5.4 release. These
settings are only read from the workspace root `pubspec.yaml`.

The daily pull request gate is available locally as `./tool/ci_light.sh`. It
runs the analyzer, the builders with a drift check on every generated file,
the code generator tests and a small example unit test. The full
`./tool/ci.sh` gate is reserved for the release workflow and adds the native
bridge tests, every bundled Lua release and the Flutter integration checks.
Both scripts honour `DART_CMD` and `FLUTTER_CMD` (for example
`DART_CMD="fvm dart"`).
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
