#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
project_dir="$repo_root/example/lua"

if ! command -v cyan >/dev/null 2>&1; then
  printf '%s\n' 'cyan is required; install it with: luarocks --lua-version=5.4 install cyan 0.4.1-1' >&2
  exit 127
fi

cd "$project_dir"
exec cyan build "$@"
