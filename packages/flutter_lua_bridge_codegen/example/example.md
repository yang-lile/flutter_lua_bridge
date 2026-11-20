# Example

A contract with one `@LuaApi` interface, implemented in Teal and called from
Dart. The full Flutter app, with a card battle game, host APIs and every
safety level, is in
[`examples/flutter_lua_bridge_example`](https://github.com/yang-lile/flutter_lua_bridge/tree/main/examples/flutter_lua_bridge_example).

```sh
dart run flutter_lua_bridge_codegen:init
```

`lib/bridge/basic_api.dart`, the contract:

```dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

part 'basic_api.g.dart';

class RandomResult {
  const RandomResult({required this.luaVersion, required this.a, required this.b});
  final int luaVersion;
  final int a;
  final int b;
}

@LuaApi(module: 'basic')
abstract class BasicApi {
  RandomResult run();
}
```

`lua/src/basic.tl`, the implementation, type checked against the generated
`lua/types/basic_api_bridge.d.tl`:

```lua
local bridge = require("basic_api_bridge")

local implementation: bridge.BasicApi = {
  run = function(): bridge.RandomResult
    local major, minor = _VERSION:match("^Lua (%d+)%.(%d+)")
    return {
      luaVersion = math.tointeger(tonumber(major) * 100 + tonumber(minor)),
      a = math.random(1, 1024),
      b = math.random(1, 1024),
    }
  end,
}

return bridge.bindBasicApi(implementation)
```

```sh
dart run build_runner build
```

This writes `basic_api.g.dart` and compiles the Teal to `assets/lua/basic.lua`
(list `assets/lua/` under `flutter: assets:`). Calling it:

```dart
final lua = LuaRuntime.create();
try {
  final source = await rootBundle.loadString('assets/lua/basic.lua');
  final result = BasicApiClient.load(runtime: lua, source: source).run();
  switch (result) {
    case LuaSuccess(:final value):
      print('Lua ${value.luaVersion}: ${value.a}, ${value.b}');
    case LuaFailure(:final kind, :final message):
      print('$kind: $message');
  }
} finally {
  lua.close();
}
```

At the default safety level `O1` the call returns `LuaCallResult<T>`; with
`@LuaApi(module: 'basic', optimization: LuaOptimization.o3)` it returns
`RandomResult` directly and throws `LuaBridgeException`.

The Lua side also runs without the app:

```sh
dart run flutter_lua_bridge_codegen:run    # lua/test/main.tl and *_test.tl
```
