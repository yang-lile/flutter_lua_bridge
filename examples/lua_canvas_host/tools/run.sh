#!/usr/bin/env bash
#
# 构建并启动 macOS 版 Lua Canvas Studio。
#
# 与旧版的根本区别：
#   Lua SDK  —— 由 flutter_lua_bridge 的 code assets 自动构建并打包
#   Lua 代码 —— 由 pubspec.yaml 的 assets 声明自动打包
# 所以这里不需要编译 dylib、导出符号、拷贝 Frameworks、注入 Resources，
# 也不需要重签名。只有 Xcode 工程的环境适配是手工的。
#
# 用法：
#   bash tools/run.sh              # 构建 + 启动（默认）
#   bash tools/run.sh --build-only # 只构建不启动
#   bash tools/run.sh --debug     # 用 debug 模式构建并启动

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FLUTTER="${FLUTTER:-flutter}"

BUILD_ONLY=0
MODE="release"

for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=1 ;;
    --debug)      MODE="debug" ;;
    -h|--help)
      # 跳过 shebang（从第 3 行开始），只取注释里的用法
      sed -n '3,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "未知参数：$arg"
      echo "用法：bash tools/run.sh [--build-only] [--debug]"
      exit 1
      ;;
  esac
done

echo "==> 1/4 校验并同步 Lua 模块清单"
# manifest 是单一数据源：pubspec 的 assets 声明由它生成。
# 不一致会导致打包后 require 不到模块，且只在运行时暴露。
bash tools/check_manifest.sh
bash tools/gen_assets.sh

echo "==> 2/4 适配 Xcode 工程"
python3 tools/fix_xcode_project.py

echo "==> 3/4 构建 [$MODE]"
FLUTTER="$FLUTTER" bash tools/build_macos.sh "$MODE"

if [ "$MODE" = "release" ]; then
  APP="$ROOT/build/macos/Build/Products/Release/lua_canvas_studio.app"
else
  APP="$ROOT/build/macos/Build/Products/Debug/lua_canvas_studio.app"
fi

if [ ! -d "$APP" ]; then
  echo "构建产物缺失：$APP"
  exit 1
fi

echo "==> 4/4 验证打包内容"
# SDK 与 Lua 脚本都由 Flutter 自动打包，这里只做确认。
SDK=$(find "$APP" -name "*flutter_lua_bridge*" 2>/dev/null | wc -l | tr -d ' ')
LUA=$(find "$APP" -name "manifest.txt" 2>/dev/null | wc -l | tr -d ' ')
echo "  SDK 文件: $SDK 个"
echo "  Lua 清单: $LUA 个"

if [ "$BUILD_ONLY" = "1" ]; then
  echo
  echo "构建完成（未启动）"
  echo "启动：open \"$APP\""
  exit 0
fi

echo
echo "==> 启动"
# 先关掉旧实例，避免窗口或状态残留
pkill -f lua_canvas_studio 2>/dev/null || true
sleep 1

open "$APP"

# 等进程真的活下来，而不是 open 一返回就报成功
for i in $(seq 1 20); do
  sleep 1
  if pgrep -f lua_canvas_studio >/dev/null 2>&1; then
    echo "✓ 已启动（${i}s）"
    exit 0
  fi
done

echo "✗ 启动后 20 秒内进程未存活"
echo "  崩溃日志：ls -t ~/Library/Logs/DiagnosticReports/lua_canvas_studio*.ips | head -1"
exit 1
