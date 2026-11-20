## Unreleased

- A Dart function called from Lua may return a `Future`: Lua waits for it
  as for a plain call, without blocking the isolate, when Dart runs that
  Lua with `LuaFunction.callAsync` (or a generated asynchronous method). A
  failed future raises a Lua error at the call. `LuaThread.resumeAsync`
  does the same for a coroutine driven by hand.
- Streams: `LuaFunction.stream` runs a Lua generator as a lazy Dart
  stream; a Dart function returning a `Stream` (or `LuaRuntime.iterate`)
  gives Lua an iterator for a generic `for`.
- The native ABI moves to 2 (`flb_yield`, `flb_can_yield`,
  `flb_resume_failure`, and a `flags` argument to `flb_resume`). Calls that
  do not wait are as fast as before.

## 0.2.0

- Require Dart 3.14 (Flutter 3.50) and the current majors of the build hook
  dependencies: `hooks` and `code_assets` 2.2, `native_toolchain_c` 0.19.6,
  `archive` 4.7.
- The native bindings are regenerated with ffigen 23; the Dart API is
  unchanged.

## 0.1.1

- Allow the current major versions of the build hook dependencies:
  `hooks` and `code_assets` 1.x or 2.x, `native_toolchain_c` up to 0.19.
- Require `archive` 4.

## 0.1.0

- Split the annotations into `flutter_lua_bridge_codegen_annotation` and the
  Dart/Lua/Teal generator into `flutter_lua_bridge_codegen`.
- Add synchronous typed DTO interop, per-runtime host registration and a protected native error boundary.
- The library re-exports the contract annotations and the codecs;
  `package:flutter_lua_bridge/generated.dart` is removed.
- `LuaRuntime.bindLua` and `registerDart` no longer take a contract
  fingerprint. Versioning the shipped Lua against the Dart code is left to the
  application.
- Bundle official Lua 5.3.6, 5.4.9 and 5.5.0 under `third_party/`; select one
  with the `lua_version` or `lua_source` hook define (default 5.4).
- Replace the stack-oriented raw bindings with the `flb` C shim
  (`native/flb.h`): a stackless value/handle API whose interface is identical
  for every supported Lua release. **Breaking:** `raw.dart`, `LuaState` and the
  `lua_*`/`luaL_*` bindings are removed.
- `LuaRuntime` is the single Dart entry point: `run`/`eval`/`load`, globals,
  tables, functions, coroutines, userdata classes, modules, memory limit and
  interrupt, plus the support calls used by generated code.
- **Breaking:** `LuaRuntime.create()` opens `LuaLibrary.safe` by default
  (no `io`, `os`, `debug` or native module loading).
- **Breaking:** `LuaBridgeException.message` no longer embeds the traceback;
  read `traceback` and `status` instead.
- Host callbacks may re-enter the runtime; closing it inside a callback is
  still rejected.
- Migrate the Flutter basic demo and add a bidirectional BattleApi/HostApi example.
- Add generated Lua safety levels O1/O2/O3, result envelopes for O1/O2, Lua
  runtime type validators and `pcall` error capture.

## 0.0.1

- Initial release: raw Lua bindings and Flutter examples.
