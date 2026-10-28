# flutter_lua_bridge_codegen

Command line generator for `flutter_lua_bridge` contracts. It parses a Dart
contract, validates its supported types and emits three synchronized files:

```sh
dart run flutter_lua_bridge_codegen --input bridge/api.dart
```

The Dart file contains typed proxies and host registration, the Lua file is a
small protocol companion, and the `.d.tl` file supplies Teal declarations for
the application's Cyan project. Business logic stays in editable `.tl` files;
the generator never overwrites those files.

Use `--check` in CI to fail when generated artifacts are stale. The generator
has no dependency on the runtime package, so it can run in a development-only
toolchain. Use `-O1` (default), `-O2` or `-O3` to choose the generated Lua
safety level. O1/O2 APIs return `LuaCallResult<T>`; O3 keeps direct return
values and propagates uncaught Lua failures.
