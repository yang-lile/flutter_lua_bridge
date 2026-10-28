#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

cd "$repo_root/example"
dart run flutter_lua_bridge_codegen --input bridge/basic_api.dart
dart run flutter_lua_bridge_codegen --input bridge/scenarios.dart
dart run flutter_lua_bridge_codegen --input bridge/battle.dart

"$repo_root/tool/build_teal.sh"
