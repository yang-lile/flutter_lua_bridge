# flutter_lua_bridge_codegen_annotation

Small, dependency free annotations for describing a Dart/Lua bridge contract.
`package:flutter_lua_bridge/flutter_lua_bridge.dart` re-exports them, so a
contract library needs only that one import.

| Annotation | Meaning |
| --- | --- |
| `@LuaApi(module: 'battle')` | The interface is implemented in Lua or Teal and called from Dart. |
| `@DartApi(module: 'host')` | The interface is implemented in Dart and called from Lua. |
| `@LuaName('calculate_damage')` | The name of a method, field or enum value on the Lua side. |

`LuaApi.optimization` (`LuaOptimization.o1`, `o2` or `o3`) overrides, for one
interface, the default safety level set in the generator's `build.yaml`
options.
