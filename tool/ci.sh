#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

if ! command -v dart >/dev/null 2>&1; then
  printf '%s\n' 'dart is required; install Flutter/Dart before running CI.' >&2
  exit 127
fi

dart_cmd=${DART_CMD:-dart}

"$dart_cmd" --suppress-analytics analyze --fatal-infos

(cd packages/flutter_lua_bridge_codegen && "$dart_cmd" --suppress-analytics test test/generator_test.dart)
(cd packages/flutter_lua_bridge_codegen && "$dart_cmd" --suppress-analytics test test/model_test.dart)
(cd packages/flutter_lua_bridge && "$dart_cmd" --suppress-analytics test \
  test/codecs_test.dart test/runtime_test.dart)

for contract in bridge/basic_api.dart bridge/scenarios.dart bridge/battle.dart; do
  (cd examples/flutter_lua_bridge_example && "$dart_cmd" --suppress-analytics run flutter_lua_bridge_codegen --input "$contract" --check)
done

(cd packages/flutter_lua_bridge && \
  "$dart_cmd" --suppress-analytics run flutter_lua_bridge_codegen \
    --input test/fixtures/values.dart --check)

if ! command -v cyan >/dev/null 2>&1; then
  printf '%s\n' 'cyan is required; install with: luarocks --lua-version=5.4 install cyan 0.4.1-1' >&2
  exit 127
fi
(cd examples/flutter_lua_bridge_example/lua && cyan build)

if ! command -v python3 >/dev/null 2>&1; then
  printf '%s\n' 'python3 is required for native bridge checks.' >&2
  exit 127
fi
python3 packages/flutter_lua_bridge/tool/test_native.py

if command -v flutter >/dev/null 2>&1; then
  (cd examples/flutter_lua_bridge_example && flutter test \
    test/bridge \
    test/scenarios \
    test/widget_test.dart \
    test/game/card_loader_test.dart)
else
  printf '%s\n' 'flutter is unavailable; skipped Flutter example tests.' >&2
fi

printf '%s\n' 'Local CI checks passed.'
