# flutter_lua_bridge

Dart <-> Lua interoperability. Compile from source code, easy to replace Lua core.

## Getting Started

import this package by cmdline:

```shell
dart pub add flutter_lua_bridge
```

## Project structure

This template uses the following structure:

* `src`: Contains the lua source code, and a CmakeFile.txt file for building
  that source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

* platform folders (`android`, `ios`, `macos`, etc.): Contains the build files
  for building and bundling the native code library with the platform application.
