#!/usr/bin/env bash
#
# 校验 assets/lua/manifest.txt 与实际文件是否一致。
#
# 为什么需要：manifest 是 Lua 模块的唯一索引，
# Flutter assets 不会递归列目录，靠它决定打包哪些文件。
# 如果清单漏了模块，运行时才会报 require 不到——太晚。
#
# 用法：bash tools/check_manifest.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MANIFEST="assets/lua/manifest.txt"

if [ ! -f "$MANIFEST" ]; then
  echo "[ERR] 缺少 $MANIFEST"
  exit 1
fi

# 清单里声明的模块
declared=$(grep -vE '^\s*(#|$)' "$MANIFEST" | sort)

# 磁盘上应存在的模块（排除不该打包的）
actual=$(cd assets/lua && find . -name "*.lua" \
  ! -name "bootstrap.lua" \
  ! -name "demo.lua" \
  ! -path "./spec/*" \
  | sed 's|^\./|assets/lua/|' | sort)

missing=$(comm -23 <(echo "$actual") <(echo "$declared"))
extra=$(comm -13 <(echo "$actual") <(echo "$declared"))

status=0

if [ -n "$missing" ]; then
  echo "[ERR] 磁盘上有但清单里没有（打包后会require 失败）："
  echo "$missing" | sed 's/^/  /'
  status=1
fi

if [ -n "$extra" ]; then
  echo "[ERR] 清单里有但磁盘上没有（构建会报错）："
  echo "$extra" | sed 's/^/  /'
  status=1
fi

if [ $status -eq 0 ]; then
  count=$(echo "$declared" | wc -l | tr -d ' ')
  echo "[OK] 清单一致，$count 个模块"
fi

exit $status