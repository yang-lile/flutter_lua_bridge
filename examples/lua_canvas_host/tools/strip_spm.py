#!/usr/bin/env python3
"""从 project.pbxproj 精确移除 FlutterGeneratedPluginSwiftPackage。

pbxproj 是 OpenStep plist，所有条目都以 "ID = {" 开头、"= {" 或
"," 结尾的独立行或多行块。安全做法是逐行判断，只删两类：

  1. 容器里纯引用条目（形如 `\t\t\t\t78A318202AECB46A00862997 /* ... */,`）
  2. section 内的完整对象块（从 `\t\tID /* ... */ = {` 到 `\t\t};`）

绝不整段删 section 标记，Begin/End 配对必须保持。
执行后用 plutil -lint 校验格式，失败立即从备份恢复。

用法：python3 tools/strip_spm.py
"""
import shutil
import subprocess
import sys
from pathlib import Path

PBX = Path("macos/Runner.xcodeproj/project.pbxproj")
MARKER = "FlutterGeneratedPluginSwiftPackage"


def is_object_start(line: str) -> bool:
    """形如 `\t\t78A3... /* name */ = {`"""
    return " = {" in line


def strip(lines: list[str]) -> tuple[list[str], int]:
    out: list[str] = []
    i = 0
    removed = 0

    while i < len(lines):
        line = lines[i]

        # 情况 A：section 内的对象块，含 SPM
        if MARKER in line and is_object_start(line):
            # 找到匹配的结束行 "};"（pbxproj 缩进固定为两个 tab）
            j = i + 1
            while j < len(lines) and lines[j].strip() != "};":
                j += 1
            i = j + 1
            removed += 1
            continue

        # 情况 B：任何其他含 SPM 的行（容器引用、单行对象）
        if MARKER in line:
            i += 1
            removed += 1
            continue

        out.append(line)
        i += 1

    return out, removed


def main() -> int:
    if not PBX.exists():
        print(f"[SKIP] {PBX} 不存在")
        return 0

    original = PBX.read_text(encoding="utf-8")
    if MARKER not in original:
        print("[SKIP] 没有 SPM 引用")
        return 0

    backup = PBX.with_suffix(".pbxproj.bak")
    shutil.copy2(PBX, backup)
    print(f"[BAK] {backup}")

    lines = original.splitlines(keepends=True)
    kept, removed = strip(lines)
    result = "".join(kept)

    PBX.write_text(result, encoding="utf-8")
    print(f"[OK] 移除 {removed} 个条目  {len(original)} -> {len(result)} 字节")

    # 立即校验；格式不对就回滚
    check = subprocess.run(
        ["plutil", "-lint", str(PBX)],
        capture_output=True, text=True,
    )
    if "OK" not in check.stdout:
        print("[ERR] 格式校验失败，回滚", file=sys.stderr)
        shutil.copy2(backup, PBX)
        print(check.stdout, check.stderr, file=sys.stderr)
        return 1

    # section 配对校验
    begins = result.count("/* Begin ") + result.count("/* Begin\t")
    begins = result.count("section */")
    if result.count("/* Begin") != result.count("/* End"):
        print("[ERR] section 配对损坏，回滚", file=sys.stderr)
        shutil.copy2(backup, PBX)
        return 1

    print(f"[OK] 格式校验通过，section 配对 {begins // 2} 对")
    return 0


if __name__ == "__main__":
    sys.exit(main())