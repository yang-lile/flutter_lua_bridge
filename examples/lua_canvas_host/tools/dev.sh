#!/usr/bin/env bash
#
# 本地调试：构建（debug）+ 启动。
#
# 为什么不直接用 `flutter run`：
#   `flutter run` 要连 VM service 的本地 socket，这个环境里连不上
#   （实测 "Error waiting for a debug connection"）。
#   但 debug 模式**构建**是好的 —— 直接 open 产物就能跑，
#   只是没有热重载。
#
# 改 Dart 代码 -> 重新跑本脚本
# 改 Lua 代码 -> 重新跑本脚本（Lua 通过 assets 打包，必须重打）
#
# 用法：
#   bash tools/dev.sh              # 构建 + 启动
#   bash tools/dev.sh --no-build   # 只启动，不重新构建
#   bash tools/dev.sh --release   # 用 release 模式（体积小、启动快）

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FLUTTER="${FLUTTER:-flutter}"
MODE="debug"
DO_BUILD=1

for arg in "$@"; do
  case "$arg" in
    --no-build) DO_BUILD=0 ;;
    --release) MODE="release" ;;
    -h|--help)
      sed -n '3,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "未知参数：$arg"
      echo "用法：bash tools/dev.sh [--no-build] [--release]"
      exit 1
      ;;
  esac
done

if [ "$DO_BUILD" = "1" ]; then
  # assets 声明必须与 manifest 同步，否则打包后 require 不到模块
  bash tools/check_manifest.sh
  bash tools/gen_assets.sh

  echo "==> 构建 [$MODE]"
  FLUTTER="$FLUTTER" bash tools/build_macos.sh "$MODE"
fi

if [ "$MODE" = "release" ]; then
  APP="$ROOT/build/macos/Build/Products/Release/lua_canvas_studio.app"
else
  APP="$ROOT/build/macos/Build/Products/Debug/lua_canvas_studio.app"
fi

if [ ! -d "$APP" ]; then
  echo "产物不存在：$APP"
  echo "先不带 --no-build 跑一次"
  exit 1
fi

echo "==> 启动"
pkill -f lua_canvas_studio 2>/dev/null || true
sleep 1
open "$APP"

for i in $(seq 1 15); do
  sleep 1
  if pgrep -f lua_canvas_studio >/dev/null 2>&1; then
    echo "✓ 运行中（${i}s）"
    exit 0
  fi
done

echo "✗ 20 秒内未存活"
echo "  崩溃日志：ls -t ~/Library/Logs/DiagnosticReports/lua_canvas_studio*.ips | head -1"
exit 1
