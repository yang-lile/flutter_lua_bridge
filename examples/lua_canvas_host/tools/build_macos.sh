#!/usr/bin/env bash
#
# 构建 macOS 应用。
#
# Flutter 先生成 ephemeral 配置，Xcode 再直接构建 Runner.xcodeproj。
# 直接使用 project 可绕过部分 Xcode 版本无法解析 Flutter workspace
# 的问题；Flutter 的 native assets 和资源打包仍由 macOS assemble 阶段完成。

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
    echo "未知构建模式：$MODE" >&2
    echo "用法：bash tools/build_macos.sh [debug|release|profile]" >&2
    exit 2
    ;;
esac

echo "==> 解析依赖"
if [[ "${SKIP_PUB_GET:-0}" == "1" ]]; then
  echo "跳过 pub get（SKIP_PUB_GET=1）"
else
  "$FLUTTER" pub get
fi

echo "==> 生成 Flutter macOS 配置 [$MODE]"
"$FLUTTER" build macos --"$MODE" --config-only --no-pub

echo "==> 构建 Xcode project [$CONFIGURATION]"
XCODE_FLUTTER_ROOT="${FLUTTER_ROOT:-}"
if [[ -z "$XCODE_FLUTTER_ROOT" && "$FLUTTER" == */bin/flutter ]]; then
  XCODE_FLUTTER_ROOT="$(cd "$(dirname "$FLUTTER")/.." && pwd)"
fi

XCODE_ARGS=(
  -project "$ROOT/macos/Runner.xcodeproj" \
  -scheme Runner \
  -configuration "$CONFIGURATION" \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$ROOT/build/macos" \
)
if [[ -n "$XCODE_FLUTTER_ROOT" ]]; then
  XCODE_ARGS+=("FLUTTER_ROOT=$XCODE_FLUTTER_ROOT")
fi
XCODE_ARGS+=(CODE_SIGNING_ALLOWED=NO build)
xcodebuild "${XCODE_ARGS[@]}"
