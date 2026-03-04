# Development Guide

This document is for developers who want to contribute to or modify `flutter_lua_bridge`.

## Project Structure

```
flutter_lua_bridge/
├── hook/
│   └── build.dart          # Build hook - compiles Lua C source to native libraries
├── lib/
│   ├── src/
│   │   ├── gen/
│   │   │   └── flutter_lua_bridge.g.dart   # FFI bindings
│   │   └── ...             # Dart wrapper code
│   └── flutter_lua_bridge.dart
├── src/lua/src/            # Lua 5.4.7 source code
└── pubspec.yaml
```

## How It Works

### Native Assets Build Hook

The `hook/build.dart` uses `native_toolchain_c` to compile Lua C source code:

```dart
final builder = CBuilder.library(
  name: packageName,
  assetName: 'src/gen/flutter_lua_bridge.g.dart',  // Must match FFI file path
  sources: ['src/lua/src/lapi.c', 'src/lua/src/lauxlib.c', ...],
  libraries: ['m', 'dl'],  // Link math and dynamic loading libraries
);
```

The build hook automatically runs during `dart run`, `flutter build`, or `flutter run`.

### Asset ID Matching

For FFI to find the native library, the asset ID must match:

| Source | Asset ID |
|--------|----------|
| Build hook | `package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart` |
| FFI library URI | `package:flutter_lua_bridge/src/gen/flutter_lua_bridge.g.dart` |

The `assetName` in `CBuilder.library()` must match the relative path of the FFI file (`lib/` is implicit).

## Platform-Specific Notes

### Android

- Uses bionic libc
- Requires `libm` (math library) for `acos`, `sin`, `cos`, etc.
- Requires `libdl` for dynamic loading support
- No manual CMake/Gradle configuration needed (handled by `native_toolchain_c`)

### iOS

- Dynamic libraries are automatically bundled into frameworks
- Bitcode is disabled by default

## Testing

```shell
# Run Dart tests
dart test

# Run example app
cd example
flutter run
```

## Rebuilding Native Assets

To force a rebuild of native assets:

```shell
# Clean build cache
rm -rf .dart_tool/build/
rm -rf build/

# Rebuild
flutter build apk --debug  # or your target platform
```

## Lua Source Modifications

The Lua 5.4.7 source is in `src/lua/src/`. To modify:

1. Edit C source files
2. Rebuild (hook automatically recompiles)
3. Test thoroughly

### Lua Configuration

The build hook uses standard C (no `LUA_USE_LINUX` macro). This means:
- Standard `longjmp/setjmp` for error handling
- Standard `signal()` for signal handling
- No `io.popen()` support
- No `package.loadlib()` support

To enable POSIX features, edit `hook/build.dart` and add:

```dart
defines: {
  'LUA_USE_LINUX': null,
}
```

## Troubleshooting

### "Could not find native asset"

Check that `assetName` in `hook/build.dart` matches the FFI file path.

### "cannot locate symbol 'acos'"

Make sure `libraries: ['m', 'dl']` is set in `CBuilder.library()`.

### Build cache issues

```shell
flutter clean
rm -rf .dart_tool/build/
```
