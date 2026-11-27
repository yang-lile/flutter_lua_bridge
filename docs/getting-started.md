# Getting started

This guide adds Lua scripting to a Flutter app, one step at a time. For each
step it says what to do, what happens, and why. At the end, Dart calls a
battle formula written in Teal (typed Lua), and that formula calls back into
Dart, both through generated, type-checked code.

The examples use a Flutter app named `my_app`. A plain Dart package works
the same way: use `dart` where the guide says `flutter`, and read the Lua
source from a file instead of the asset bundle.

## How the pieces fit

```text
 you write                     build_runner generates             shipped in the app
 ─────────                     ──────────────────────             ──────────────────
 lib/bridge/battle.dart  ───►  lib/bridge/battle.g.dart     ───►  compiled Dart
   (the contract)                (clients, codecs, Lua glue)
                         ───►  lua/types/battle_bridge.d.tl
                                 (Teal types of the contract)
 lua/src/battle.tl       ───►  assets/lua/battle.lua        ───►  asset (Lua source)
   (the implementation,          (Teal compiled to Lua)
    checked against the types)
```

- The **contract** is a Dart file of abstract classes. It is the single
  description of the API; everything that crosses between Dart and Lua is
  derived from it, so the two sides cannot disagree about names or types.
- The **runtime** (`flutter_lua_bridge`) runs Lua inside the app. Lua 5.4 is
  compiled from source for each target platform by a build hook, so nothing
  is installed on the device or the developer machine.
- The **code generator** (`flutter_lua_bridge_codegen`) runs only at
  development time, under `build_runner`. It is not shipped.
- **Teal** is optional. It is compiled to Lua by a compiler bundled with the
  generator; the app only ever loads Lua.

## Step 0: Requirements

- **Flutter 3.50 or later (Dart 3.14).** The packages require it.
- **A C compiler for every platform you build for**: Xcode for iOS and
  macOS, the Android NDK (installed through Android Studio) for Android,
  clang or gcc on Linux, Visual Studio with the C++ workload on Windows.
  *Why:* the build hook compiles the bundled Lua sources with the platform's
  toolchain, the same one Flutter already needs for those platforms.
- *Optional:* a Teal extension for your editor (for VS Code, "Teal Language
  Support"), for completion and type errors while you type.

## Step 1: Add the packages

```sh
cd my_app
flutter pub add flutter_lua_bridge
flutter pub add dev:build_runner dev:flutter_lua_bridge_codegen
```

**What happens:** `pubspec.yaml` gains `flutter_lua_bridge` under
`dependencies` and the other two under `dev_dependencies`.

**Why:** the runtime is part of the app, so it is a normal dependency.
`build_runner` and the generator only produce source files during
development, so they are dev dependencies and add nothing to the app's size.

## Step 2: Scaffold the project

```sh
dart run flutter_lua_bridge_codegen:init
```

**What happens:** it creates the directories and two configuration files,
prints the layout, and lists what it could not do for you:

```text
  created  lib/bridge/
  created  lua/src/
  created  lua/types/
  created  assets/lua/
  created  tlconfig.lua
  created  lua/test/main.tl
  created  build.yaml
...
Left for you:
- For a Flutter app, ship the compiled Lua by adding it to pubspec.yaml:

  flutter:
    assets:
      - assets/lua/
```

Do what it lists. Here, add the assets entry to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/lua/
```

**Why each file exists:**

| File | Purpose | Who maintains it |
| --- | --- | --- |
| `build.yaml` | `build_runner` only reads the directories listed under `sources`; this adds `lua/**` so the Teal and Lua sources are built | `init` once, then you |
| `tlconfig.lua` | Tells the Teal language server and the `run` command where modules live (`lua/src`, `lua/types`, `lua/test`). Editors read it only from the opened folder, which is why it sits at the package root | `init` once, then you |
| `lua/test/main.tl` | A scratch entry for running Lua without the app (step 6) | you |
| `assets/lua/` | Where the compiled Lua lands; listing it as an asset ships it | the builder |

`init` never overwrites an existing file, so it is safe to run again.

## Step 3: Write the contract

Create `lib/bridge/battle.dart`:

```dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'battle.g.dart';

/// Lua sees the values as the strings "fire", "water" and "grass".
enum Affinity { fire, water, grass }

/// A data class: Lua sees it as a table with these fields.
class Fighter {
  const Fighter({
    required this.name,
    required this.attack,
    required this.defense,
    required this.affinity,
  });

  final String name;
  final int attack;
  final int defense;
  final Affinity? affinity; // nullable: may be nil in Lua
}

/// Implemented in Lua, called from Dart.
@LuaApi(module: 'battle')
abstract class BattleApi {
  int damage(Fighter attacker, Fighter defender);
}

/// Implemented in Dart, called from Lua.
@DartApi(module: 'host')
abstract class HostApi {
  void log(String message);
  double multiplier(Affinity attacker, Affinity defender);
}
```

**What it means:**

- `@LuaApi(module: 'battle')`: Lua implements `BattleApi` in a module named
  `battle`; Dart calls it through a generated `BattleApiClient`.
- `@DartApi(module: 'host')`: Dart implements `HostApi`; Lua calls it.
- `part 'battle.g.dart'`: the generated code becomes part of this library.
- The library is named `battle`, so its Lua glue module is `battle_bridge`.

**Why a contract:** both sides are generated from this one file, so a
renamed method or a changed type is a compile error in Dart and a type error
in Teal, instead of a crash at runtime.

**Rules the generator enforces** (a violation fails the build and points at
the declaration):

- Types: `bool`, `int`, `double`, `String`, simple enums, data classes,
  `List<T>`, `Map<String, T>`, the nullable forms of these, and `void`
  results. `dynamic`, `Object`, `Future`, `Stream`, functions, untyped
  collections, non-`String` map keys and nullable elements are rejected.
- Data classes: one unnamed constructor whose parameters are all required
  (nullable ones too) and initialise `final` fields of the same names; no
  other fields, no inheritance, no recursion.
- Interfaces: abstract methods only; required named parameters are allowed
  and become positional in Lua.

The full list is in the [code generator reference](codegen-guide.md).

## Step 4: Generate the Dart side and the Teal types

```sh
dart run build_runner build
```

**What happens:**

- `lib/bridge/battle.g.dart` appears, with `BattleApiClient`,
  `registerHostApi`, the codecs for `Fighter` and `Affinity`, and the Lua glue
  module `battle_bridge` embedded as a string.
- `lua/types/battle_bridge.d.tl` appears: the Teal declarations of what
  `require("battle_bridge")` returns.
- Nothing appears in `assets/lua/` yet, because `lua/src/` is still empty.

While you work, prefer `dart run build_runner watch`. It regenerates on
every save of a contract or a file under `lua/src`.

**Why:** the Teal types must exist before you write the implementation, so
the editor and the compiler can check it against the contract.

**Do not edit** `*.g.dart`, `lua/types/` or `assets/lua/`. They are
overwritten on the next build. Commit them like any other generated Dart
file, so the app builds without running the generator first.

## Step 5: Implement the Lua side in Teal

Create `lua/src/battle.tl`:

```lua
local bridge = require("battle_bridge")
local host = bridge.getHostApi()

local implementation: bridge.BattleApi = {
  damage = function(attacker: bridge.Fighter, defender: bridge.Fighter): integer
    local factor = 1.0
    if attacker.affinity and defender.affinity then
      factor = host.multiplier(attacker.affinity, defender.affinity)
    end
    local raw = math.floor(attacker.attack * factor) - defender.defense
    local result = math.max(0, raw)
    host.log(attacker.name .. " hits " .. defender.name .. " for " .. result)
    return result
  end,
}

return bridge.bindBattleApi(implementation)
```

Then build again (or let `watch` do it):

```sh
dart run build_runner build
```

**What happens:** the bundled Teal compiler type-checks `battle.tl` against
`battle_bridge.d.tl` and writes `assets/lua/battle.lua`. A type error
(a misspelled field, a `string` returned where `integer` is expected) fails
the build with its file, line and column, and no Lua is written.

**What each line does:**

- `require("battle_bridge")` returns the generated glue. Its type,
  `bridge.BattleApi`, `bridge.Fighter` and so on, come from the contract.
- `bridge.getHostApi()` returns the Dart implementation of `HostApi` that
  the app registers in step 7.
- `return bridge.bindBattleApi(implementation)` is required. It checks that
  every contract method is present, and at the default safety level it wraps
  each one to validate arguments and results and catch errors. A module that
  returns its table without binding it cannot be called from Dart.

**Why Teal:** it checks the implementation against the contract before the
app runs. Plain Lua works too: name the file `lua/src/battle.lua` and it is
copied to `assets/lua/` unchanged, without type checking.

## Step 6: Test the Lua side without the app

Create `lua/test/battle_test.tl`:

```lua
local bridge = require("battle_bridge")

-- Outside the app, getHostApi() returns an empty table: fill it with stand-ins.
local host = bridge.getHostApi()
host.log = function(_: string) end
host.multiplier = function(_attacker: bridge.Affinity, _defender: bridge.Affinity): number
  return 2.0
end

local battle = require("battle")
local knight: bridge.Fighter = { name = "knight", attack = 10, defense = 3, affinity = "fire" }
local slime: bridge.Fighter = { name = "slime", attack = 2, defense = 4, affinity = "grass" }

assert(battle.damage(knight, slime) == 16)  -- 10 * 2.0 - 4
assert(battle.damage(slime, knight) == 1)   -- 2 * 2.0 - 3
```

```sh
dart run flutter_lua_bridge_codegen:run           # every main.tl and *_test.tl under lua/test
dart run flutter_lua_bridge_codegen:run --watch   # again on every save
```

**What happens:** each entry runs on the same Lua runtime the app uses, with
Teal type-checked as in the build. An entry passes when it returns without
an error; `assert` is the test primitive. `print` output is shown.

**Why:** it is the fastest loop for business logic: no device, no Flutter
build. Outside the app `bindBattleApi(t)` returns `t` unchanged, so the test
calls the functions directly.

## Step 7: Implement the Dart side and call Lua

Implement `HostApi` and call `BattleApi`, for example in `lib/battle_service.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import 'bridge/battle.dart';

class AppHost implements HostApi {
  @override
  void log(String message) => debugPrint('[lua] $message');

  @override
  double multiplier(Affinity attacker, Affinity defender) =>
      switch ((attacker, defender)) {
        (Affinity.fire, Affinity.grass) ||
        (Affinity.water, Affinity.fire) ||
        (Affinity.grass, Affinity.water) => 2.0,
        (Affinity.grass, Affinity.fire) ||
        (Affinity.fire, Affinity.water) ||
        (Affinity.water, Affinity.grass) => 0.5,
        _ => 1.0,
      };
}

/// Owns one Lua runtime for as long as the battle screen lives.
class BattleService {
  BattleService._(this._lua, this._battle);

  static Future<BattleService> start() async {
    final lua = LuaRuntime.create(); // LuaLibrary.safe: no io, os or debug
    try {
      registerHostApi(AppHost(), runtime: lua); // before Lua that uses it loads
      final battle = BattleApiClient.load(
        runtime: lua,
        source: await rootBundle.loadString('assets/lua/battle.lua'),
      );
      return BattleService._(lua, battle);
    } catch (_) {
      lua.close();
      rethrow;
    }
  }

  final LuaRuntime _lua;
  final BattleApiClient _battle;

  int damage(Fighter attacker, Fighter defender) {
    switch (_battle.damage(attacker, defender)) {
      case LuaSuccess(:final value):
        return value;
      case LuaFailure(:final kind, :final message):
        // kind: type (a value broke the contract), runtime (the Lua code
        // raised an error) or protocol (the module did not answer as bound).
        throw StateError('battle.damage failed ($kind): $message');
    }
  }

  void dispose() => _lua.close();
}
```

**What happens, in order:**

1. `LuaRuntime.create()` opens a Lua state with the safe standard libraries:
   no file, process or native-library access, and `require` only finds
   modules the app provides.
2. `registerHostApi` exposes `AppHost` as the module `host`. It must come
   before loading Lua that calls `getHostApi()`, because the Lua module runs
   when it loads.
3. `BattleApiClient.load` loads the glue module, runs `battle.lua` as the
   module `battle`, checks that every contract method is there, and returns
   the client.
4. Every call is synchronous. At the default safety level (`O1`) it returns
   `LuaCallResult<int>`: `LuaSuccess` with the value, or `LuaFailure` with a
   `kind` and a `message`. A Lua bug never crashes the app.
5. `close()` frees the Lua state. Every client of that runtime fails with a
   `StateError` afterwards.

**Why this shape:** a runtime belongs to the isolate that created it, so
create it where you use it and close it when that owner goes away. Loading
throws `LuaBridgeException` (syntax errors, a missing method), which is why
`start` closes the runtime when loading fails.

## Step 8: Run it

```sh
flutter run
```

**What happens:** before compiling Dart, Flutter runs the build hook of
`flutter_lua_bridge`. It compiles Lua 5.4 and the bridge's C shim for the
target and bundles the native library with the app. The first build per
platform takes longer; later builds reuse the result.

`flutter test` runs the same hook for the host machine, so widget and unit
tests can create a `LuaRuntime` and load `assets/lua/battle.lua` too.

## Step 9: Day-to-day workflow

Keep `dart run build_runner watch` running, then:

| You change | What to do | Why |
| --- | --- | --- |
| Business logic in `lua/src/` | Save; run `flutter_lua_bridge_codegen:run`; hot restart the app | `watch` recompiles the asset; the asset is read when the runtime loads it, which a hot restart repeats and a hot reload does not |
| The contract | Save; fix the Teal type errors the build reports; fix the Dart compile errors in your `HostApi` implementation and call sites | Both sides are regenerated from the contract, so every place that no longer matches is reported at build time |
| A helper module used by several implementations (`require("formulas")`) | Load it with `runtime.loadModule('formulas', source: ...)` before the modules that require it | In the app, `require` only finds modules the app has loaded |
| Performance of a hot path | Raise its safety level, see below | Type checks and `pcall` cost time on every call |

**Safety levels** choose how much each call checks:

| Level | Lua checks argument and result types | Errors are caught | Dart gets |
| --- | --- | --- | --- |
| `O1` (default) | yes | yes | `LuaCallResult<T>` |
| `O2` | no (results are still decoded and checked in Dart) | yes | `LuaCallResult<T>` |
| `O3` | no | no | `T`; failures throw `LuaBridgeException` |

Set the project default under the builder options in `build.yaml`
(`optimization: O2`), or one interface with
`@LuaApi(module: 'battle', optimization: LuaOptimization.o3)`. Keep `O1` for
code that can change without a new app release (next section).

**The Lua version** is 5.4 by default. To build 5.3 or 5.5, set it in the
root `pubspec.yaml` of the app (or of the workspace):

```yaml
hooks:
  user_defines:
    flutter_lua_bridge:
      lua_version: "5.5"
```

The Teal compiler follows it. See [Choosing the Lua source](lua-source.md).

## Step 10: Ship

The release build contains the runtime package, its native library, the
generated Dart and the files in `assets/lua/`. Neither the generator, nor
Teal, nor `lua/src` is shipped.

To change the Lua of an installed app without a store release, see
[Loading Lua at runtime](dynamic-lua.md).

## Going further

- [Loading Lua at runtime](dynamic-lua.md): delivering scripts from a
  server, the conditions they must meet, and a safe way to swap them in.
- [Code generator reference](codegen-guide.md): every contract rule,
  `build.yaml` options, interface inheritance, the `run` command.
- [Example app](../examples/flutter_lua_bridge_example): a card battle game
  with every safety level, Lua-side tests and a benchmark.
