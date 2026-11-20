# Code generator reference

Details of `flutter_lua_bridge_codegen` that the package README leaves out.
The design behind them is in [`codegen-design.md`](codegen-design.md).

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

## Contract rules

Data classes are your own classes: one unnamed constructor whose parameters
are all required (nullable ones too) and each initialise a final field of the
same name. Supported types are `bool`, `int`, `double`, `String`, simple
enums, data classes, `List<T>`, `Map<String, T>` and their nullable forms.
Unsupported contracts fail the build with a message that points at the
declaration.

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

## Asynchronous methods

A method may return `Future<T>` (or `Future<void>`) when a step takes time:
a network request, a database, a dialog. Lua is unaware of it; there are no
callbacks or `await` in Lua.

```dart
@DartApi(module: 'host')
abstract class HostApi {
  Future<Profile> loadProfile(String id);    // implemented with async/await
}

@LuaApi(module: 'quests')
abstract class QuestApi {
  Future<Reward> complete(String questId);   // may wait for HostApi
}
```

```lua
complete = function(questId: string): bridge.Reward
  local profile = host.loadProfile("me")      -- a plain call in Lua
  return { gold = profile.level * 10 }
end,
```

```dart
switch (await quests.complete('q1')) {        // Future<LuaCallResult<Reward>>
  case LuaSuccess(:final value): ...
  case LuaFailure(:final message): ...
}
```

- An asynchronous `@DartApi` method is an ordinary `async` Dart method. While
  its future is pending, the Lua call that is waiting for it is paused; a
  failed future raises an error at that call, which the safety level reports
  as usual (`LuaFailure` at `O1`/`O2`, an exception at `O3`).
- An asynchronous `@LuaApi` method returns `Future<LuaCallResult<T>>` at
  `O1`/`O2` and `Future<T>` at `O3`. Only these methods can wait: a
  synchronous one whose Lua calls an asynchronous Dart method fails with
  "called from Lua code that Dart runs synchronously", so declare every
  method that may wait as returning a `Future`.
- While a call waits, the runtime stays usable: other calls, synchronous or
  asynchronous, run in between, as with any Dart `async` code.
- `Future` is accepted only as a method's result; `Future?`, nested futures,
  `FutureOr` and `Stream` are rejected.

Binding wraps the functions of the Lua table in place, so a table can be bound
to one API only. Binding it again to an API of another level fails with
"already bound as ..."; give each binding its own table, for example
`bridge.bindFormulasO1Api({ physicalDamage = formulas.physicalDamage })`.

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
`build_runner` only reads the directories listed under `sources` of the
default target, and `lua/` is not one of its defaults; the `build.yaml`
written by `init` adds it.

## `tlconfig.lua`

`tlconfig.lua` sits in the package root, with paths relative to it: the Teal
language server (used by the VS Code extension) reads `tlconfig.lua` only
from the folder the editor opened and resolves `include_dir` against it. In a
`lua/` subdirectory it is never found, and every `require("<name>_bridge")`
is reported as missing. In a repository with several packages, open the
package folder, or add a root `tlconfig.lua` that points at one of them. The
build does not read it.

## Running the Lua side

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
- `Stream` results.
