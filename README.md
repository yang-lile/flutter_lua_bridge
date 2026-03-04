# flutter_lua_bridge

Dart FFI bindings for Lua 5.4. Compile Lua from source with no external dependencies.

## Features

- ✅ Lua 5.4 source code included - easy to customize
- ✅ Works on macOS, Linux, Windows, Android, iOS
- ✅ High-level API (`LuaState`) and low-level FFI bindings
- ✅ Automatic native library building via Dart hooks

## Installation

```shell
dart pub add flutter_lua_bridge
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_lua_bridge: ^0.1.0
```

## Usage

### High-level API (Recommended)

```dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

void main() {
  LuaState.use((lua) {
    lua.openLibs();
    
    // Run Lua code
    lua.doString('''
      function add(a, b)
        return a + b
      end
      result = add(10, 20)
    ''');
    
    // Get result
    lua.getGlobal('result');
    print('Result: \${lua.toInteger(-1)}');
  });
}
```

### Low-level FFI

```dart
import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

void main() {
  final L = luaL_newstate();
  luaL_openlibs(L);
  
  // Execute Lua code
  luaL_dostring(L, 'print("Hello from Lua!")'.toNativeUtf8());
  
  lua_close(L);
}
```

## Platform Support

| Platform | Status |
|----------|--------|
| macOS | ✅ |
| Linux | ✅ |
| Windows | ✅ |
| Android | ✅ |
| iOS | ✅ |

No manual configuration needed - the package automatically builds native libraries on all platforms.

## Example

See the [example](example/) folder for a complete Flutter demo app.

```shell
cd example
flutter run
```

## License

MIT
