#!/usr/bin/env sh
# The lightweight gate: analyzer, generator tests, generated artifact drift
# and a small example unit test.
#
# Set DART_CMD / FLUTTER_CMD to use another launcher, for example
# DART_CMD="fvm dart" FLUTTER_CMD="fvm flutter".
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

dart_cmd=${DART_CMD:-dart}
flutter_cmd=${FLUTTER_CMD:-flutter}
if ! command -v "${dart_cmd%% *}" >/dev/null 2>&1; then
  printf '%s\n' "${dart_cmd%% *} is required; install Flutter/Dart before running the light CI." >&2
  exit 127
fi

$dart_cmd --suppress-analytics analyze --fatal-infos
(cd packages/flutter_lua_bridge_codegen_annotation && $dart_cmd --suppress-analytics test)
(cd packages/flutter_lua_bridge && $dart_cmd --suppress-analytics test test/codecs_test.dart)

# Runs the builders, including the Teal compiler, and fails on drift.
DART_CMD="$dart_cmd" ./tool/generate_example.sh --check
(cd packages/flutter_lua_bridge_codegen && $dart_cmd --suppress-analytics test)

if command -v "${flutter_cmd%% *}" >/dev/null 2>&1; then
  (cd examples/flutter_lua_bridge_example && $flutter_cmd test test/game/card_loader_test.dart)
else
  printf '%s\n' 'flutter is unavailable; skipped the example unit test.' >&2
fi

printf '%s\n' 'Light CI checks passed.'
