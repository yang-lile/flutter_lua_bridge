#!/usr/bin/env sh
# Builds the native asset through hook/build.dart against each bundled Lua
# release and runs on it the runtime tests, the generator's end-to-end tests
# (which include compiling Teal with the bundled tl.lua), the example's Lua
# entries and, when Flutter is available, the example's basic bridge test and
# the flutter_lua_bridge_ui tests.
#
#   tool/test_lua_versions.sh                 # every release under third_party/
#   tool/test_lua_versions.sh 5.3.6 5.5.0     # selected releases
#   tool/test_lua_versions.sh --skip-default  # all but the hook's default line,
#                                             # which the plain test run covers
#
# Hook user-defines are only read from the workspace root pubspec.yaml, so the
# script appends a temporary `hooks:` block there and restores the file on
# exit. Every release is selected by release line (`lua_version`); the first
# one is also selected by local directory (`lua_source`), which checks that
# path end to end. The selection logic itself is unit tested in
# test/lua_source_test.dart, so repeating it for every release adds nothing.
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

dart_cmd=${DART_CMD:-dart}
flutter_cmd=${FLUTTER_CMD:-flutter}
example=examples/flutter_lua_bridge_example
package=packages/flutter_lua_bridge
codegen=packages/flutter_lua_bridge_codegen
ui=packages/flutter_lua_bridge_ui
pubspec=pubspec.yaml
backup=$(mktemp)
cp "$pubspec" "$backup"
trap 'cp "$backup" "$pubspec"; rm -f "$backup"' EXIT INT TERM

if grep -q '^hooks:' "$pubspec"; then
  printf '%s\n' "$pubspec already has a hooks: block; remove it before running this script." >&2
  exit 1
fi

# Keep in sync with the default of hook/build.dart.
default_line=5.4
skip_default=false
if [ "${1:-}" = "--skip-default" ]; then
  skip_default=true
  shift
fi

if [ "$#" -gt 0 ]; then
  releases=$*
else
  releases=$(cd "$package/third_party" && ls -d lua-* | sed 's/^lua-//')
fi
if $skip_default; then
  releases=$(for release in $releases; do
    [ "${release%.*}" = "$default_line" ] || printf '%s\n' "$release"
  done)
fi
if [ -z "$releases" ]; then
  printf '%s\n' 'No Lua release selected.' >&2
  exit 1
fi

run_with() {
  # $1: release, $2: user-define line
  cp "$backup" "$pubspec"
  printf '\nhooks:\n  user_defines:\n    flutter_lua_bridge:\n      %s\n' "$2" >> "$pubspec"
  printf '%s\n' "== Lua $1 ($2)"
  (cd "$package" && FLB_EXPECT_LUA_VERSION=$1 $dart_cmd --suppress-analytics test \
    test/lua_runtime_test.dart)
  (cd "$codegen" && $dart_cmd --suppress-analytics test \
    test/runtime_test.dart test/levels_test.dart)
  (cd "$codegen" && $dart_cmd --suppress-analytics test -P teal-worker)
  (cd "$example" && $dart_cmd --suppress-analytics run \
    flutter_lua_bridge_codegen:run)
  if command -v "${flutter_cmd%% *}" >/dev/null 2>&1; then
    (cd "$example" && $flutter_cmd test test/bridge/basic_bridge_test.dart)
    # The flb.ui Lua module relies on __len, __pairs and table library
    # metamethods, which differ between releases.
    (cd "$ui" && $flutter_cmd test)
  fi
}

first=true
for release in $releases; do
  if [ ! -f "$package/third_party/lua-$release/src/lua.h" ]; then
    printf '%s\n' "Lua $release is not bundled under $package/third_party." >&2
    exit 1
  fi
  if $first; then
    run_with "$release" "lua_source: $package/third_party/lua-$release"
    first=false
  fi
  run_with "$release" "lua_version: \"${release%.*}\""
done

printf '%s\n' "Runtime, generator and example tests passed on: $(printf '%s ' $releases)"
