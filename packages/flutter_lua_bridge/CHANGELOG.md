## Unreleased

- Split the annotations into `flutter_lua_bridge_codegen_annotation` and the
  Dart/Lua/Teal generator into `flutter_lua_bridge_codegen`.
- Add synchronous typed DTO interop, per-runtime host registration, contract fingerprints and a protected native error boundary.
- Pin the bundled engine to official Lua 5.4.9 and regenerate its raw bindings.
- Move the previous detailed Lua API to `raw.dart`; the main entry now exports the typed runtime and errors. This changes existing imports.
- Migrate the Flutter basic demo and add a bidirectional BattleApi/HostApi example.
- Add generated Lua safety levels O1/O2/O3, result envelopes for O1/O2, Lua
  runtime type validators and `pcall` error capture.

## 0.0.2

- Existing raw Lua bindings and Flutter examples.
