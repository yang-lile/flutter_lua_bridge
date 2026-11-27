#!/usr/bin/env sh
# The full release gate, split into stages that CI runs as parallel jobs:
#
#   ./tool/ci.sh                  # every stage, in order
#   ./tool/ci.sh native versions  # selected stages
#
#   light     ci_light.sh (analyzer, builders with drift check, generator,
#             example Lua and widget package tests), plus the runtime tests,
#             on the default Lua release
#   native    C tests of the flb shim with ASan/UBSan on every bundled Lua
#             (needs clang and python3, not Dart)
#   versions  runtime, generator, example Lua, widget and remote package
#             tests on the other bundled Lua releases
#   example   Flutter tests of the example app
#
# Teal is compiled by the bundled tl.lua, so no Lua toolchain is required.
# Set DART_CMD / FLUTTER_CMD to use another launcher, for example
# DART_CMD="fvm dart" FLUTTER_CMD="fvm flutter".
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

dart_cmd=${DART_CMD:-dart}
flutter_cmd=${FLUTTER_CMD:-flutter}

require() {
  if ! command -v "${1%% *}" >/dev/null 2>&1; then
    printf '%s\n' "${1%% *} is required for the $2 stage." >&2
    exit 127
  fi
}

stage_light() {
  DART_CMD="$dart_cmd" FLUTTER_CMD="$flutter_cmd" ./tool/ci_light.sh
  (cd packages/flutter_lua_bridge && $dart_cmd --suppress-analytics test)
}

stage_native() {
  require python3 native
  python3 packages/flutter_lua_bridge/tool/test_native.py
}

stage_versions() {
  require "$dart_cmd" versions
  DART_CMD="$dart_cmd" FLUTTER_CMD="$flutter_cmd" \
    ./tool/test_lua_versions.sh --skip-default
}

stage_example() {
  require "$flutter_cmd" example
  (cd examples/flutter_lua_bridge_example && $flutter_cmd test \
    test/bridge \
    test/scenarios \
    test/widget_test.dart)
}

if [ "$#" -eq 0 ]; then
  set -- light native versions example
fi
for stage in "$@"; do
  case "$stage" in
    light | native | versions | example) ;;
    *)
      printf '%s\n' "Unknown stage: $stage" >&2
      exit 64
      ;;
  esac
done
for stage in "$@"; do
  printf '%s\n' "== $stage"
  "stage_$stage"
done

printf '%s\n' "CI stages passed: $*"
