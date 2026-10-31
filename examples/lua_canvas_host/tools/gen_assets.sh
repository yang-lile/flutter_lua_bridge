#!/usr/bin/env bash
#
# 根据 assets/lua/manifest.txt 生成 pubspec.yaml 的 assets 声明。
#
# 为什么要生成而不是手写：
#   Lua 模块是普通文件，rootBundle.loadString 必须按具体路径读取，
#   所以 pubspec 里要逐个列出。列表来源就是 manifest.txt——
#   单一数据源，避免两处维护导致遗漏。
#
# 实现方式：用显式边界标记（ASSETS_BLOCK_BEGIN/END）定位替换范围。
# 不依赖正则猜格式，改动脚本也不会误伤 pubspec 的其他内容。
#
# 用法：bash tools/gen_assets.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MANIFEST="assets/lua/manifest.txt"
PUBSPEC="pubspec.yaml"
BEGIN="# ASSETS_BLOCK_BEGIN"
END="# ASSETS_BLOCK_END"

[ -f "$MANIFEST" ] || { echo "[ERR] 缺少 $MANIFEST"; exit 1; }
[ -f "$PUBSPEC" ] || { echo "[ERR] 缺少 $PUBSPEC"; exit 1; }

# 确认清单里的文件都存在
while read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || { echo "[ERR] 清单中的文件不存在：$f"; exit 1; }
done < <(grep -vE '^[[:space:]]*(#|$)' "$MANIFEST")

python3 - "$BEGIN" "$END" <<'PY'
import sys
from pathlib import Path

begin, end = sys.argv[1], sys.argv[2]

manifest = Path('assets/lua/manifest.txt')
pubspec = Path('pubspec.yaml')

files = {'assets/lua/manifest.txt'}
for raw in manifest.read_text(encoding='utf-8').splitlines():
    line = raw.strip()
    if line and not line.startswith('#'):
        files.add(line)

block = '\n'.join([
    f'  {begin}',
    '  # Lua 模块清单与各模块文件。',
    '  # 由 tools/gen_assets.sh 从 assets/lua/manifest.txt 生成，勿手改。',
    '  assets:',
    *[f'    - {f}' for f in sorted(files)],
    f'  {end}',
    '',
])

lines = pubspec.read_text(encoding='utf-8').splitlines(keepends=True)

# 找边界标记；缺失则在文件末尾追加
try:
    i = next(n for n, l in enumerate(lines) if begin in l)
    j = next(n for n, l in enumerate(lines) if end in l and n >= i)
except StopIteration:
    i = j = None

new = block + '\n'
if i is not None and j is not None:
    out = lines[:i] + [new] + lines[j + 1:]
    action = '已替换'
else:
    out = lines + ['\n', new]
    action = '已追加'

pubspec.write_text(''.join(out), encoding='utf-8')
print(f'{action} assets 块，共 {len(files)} 项')
PY

count=$(grep -cE '^[[:space:]]+- assets/lua/' "$PUBSPEC" || true)
echo "[OK] pubspec 现声明 $count 项"