#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FLUTTER="${FLUTTER:-flutter}"
MODE="${1:-debug}"

case "$MODE" in
  debug) CONFIGURATION="Debug" ;;
  release) CONFIGURATION="Release" ;;
  profile) CONFIGURATION="Profile" ;;
  *)
    echo "用法：bash tools/build_macos.sh [debug|release|profile]" >&2
    exit 2
    ;;
esac

if [ "${SKIP_PUB_GET:-0}" != "1" ]; then
  "$FLUTTER" pub get
fi

# Flutter 负责生成 ephemeral 配置；Xcode 27 下直接使用 workspace 会被误判为
# 非 workspace，因此后续改用两个 xcodeproj 依次构建。
"$FLUTTER" build macos --"$MODE" --config-only --no-pub

if ! command -v pod >/dev/null 2>&1; then
  echo "pod is required to build the macOS example" >&2
  exit 127
fi

(
  cd macos
  pod install --no-repo-update
)

FLUTTER_ROOT_VALUE="${FLUTTER_ROOT:-}"
if [ -z "$FLUTTER_ROOT_VALUE" ] && [[ "$FLUTTER" == */bin/flutter ]]; then
  FLUTTER_ROOT_VALUE="${FLUTTER%/bin/flutter}"
fi

DERIVED_DATA="$ROOT/build/macos"
PODS_FRAMEWORK_DIR="$ROOT/macos/build/$CONFIGURATION"
COMMON_ARGS=(
  -configuration "$CONFIGURATION"
  -destination 'generic/platform=macOS'
  -derivedDataPath "$DERIVED_DATA"
  MACOSX_DEPLOYMENT_TARGET=13.0
  CODE_SIGNING_ALLOWED=NO
)
if [ -n "$FLUTTER_ROOT_VALUE" ]; then
  COMMON_ARGS+=(FLUTTER_ROOT="$FLUTTER_ROOT_VALUE")
fi

xcodebuild \
  -project "$ROOT/macos/Pods/Pods.xcodeproj" \
  -scheme Pods-Runner \
  "${COMMON_ARGS[@]}" \
  build

xcodebuild \
  -project "$ROOT/macos/Runner.xcodeproj" \
  -scheme Runner \
  "${COMMON_ARGS[@]}" \
  FRAMEWORK_SEARCH_PATHS="$PODS_FRAMEWORK_DIR" \
  build

APP="$DERIVED_DATA/Build/Products/$CONFIGURATION/flutter_lua_bridge_example.app"
if [ ! -d "$APP" ]; then
  echo "构建产物缺失：$APP" >&2
  exit 1
fi

echo "构建成功：$APP"
