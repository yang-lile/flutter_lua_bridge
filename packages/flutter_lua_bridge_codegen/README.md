# flutter_lua_bridge_codegen

`build_runner` builders for `flutter_lua_bridge` contracts. A contract is a
Dart library with `@LuaApi` and `@DartApi` interfaces; the builders generate
the code on both sides of the bridge and compile the Teal implementation.

```yaml
dependencies:
  flutter_lua_bridge: ^0.1.0
dev_dependencies:
  build_runner: ^2.10.0
  flutter_lua_bridge_codegen: ^0.1.0
```

```sh
dart run flutter_lua_bridge_codegen:init   # once: directories, build.yaml, tlconfig.lua
dart run build_runner build                # or: watch
dart run flutter_lua_bridge_codegen:run    # run lua/test without the app
```

Before Dart 3.12 (Flutter 3.38 ships Dart 3.10), add `--force-jit`:
`dart compile` there refuses packages whose dependencies have build hooks, and
`flutter_lua_bridge` has one, so build_runner cannot AOT-compile its build
script. The flag works on every SDK.

## Layout

| Path | Written by | Content |
| --- | --- | --- |
| `lib/bridge/<name>.dart` | you | The contract: interfaces, data classes, enums, and `part '<name>.g.dart';` |
| `lib/bridge/<name>.g.dart` | builder | `XxxClient`, `registerXxx`, codecs and the embedded Lua glue |
| `lua/types/<name>_bridge.d.tl` | builder | Teal declarations of `require("<name>_bridge")` |
| `lua/src/*.tl`, `lua/src/*.lua` | you | The implementation |
| `assets/lua/*.lua` | builder | Compiled Teal and copied Lua; list `assets/lua/` under `flutter: assets:` |
| `lua/test/main.tl`, `*_test.tl` | you (`init` writes `main.tl`) | Entries for [`run`](#running-the-lua-side) |
| `tlconfig.lua` | `init` | For the Teal language server and `run`; the build does not read it |
| `build.yaml` | `init` | Adds `lua/**` to the build sources |

`build_runner` only reads the directories listed under `sources` of the
default target, and `lua/` is not one of its defaults. That is what the
generated `build.yaml` is for.

`tlconfig.lua` sits in the package root, with paths relative to it: the Teal
language server (used by the VS Code extension) reads `tlconfig.lua` only
from the folder the editor opened and resolves `include_dir` against it. In a
`lua/` subdirectory it is never found, and every `require("<name>_bridge")`
is reported as missing. In a repository with several packages, open the
package folder, or add a root `tlconfig.lua` that points at one of them.

## Generated Dart

For `@LuaApi(module: 'battle') abstract class BattleApi` the part file contains
`BattleApiClient`:

- `BattleApiClient(runtime: lua)` binds a module that is already loaded.
- `BattleApiClient.load(runtime: lua, source: text)` loads the module first.
- At `O1` and `O2` every method returns `LuaCallResult<T>`. At `O3` the client
  `implements BattleApi`, returns `T` and throws `LuaBridgeException`.

For `@DartApi(module: 'host') abstract class HostApi` it contains
`registerHostApi(HostApi? api, {required LuaRuntime runtime})`; pass `null` to
unregister. Lua obtains the implementation with `bridge.getHostApi()`.

An API may implement plain abstract interfaces and inherits their methods.
This declares an interface once and binds it at several safety levels:

```dart
abstract interface class BattleFormulas {
  Damage physicalDamage(Fighter attacker, Fighter defender, double multiplier, Roll roll);
}

@LuaApi(module: 'formulas_o1', optimization: LuaOptimization.o1)
abstract class FormulasO1Api implements BattleFormulas {}

@LuaApi(module: 'formulas_o3', optimization: LuaOptimization.o3)
abstract class FormulasO3Api implements BattleFormulas {}
```

The O3 client then also implements `BattleFormulas`. Interfaces must be
abstract, without type arguments, annotations or members other than abstract
instance methods; `extends` and mixins are rejected.

Binding wraps the functions of the Lua table in place, so a table can be bound
to one API only. Binding it again to an API of another level fails with
"already bound as ..."; give each binding its own table, for example
`bridge.bindFormulasO1Api({ physicalDamage = formulas.physicalDamage })`.

Data classes are your own classes: one unnamed constructor whose required
parameters each initialise a final field of the same name. Supported types are
`bool`, `int`, `double`, `String`, simple enums, data classes, `List<T>`,
`Map<String, T>` and their nullable forms. Unsupported contracts fail the
build with a message that points at the declaration.

## Safety levels

| Level | Lua validators | `pcall` | Dart result |
| --- | --- | --- | --- |
| `O1` (default) | yes | yes | `LuaCallResult<T>` |
| `O2` | no | yes | `LuaCallResult<T>` |
| `O3` | no | no | `T`, throws `LuaBridgeException` |

The default is set for a package in `build.yaml` and can be overridden for one
interface with `@LuaApi(optimization: LuaOptimization.o3)`.

## Options

```yaml
targets:
  $default:
    builders:
      flutter_lua_bridge_codegen:bridge:
        options: &flb
          contracts: lib/bridge
          types: lua/types
          sources: lua/src
          output: assets/lua
          optimization: O1
      flutter_lua_bridge_codegen:teal_types:
        options: *flb
      flutter_lua_bridge_codegen:teal:
        options: *flb
```

All three builders take the same options, so give them the same values.

## Running the Lua side

`run` executes hand-written entry files on `LuaRuntime`, without the app and
without a system Lua. Use it for quick tests of Lua and Teal logic:

```sh
dart run flutter_lua_bridge_codegen:run                        # all entries under lua/test
dart run flutter_lua_bridge_codegen:run lua/test/cards_test.tl # one file
dart run flutter_lua_bridge_codegen:run lua/sandbox            # another directory
dart run flutter_lua_bridge_codegen:run main.tl -- a b         # `...` is "a", "b"
dart run flutter_lua_bridge_codegen:run --watch                # rerun on .tl/.lua changes
```

- A directory target runs every `main.tl|lua` and `*_test.tl|lua` below it.
  Each entry gets a fresh Lua state and passes when it returns without an
  error; the exit code is 1 if any entry fails.
- `require()` searches the entry's own directory, then `include_dir` and
  `source_dir` of the nearest `tlconfig.lua` above it. Teal is type checked
  like in the build, and tracebacks point at the Teal lines.
- The generated `<contract>_bridge` glue lives in the `.g.dart` files, so a
  missing `*_bridge` module is stubbed: `bindXxx(t)` returns `t` unchanged
  (the safety-level checks do not run), and `getXxx()` returns a table the
  entry fills with stand-ins for the Dart functions. Calling one that is not
  assigned raises `<module>: Api.method is not stubbed`.

The same runner is available to Dart tests:

```dart
import 'package:flutter_lua_bridge_codegen/lua_runner.dart';

final result = await LuaRunner().run('lua/test/cards_test.tl');
expect(result.passed, isTrue, reason: result.error);
```

## Teal

`lib/src/teal/tl.lua` is the unmodified Teal 0.24.8 compiler (MIT, see
`lib/src/teal/LICENSE`). A build script cannot load native assets, so the Teal
builder starts one `teal_worker` process per build; the worker runs `tl.lua`
on the Lua release selected for the application and generates Lua for it
(`gen_target` 5.4 on Lua 5.4 and later, otherwise 5.3). `require` is resolved
among `lua/src` and `lua/types`. Type and syntax errors fail the build with
their file, line and column. LuaRocks, Cyan and a system Lua are not used.

Not implemented yet:

- Compiling Teal inside the running application. Only compiled Lua is shipped.
- Asynchronous (`Future`) host methods. Calls are synchronous in both
  directions.
