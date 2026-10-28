#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
playground="$repo_root/playground"

mkdir -p "$playground/bridge" "$playground/bin" "$playground/lib" \
  "$playground/lua/src" "$playground/lua/build"

cat > "$playground/bridge/demo.dart" <<'DART'
import 'package:flutter_lua_bridge_codegen_annotation/flutter_lua_bridge_codegen_annotation.dart';

@ConfigureLuaBridge(
  dartOut: 'playground/lib/demo.g.dart',
  luaOut: 'playground/lua/src/demo_bridge.lua',
  tealOut: 'playground/lua/src/demo_bridge.d.tl',
  optimization: 'O1',
)
@LuaApi(module: 'demo')
abstract class DemoApi {
  int add(int left, int right);
}
DART

cat > "$playground/lua/tlconfig.lua" <<'LUA'
return {
  source_dir = "src",
  build_dir = "build",
  include = { "**/*.tl" },
  gen_target = "5.3",
  gen_compat = "off",
}
LUA

cat > "$playground/lua/src/demo.tl" <<'TEAL'
local bridge = require("demo_bridge")

local implementation: bridge.DemoApi = {
  add = function(left: integer, right: integer): integer
    return left + right
  end,
}

return bridge.bindDemoApi(implementation)
TEAL

cat > "$playground/bin/demo.dart" <<'DART'
import 'dart:io';

import 'package:flutter_lua_bridge/flutter_lua_bridge.dart';

import '../lib/demo.g.dart';

void main() {
  final runtime = LuaRuntime.create();
  try {
    final source = File('playground/lua/build/demo.lua').readAsStringSync();
    final api = DemoApi.load(runtime: runtime, source: source);
    final result = api.add(20, 22);
    switch (result) {
      case LuaSuccess(value: final value):
        print('O1 success: $value');
      case LuaFailure(kind: final kind, message: final message):
        print('O1 failure: $kind $message');
    }
  } finally {
    runtime.close();
  }
}
DART

cat > "$playground/README.md" <<'MD'
# Local playground

This directory is generated and ignored by Git. Recreate it from the repository
root with:

```sh
./tool/create_playground.sh
```

The script generates a minimal O1 contract, compiles `demo.tl` with Cyan (or
falls back to `tl gen` when Cyan is unavailable), and leaves the generated Dart
and Lua files under this directory.

Run the result from the repository root:

```sh
dart run playground/bin/demo.dart
```

The expected output is `O1 success: 42`. Change `demo.tl` to return a string or
raise an error to observe the generated type and `pcall` error results.
MD

cd "$repo_root"
dart --suppress-analytics run flutter_lua_bridge_codegen --input playground/bridge/demo.dart

if command -v cyan >/dev/null 2>&1; then
  (cd "$playground/lua" && cyan build)
elif command -v tl >/dev/null 2>&1; then
  tl_command=$(command -v tl)
  if ! "$tl_command" --help >/dev/null 2>&1; then
    printf '%s\n' 'Install Cyan or Teal first: luarocks --lua-version=5.4 install cyan 0.4.1-1' >&2
    exit 127
  fi
  (cd "$playground/lua" && "$tl_command" gen -I src --gen-target 5.3 --gen-compat off -o build/demo.lua src/demo.tl)
else
  printf '%s\n' 'Install Cyan or Teal first: luarocks --lua-version=5.4 install cyan 0.4.1-1' >&2
  exit 127
fi

printf '%s\n' "Created $playground"
