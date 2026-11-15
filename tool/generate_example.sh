#!/usr/bin/env sh
# Regenerates every generated artifact in the repository with build_runner:
# the example app and the fixtures of the code generator tests.
#
#   tool/generate_example.sh           # regenerate
#   tool/generate_example.sh --check   # regenerate and fail on drift
#
# Set DART_CMD to use another launcher, for example DART_CMD="fvm dart".
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

dart_cmd=${DART_CMD:-dart}
check=false
if [ "${1:-}" = "--check" ]; then
  check=true
fi

example=examples/flutter_lua_bridge_example
fixtures=packages/flutter_lua_bridge_codegen/test/fixtures

# Every path the builders write to.
snapshot() {
  {
    find "$example/lib/bridge" "$fixtures" -maxdepth 1 -name '*.g.dart'
    find "$example/lua/types" "$example/assets/lua" \
      "$fixtures/lua/types" "$fixtures/lua/out" -type f
  } 2>/dev/null | LC_ALL=C sort | while read -r file; do
    printf '%s %s\n' "$(cksum < "$file")" "$file"
  done
}

before=$(snapshot)
for package in "$example" packages/flutter_lua_bridge_codegen; do
  (cd "$package" && $dart_cmd --suppress-analytics run build_runner build)
done

if $check; then
  after=$(snapshot)
  if [ "$before" != "$after" ]; then
    printf '%s\n' 'Generated files are out of date; run tool/generate_example.sh and commit the result.' >&2
    before_file=$(mktemp)
    after_file=$(mktemp)
    printf '%s\n' "$before" > "$before_file"
    printf '%s\n' "$after" > "$after_file"
    diff "$before_file" "$after_file" >&2 || true
    rm -f "$before_file" "$after_file"
    exit 1
  fi
  printf '%s\n' 'Generated files are up to date.'
fi
