## Unreleased

- Split the annotations into `flutter_lua_bridge_codegen_annotation` and the
  Dart/Lua/Teal generator into `flutter_lua_bridge_codegen`.
- Add synchronous typed DTO interop, per-runtime host registration, contract fingerprints and a protected native error boundary.
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

## 0.0.2

- Existing raw Lua bindings and Flutter examples.
