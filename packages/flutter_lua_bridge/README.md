# flutter_lua_bridge

Runtime package for typed, synchronous Dart/Lua calls. It bundles the Lua
engine as a Dart native asset and exposes `LuaRuntime`, generated codecs and a
`raw.dart` migration surface.

Application contracts and code generation live in the sibling packages
`flutter_lua_bridge_codegen_annotation` and `flutter_lua_bridge_codegen`.
Generated Dart files import this package, while generated Teal declarations and
Lua companions stay in the application's Cyan project.

```dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

final runtime = LuaRuntime.create();
try {
  // Use the generated API for the application's contract.
} finally {
  runtime.close();
}
```

The package supports strict primitive, enum, DTO, nullable, list and
string-keyed map conversions. Calls are synchronous and confined to the
creating isolate. The old stack-oriented bindings remain available through
`package:flutter_lua_bridge/raw.dart` for migration.

The bundled Lua source can be replaced by the consuming application's build
configuration. Put the path to a Lua source tree (containing `src/lua.h` and
the required Lua library sources) in the workspace root `pubspec.yaml`:

```yaml
hooks:
  user_defines:
    flutter_lua_bridge:
      lua_source: third_party/lua-5.4
      # For a downloaded archive, also set:
      # lua_version: 5.5.0
      # Optional: lua_sha256: <64-character SHA-256 digest>
```

The hook accepts a local source tree or an `http(s)` archive URL. URL sources
must provide a fixed `lua_version` label. An optional `lua_sha256` digest
verifies the downloaded archive; verified archives are cached under the hook's
shared output directory. Without a digest, the URL and version label still
form the cache key; bump `lua_version` when the remote content changes.
The selected tree must contain `src/lua.h` and the required Lua library
sources. The standalone `lua.c` and `luac.c` programs are never included. Lua
version compatibility is determined by the C bridge's API usage rather than a
hard-coded version check.

Generated O1/O2 APIs return `LuaCallResult<T>`; inspect `status`, or pattern
match `LuaSuccess<T>` and `LuaFailure<T>`. Native load/protocol failures remain
`LuaBridgeException`s because they are outside the generated Lua error envelope.
