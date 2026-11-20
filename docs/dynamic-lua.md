# Loading Lua at runtime

An app built with flutter_lua_bridge reads its Lua as text when it creates a
runtime, usually from `assets/lua/`. The same text can come from anywhere: a
server, a file, a database. This is how business logic changes without a new
app release. This page covers what a delivered script can change, the
conditions it must meet, and a loading flow that never leaves the app
without working Lua.

It builds on the `battle` example of [Getting started](getting-started.md).

## What a script can and cannot change

The contract (`lib/bridge/battle.dart`) is compiled into the app. So is the
Lua glue generated from it: the `battle_bridge` module lives inside
`battle.g.dart`, not in a file you deliver. A delivered script therefore
replaces **the implementation** of a contract, never the contract itself.

| Can change with a delivered script | Needs a new app release |
| --- | --- |
| The body of every `@LuaApi` method: formulas, rules, tables of data | Adding, removing or renaming a method, a parameter or a field |
| Helper modules the implementation requires | Changing a type, or a method's safety level |
| Which `@DartApi` methods the script calls, among those the app registers | Adding a `@DartApi` method, or a Lua module the app does not load |

## Conditions a delivered script must meet

A script is accepted only if all of these hold. The "When it fails" column
is what the app sees otherwise.

| # | Condition | Why | When it fails |
| --- | --- | --- | --- |
| 1 | It is **Lua source text**, not bytecode. Compile Teal ahead of time and deliver the `assets/lua/<module>.lua` that `build_runner` writes | `loadModule` accepts text only: bytecode is not portable between Lua releases and is not verified by Lua | Loading throws `LuaBridgeException` "attempt to load a binary chunk" |
| 2 | It is built from the **same contract version** the installed app was built with | The app checks the script against its own, compiled-in contract. The bridge does not version contracts for you (see [Versioning](#versioning)) | Depends on what changed: see the compatibility table below |
| 3 | It **returns `bridge.bindXxx(implementation)`**, where `bridge = require("<contract>_bridge")` | Binding checks the table and, at `O1`/`O2`, installs the wrappers that report errors as results | A plain table loads, but every call fails with `LuaFailure`; a non-table result throws "module 'battle' must return a table" |
| 4 | It **implements every method** of the interface, with the Lua names of the contract | Calls are resolved by name when the client binds | Loading throws `LuaBridgeException` "BattleApi.damage is missing". Extra methods and extra table fields are ignored |
| 5 | Every argument it accepts and every value it returns **matches the contract types** | Types are part of the contract; a required data class field must be present | At `O1` and `O2` the call returns `LuaFailure` with `kind: type`, for example "BattleApi.run.result.a: expected integer". At `O3` it throws |
| 6 | It is written for the app's **Lua release line** (5.4 unless the app chose otherwise) | Lua 5.3, 5.4 and 5.5 differ in syntax and semantics; Teal targets the configured line | Syntax errors throw at load; semantic differences show up as wrong results |
| 7 | It uses only the **standard libraries the runtime opened** (`LuaLibrary.safe` by default: no `io`, `os`, `debug` or native modules) | The sandbox is what makes running delivered code acceptable | Loading or calling fails, for example "attempt to index a nil value (global 'io')" |
| 8 | Every module it `require`s is **loaded by the app first** | In the app, `require` finds only modules the host provides; there is no file search path | Loading throws "module 'formulas' not found" |
| 9 | It calls only `@DartApi` methods **this app version registers** | The Dart side is compiled into the app | The call fails at runtime (a `LuaFailure` with `kind: runtime` at `O1`/`O2`) |
| 10 | It stays within the **memory limit** you set and **returns promptly** | Calls are synchronous on the calling isolate | Over the limit: `LuaFailure` "not enough memory". A script that never returns blocks the isolate; see [Runaway scripts](#runaway-scripts) |

Conditions 4, 5 and 8 are checked by the bridge; the others are yours to
guarantee, mostly by building and testing the script with the same project
that builds the app.

## Producing a script to deliver

Deliver what the normal build produces, from the source of the app version
you target:

```sh
git checkout <the release of the app>     # the same contract as the installed app
# edit lua/src/battle.tl
dart run flutter_lua_bridge_codegen:run   # the Lua-side tests
dart run build_runner build               # type checks against the contract, writes assets/lua/
flutter test                              # optional: the Dart tests on the new Lua
```

Then publish `assets/lua/battle.lua`, and every helper module it requires,
with the metadata the app checks before loading (next section).

## Versioning

The bridge does not fingerprint contracts, so give each contract a version
yourself and publish scripts per version:

```dart
/// The version of lib/bridge/battle.dart. Raise it with every change to the
/// file, and keep publishing scripts for every version still installed.
const battleContractVersion = 1;
```

What happens to a script built for an older contract:

| Contract change | Old scripts on the new app |
| --- | --- |
| A `@LuaApi` method added | Fail to load (condition 4) |
| A `@LuaApi` method removed | Still load; the extra function is ignored |
| A field added to a data class that Lua returns | Required field: every call that returns it fails (condition 5). Nullable field: works, the field is `null` |
| A field added to a data class that Lua receives | Works; the script ignores the new field |
| A type changed | Calls fail with `kind: type` |
| A `@DartApi` method added | Works |

Raising the version on every change is simpler than reasoning about each
case, and it is what the loading flow below checks.

## A loading flow that cannot break the app

The principle: build the new runtime completely, test it, then swap it in.
Never modify the runtime the app is using.

Give the `BattleService` of the guide a constructor that takes the Lua
sources; `bundled()` replaces the guide's `start()`:

```dart
class BattleService {
  BattleService._(this._lua, this._battle);

  /// The Lua shipped with the app: always available, the last resort.
  static Future<BattleService> bundled() async => fromSources({
    'battle': await rootBundle.loadString('assets/lua/battle.lua'),
  });

  /// Loads [modules] (module name to Lua source) into a new runtime: the
  /// helpers in the order given, then `battle`. Throws if any of them fails
  /// to load, does not implement [BattleApi], or fails a test call.
  static BattleService fromSources(Map<String, String> modules) {
    final lua = LuaRuntime.create(memoryLimit: 16 << 20); // 16 MB
    try {
      registerHostApi(AppHost(), runtime: lua);
      for (final MapEntry(key: name, value: source) in modules.entries) {
        if (name != 'battle') lua.loadModule(name, source: source);
      }
      final battle = BattleApiClient.load(
        runtime: lua,
        source: modules['battle']!,
      );
      final service = BattleService._(lua, battle);
      service._selfTest();
      return service;
    } catch (_) {
      lua.close();
      rethrow;
    }
  }

  /// Type errors show up per call, not at load: call once before use.
  void _selfTest() {
    const probe = Fighter(name: 'probe', attack: 5, defense: 1, affinity: Affinity.fire);
    damage(probe, probe); // throws on LuaFailure
  }

  // damage() and dispose() as in the guide.
}
```

Then, wherever the app updates its scripts:

```dart
class BattleScripts {
  BattleScripts(this.current);

  BattleService current;

  Future<void> update() async {
    final release = await fetchRelease(); // your server: metadata and sources

    // 1. Is it meant for this app? Same contract, same Lua line.
    if (release.contract != battleContractVersion) return;
    if (!LuaRuntime.luaRelease.startsWith('Lua ${release.luaLine}')) return;

    // 2. Is it really yours? A loaded script runs inside the app.
    if (!verifySignature(release)) return; // your key, your algorithm

    // 3. Build and test a separate runtime; the current one is untouched.
    final BattleService next;
    try {
      next = BattleService.fromSources(release.modules);
    } on Object catch (error) {
      reportRejectedScript(release, error);
      return;
    }

    // 4. Swap, then free the old runtime.
    final previous = current;
    current = next;
    previous.dispose();
    await storeLastKnownGood(release); // load it at the next start
  }
}
```

At startup, load the last known good release if there is one and it passes
the same checks, and fall back to `BattleService.bundled()` otherwise.

**Why a new runtime instead of reloading in place:** calling
`BattleApiClient.load` again on the runtime in use does replace the module,
and existing clients immediately call the new code. But a script that fails
halfway leaves the runtime with part of its modules replaced, and globals or
modules from the old script stay behind. A separate runtime makes the update
all or nothing, and closing the old one frees everything it held.

**Why sign:** a script runs with every capability you gave the runtime:
the libraries you opened and every `@DartApi` method you registered.
Verify a signature made with a key only your build or release process
holds (for example Ed25519) before loading. HTTPS alone protects the
transfer, not the server.

## Runaway scripts

Calls are synchronous: Dart waits on the calling isolate until Lua returns.
The bridge has no time limit of its own. What exists:

- `LuaRuntime.interrupt()` stops the running Lua code with an error that
  Lua cannot catch. The runtime checks for it every 1000 VM instructions,
  but it has to be called while Lua runs, so from Dart code that Lua calls
  (a `@DartApi` method or a `lua.function` callback).
- A script you cannot fully trust or test can run on a background isolate,
  so a hang does not freeze the UI. `examples/lua_canvas_host` does this
  (`lib/lua_worker.dart`), with a Lua-side time budget.

The practical rule for delivered business logic: test it with the same
project before publishing (conditions 2 and 6), keep loops bounded by the
input, and keep `O1`.

## Choosing the safety level for delivered code

Use `O1` (the default) for any interface whose implementation can be
delivered. It validates every argument and result in Lua and turns every
error into a `LuaFailure`. `O2` keeps the error handling but checks only
results, in Dart. `O3` lets a broken script throw into your Dart code, so
keep it for interfaces whose Lua ships only inside the app.

## Store policies

Interpreted scripts that run in a sandbox and do not change the purpose of
the app are generally accepted, but the rules are the stores', not this
library's. Check the current App Store Review Guidelines (sections 2.5.2
and 4.7) and Google Play's policy on code downloaded at runtime before
relying on delivered scripts.
