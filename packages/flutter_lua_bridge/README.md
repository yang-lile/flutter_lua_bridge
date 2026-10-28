# flutter_lua_bridge

Runtime package for typed, synchronous Dart/Lua 5.4 calls. It bundles the Lua
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

Generated O1/O2 APIs return `LuaCallResult<T>`; inspect `status`, or pattern
match `LuaSuccess<T>` and `LuaFailure<T>`. Native load/protocol failures remain
`LuaBridgeException`s because they are outside the generated Lua error envelope.
