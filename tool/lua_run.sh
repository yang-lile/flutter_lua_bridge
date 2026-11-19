#!/usr/bin/env sh
# Runs Lua and Teal entries with `flutter_lua_bridge_codegen:run`; the
# VS Code tasks in .vscode/tasks.json call it.
#
#   tool/lua_run.sh                       # the example's lua/test
#   tool/lua_run.sh path/to/x_test.tl     # one file (any package)
#   tool/lua_run.sh path/to/dir           # main.tl|lua and *_test.tl|lua below it
#   tool/lua_run.sh --watch path -- args  # options and `--` args pass through
#
# The command runs in the package that contains the first target, so error
# locations are short paths such as lua/test/x_test.tl:3 (Lua shortens long
# chunk names) that the editor can resolve. Set DART_CMD to choose the
# launcher; it defaults to `fvm dart` when fvm is installed.
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if [ -n "${DART_CMD:-}" ]; then
  dart_cmd=$DART_CMD
elif command -v fvm >/dev/null 2>&1; then
  dart_cmd="fvm dart"
else
  dart_cmd=dart
fi

# The first argument that is not an option and comes before `--`.
target=
for argument in "$@"; do
  case "$argument" in
    --) break ;;
    -*) ;;
    *) target=$argument; break ;;
  esac
done
if [ -z "$target" ]; then
  target=$repo_root/examples/flutter_lua_bridge_example/lua/test
  set -- "$@" "$target"
fi

# Nearest directory with a pubspec.yaml at or above the target.
dir=$(CDPATH= cd -- "$(dirname -- "$target")" && pwd)
[ -d "$target" ] && dir=$(CDPATH= cd -- "$target" && pwd)
while [ "$dir" != / ] && [ ! -f "$dir/pubspec.yaml" ]; do
  dir=$(dirname -- "$dir")
done
[ -f "$dir/pubspec.yaml" ] || dir=$repo_root

# Make file arguments absolute before changing directory.
for argument in "$@"; do
  shift
  if [ "$argument" != "${argument#-}" ] || [ ! -e "$argument" ]; then
    set -- "$@" "$argument"
  else
    case "$argument" in
      /*) set -- "$@" "$argument" ;;
      *) set -- "$@" "$PWD/$argument" ;;
    esac
  fi
done

cd "$dir"
exec $dart_cmd --suppress-analytics run flutter_lua_bridge_codegen:run "$@"
