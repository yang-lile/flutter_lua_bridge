#!/usr/bin/env bash
# Scores the publishable packages with pana, the analysis behind the pub.dev
# score, and fails unless every package gets full points. Run it before
# publishing:
#
#   ./tool/pana.sh                      # every package
#   ./tool/pana.sh flutter_lua_bridge   # some of them
#
# Each package is packed exactly as `dart pub publish` uploads it and analysed
# alone, outside the workspace. pana resolves dependencies through
# tool/pana_repository.dart, a local repository that adds the packed versions
# to pub.dev's, so packages released together see each other's new versions.
# It listens on PANA_PORT (default 8765); a fixed port keeps its downloads in
# one pub cache directory. Set DART_CMD to use another launcher; it defaults
# to `fvm dart` when fvm is installed. The full report of a package is printed
# when it misses points.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${DART_CMD:-}" ]]; then
  dart_cmd="$DART_CMD"
elif command -v fvm >/dev/null 2>&1; then
  dart_cmd="fvm dart"
else
  dart_cmd="dart"
fi

all=(flutter_lua_bridge_codegen_annotation flutter_lua_bridge flutter_lua_bridge_codegen)
if (($#)); then selected=("$@"); else selected=("${all[@]}"); fi

work="$(mktemp -d "${TMPDIR:-/tmp}/flb-pana.XXXXXX")"
trap 'rm -rf "$work"' EXIT

echo "Activating pana"
$dart_cmd --suppress-analytics pub global activate pana >"$work/activate.log" 2>&1 ||
  { cat "$work/activate.log"; exit 1; }

for package in "${all[@]}"; do
  log="$work/$package.pack.log"
  # --to-archive writes the upload to a file instead of sending it.
  if ! (cd "$root/packages/$package" &&
    $dart_cmd --suppress-analytics pub publish --to-archive="$work/$package.tar.gz" \
      </dev/null >"$log" 2>&1); then
    cat "$log"
    echo "Packing $package failed" >&2
    exit 1
  fi
  mkdir "$work/$package"
  tar -xzf "$work/$package.tar.gz" -C "$work/$package"
  # The packed pubspec still says `resolution: workspace`.
  sed -i.bak '/^resolution: workspace/d' "$work/$package/pubspec.yaml"
  rm "$work/$package/pubspec.yaml.bak"
done

port="${PANA_PORT:-8765}"
dirs=()
for package in "${all[@]}"; do dirs+=("$work/$package"); done
(cd "$root" && exec $dart_cmd --suppress-analytics run tool/pana_repository.dart \
  "$port" "${dirs[@]}") >"$work/repository.log" 2>&1 &
repository=$!
stop_repository() {
  # A launcher such as fvm runs the server as a child: stop the server itself.
  local pid
  pid="$(sed -n 's/^Listening on .* pid \([0-9]*\)$/\1/p' "$work/repository.log")"
  kill ${pid:+"$pid"} "$repository" 2>/dev/null || true
}
trap 'stop_repository; rm -rf "$work"' EXIT
until grep -q '^Listening on' "$work/repository.log"; do
  if ! kill -0 "$repository" 2>/dev/null; then
    cat "$work/repository.log"
    echo "The local package repository did not start" >&2
    exit 1
  fi
  sleep 0.2
done
export PUB_HOSTED_URL="http://127.0.0.1:$port"

flutter_args=()
if [[ -d "$root/.fvm/flutter_sdk" ]]; then
  flutter_args=(--flutter-sdk "$root/.fvm/flutter_sdk")
fi

failed=()
for package in "${selected[@]}"; do
  echo "== $package"
  report="$work/$package.pana.txt"
  if $dart_cmd --suppress-analytics pub global run pana --no-warning \
    --exit-code-threshold 0 --hosted-url "$PUB_HOSTED_URL" "${flutter_args[@]}" \
    "$work/$package" \
    >"$report" 2>&1; then
    grep -E '^## |^Points:' "$report"
  else
    cat "$report"
    failed+=("$package")
  fi
done

if ((${#failed[@]})); then
  echo "Missing pana points: ${failed[*]}" >&2
  exit 1
fi
