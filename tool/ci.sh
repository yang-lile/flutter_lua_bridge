#!/usr/bin/env sh
# The full release gate. It needs Dart/Flutter, a C compiler and python3;
# Teal is compiled by the bundled tl.lua, so no Lua toolchain is required.
#
# Set DART_CMD / FLUTTER_CMD to use another launcher, for example
# DART_CMD="fvm dart" FLUTTER_CMD="fvm flutter".
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

dart_cmd=${DART_CMD:-dart}
flutter_cmd=${FLUTTER_CMD:-flutter}
if ! command -v "${dart_cmd%% *}" >/dev/null 2>&1; then
  printf '%s\n' "${dart_cmd%% *} is required; install Flutter/Dart before running CI." >&2
  exit 127
fi

$dart_cmd --suppress-analytics analyze --fatal-infos

(cd packages/flutter_lua_bridge_codegen_annotation && $dart_cmd --suppress-analytics test)
(cd packages/flutter_lua_bridge && $dart_cmd --suppress-analytics test)

# Runs the builders, including the Teal compiler, and fails on drift.
DART_CMD="$dart_cmd" ./tool/generate_example.sh --check
(cd packages/flutter_lua_bridge_codegen && $dart_cmd --suppress-analytics test)

if ! command -v python3 >/dev/null 2>&1; then
  printf '%s\n' 'python3 is required for native bridge checks.' >&2
  exit 127
fi
python3 packages/flutter_lua_bridge/tool/test_native.py
DART_CMD="$dart_cmd" ./tool/test_lua_versions.sh

if command -v "${flutter_cmd%% *}" >/dev/null 2>&1; then
  (cd examples/flutter_lua_bridge_example && $flutter_cmd test \
    test/bridge \
    test/scenarios \
    test/widget_test.dart \
    test/game/card_loader_test.dart)
else
  printf '%s\n' 'flutter is unavailable; skipped Flutter example tests.' >&2
fi

printf '%s\n' 'Local CI checks passed.'
