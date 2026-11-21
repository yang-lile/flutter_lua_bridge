#!/usr/bin/env bash
# Type checks and runs the Teal samples of the widget packages:
#
#   lua/test/*_test.tl       must pass (Teal check, then run on LuaRuntime);
#   lua/test_fail/*_test.tl  must be rejected by the Teal type checker with
#                            the message of its `-- expect:` line.
#
# Usage: tool/check_teal_ui.sh [package ...] (default: every widget package)
# Set DART_CMD to use another launcher, for example DART_CMD="fvm dart".
set -euo pipefail
dart_cmd=${DART_CMD:-dart}
root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $# -eq 0 ]]; then
  set -- packages/flutter_lua_bridge_ui packages/flutter_lua_bridge_ui_material packages/flutter_lua_bridge_ui_cupertino
fi
cd "$root/packages/flutter_lua_bridge_codegen"
status=0
for package in "$@"; do
  dir="$root/$package"
  [[ -d "$dir/lua/test" ]] || continue
  echo "== $package"
  $dart_cmd run flutter_lua_bridge_codegen:run "$dir/lua/test" || status=1
  for sample in "$dir"/lua/test_fail/*_test.tl; do
    [[ -e "$sample" ]] || continue
    expect="$(sed -n 's/^-- expect: //p' "$sample")"
    if [[ -z "$expect" ]]; then
      echo "FAIL ${sample#"$root/"} has no '-- expect:' line"
      status=1
    elif output="$($dart_cmd run flutter_lua_bridge_codegen:run "$sample" 2>&1)"; then
      echo "FAIL ${sample#"$root/"} passed, but must be rejected by Teal"
      status=1
    elif grep -E '\.tl:[0-9]+:[0-9]+: ' <<<"$output" | grep -qF -- "$expect"; then
      echo "ok   ${sample#"$root/"} rejected: $(grep -m1 -E '\.tl:[0-9]+:[0-9]+: ' <<<"$output" | sed 's/.*\.tl:[0-9]*:[0-9]*: //')"
    else
      echo "FAIL ${sample#"$root/"} failed without the Teal error \"$expect\":"
      echo "$output"
      status=1
    fi
  done
done
exit "$status"
