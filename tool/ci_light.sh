#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

dart_cmd=${DART_CMD:-dart}
if ! command -v "$dart_cmd" >/dev/null 2>&1; then
  printf '%s\n' "${dart_cmd} is required; install Flutter/Dart before running the light CI." >&2
  exit 127
fi

"$dart_cmd" --suppress-analytics analyze --fatal-infos
(cd packages/flutter_lua_bridge_codegen_annotation && "$dart_cmd" --suppress-analytics test)
(cd packages/flutter_lua_bridge_codegen && "$dart_cmd" --suppress-analytics test test/generator_test.dart)
(cd packages/flutter_lua_bridge_codegen && "$dart_cmd" --suppress-analytics test test/model_test.dart)
(cd packages/flutter_lua_bridge && "$dart_cmd" --suppress-analytics test test/codecs_test.dart)

for contract in bridge/basic_api.dart bridge/scenarios.dart bridge/battle.dart; do
  (cd example && "$dart_cmd" --suppress-analytics run flutter_lua_bridge_codegen --input "$contract" --check)
done

if command -v flutter >/dev/null 2>&1; then
  (cd example && flutter test test/game/card_loader_test.dart)
else
  printf '%s\n' 'flutter is unavailable; skipped the example unit test.' >&2
fi

printf '%s\n' 'Light CI checks passed.'
