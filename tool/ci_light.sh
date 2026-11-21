#!/usr/bin/env sh
# The lightweight gate: analyzer, generator tests, generated artifact drift,
# the example's Lua entries, its game tests, the Teal samples of the widget
# packages and the tests of the widget and remote packages.
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
# The Teal worker tests need a process of their own; see dart_test.yaml.
(cd packages/flutter_lua_bridge_codegen && $dart_cmd --suppress-analytics test \
  -P teal-worker)
# The example's Lua side on its own (lua/test), without Flutter.
(cd examples/flutter_lua_bridge_example && $dart_cmd --suppress-analytics run \
  flutter_lua_bridge_codegen:run)

# The Teal samples of the widget packages: lua/test must type check and
# run, lua/test_fail must be rejected by Teal.
DART_CMD="$dart_cmd" ./tool/check_teal_ui.sh

# Layering of the widget packages (see AGENTS.md): the core layer uses only
# package:flutter/widgets.dart; Cupertino never pulls Material; nothing uses
# rfw. check_layer <package> <forbidden package names, |-separated>.
check_layer() {
  package=packages/$1
  if grep -rnE "package:($2)/" "$package/lib" ||
    grep -nE "^  ($2):" "$package/pubspec.yaml"; then
    printf '%s\n' "$package must not depend on $2." >&2
    exit 1
  fi
}
check_layer flutter_lua_bridge_ui 'material_ui|cupertino_ui|rfw'
check_layer flutter_lua_bridge_ui_cupertino 'material_ui|rfw'
check_layer flutter_lua_bridge_ui_material 'rfw'
check_layer flutter_lua_bridge_remote 'material_ui|cupertino_ui|rfw'
if grep -rnE "package:flutter/(material|cupertino)\.dart" packages/flutter_lua_bridge_ui*/lib packages/flutter_lua_bridge_remote/lib; then
  printf '%s\n' 'Widget packages import material_ui or cupertino_ui, not flutter/material.dart or flutter/cupertino.dart.' >&2
  exit 1
fi

if command -v "${flutter_cmd%% *}" >/dev/null 2>&1; then
  (cd examples/flutter_lua_bridge_example && $flutter_cmd test test/game)
  for package in flutter_lua_bridge_ui flutter_lua_bridge_ui_material \
    flutter_lua_bridge_ui_cupertino flutter_lua_bridge_remote; do
    (cd "packages/$package" && $flutter_cmd test)
  done
else
  printf '%s\n' 'flutter is unavailable; skipped the example game tests and the widget package tests.' >&2
fi

printf '%s\n' 'Light CI checks passed.'
