#!/usr/bin/env python3
"""修正 macOS Xcode 工程，使其能在受限环境下构建。

两处必要调整：

1. 移除 FlutterGeneratedPluginSwiftPackage（Swift Package Manager）
   SPM 依赖 xcodebuild 的 sandbox-exec 解析包依赖，在受限环境里报
   "sandbox_apply: Operation not permitted"。本项目的 Lua 动态库是
   手动链接的、不依赖任何插件，因此这个包（只做插件注册）可以去掉。

   注意 pbxproj 里的条目有两种形态：
     - 单行引用（容器内的 "ID /* name */,"）—— 删整行
     - 多行对象（"ID /* name */ = {" 到 "};"）—— 连块一起删
   绝不能整段删 section 标记，否则 Xcode 报 "not a valid property list"。

2. 把 MACOSX_DEPLOYMENT_TARGET 从 10.15 抬到 13.0
   Xcode 27 最低支持 12.0，10.15 会直接构建失败。

执行后立即用 plutil 校验，失败自动回滚。

用法：python3 tools/fix_xcode_project.py
"""
import shutil
import subprocess
import sys
from pathlib import Path

PBX = Path("macos/Runner.xcodeproj/project.pbxproj")
MARKER = "FlutterGeneratedPluginSwiftPackage"


def validate(path: Path) -> tuple[bool, str]:
    """校验 pbxproj 格式与 section 配对。"""
    proc = subprocess.run(["plutil", "-lint", str(path)],
                          capture_output=True, text=True)
    if "OK" not in proc.stdout:
        return False, (proc.stdout + proc.stderr).strip()

    text = path.read_text(encoding="utf-8")
    begins = text.count("/* Begin")
    ends = text.count("/* End")
    if begins != ends:
        return False, f"section 配对损坏：{begins} Begin vs {ends} End"

    return True, f"格式合法，section 配对 {begins // 2} 对"


def strip_spm(lines: list[str]) -> tuple[list[str], int]:
    """移除 SPM 条目，识别单行与多行两种形态。"""
    out: list[str] = []
    i = 0
    removed = 0

    while i < len(lines):
        line = lines[i]

        # 多行对象：包含 SPM 且以 " = {" 结尾
        if MARKER in line and line.rstrip().endswith("= {"):
            j = i + 1
            while j < len(lines) and lines[j].strip() != "};":
                j += 1
            i = j + 1
            removed += 1
            continue

        # 其余含 SPM 的行（容器引用、单行对象）
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
    result = original

    # ---- 步骤 1：移除 SPM ----
    if MARKER in result:
        backup = PBX.with_suffix(".pbxproj.bak")
        shutil.copy2(PBX, backup)

        kept, removed = strip_spm(result.splitlines(keepends=True))
        result = "".join(kept)
        PBX.write_text(result, encoding="utf-8")

        ok, msg = validate(PBX)
        if not ok:
            print(f"[ERR] SPM 移除后格式损坏，回滚：{msg}", file=sys.stderr)
            shutil.copy2(backup, PBX)
            return 1

        print(f"[OK] 移除 {removed} 个 SPM 条目  "
              f"{len(original)} -> {len(result)} 字节")
        print(f"     {msg}")
    else:
        print("[SKIP] 无 SPM 引用")

    # ---- 步骤 2：抬部署目标 ----
    if "MACOSX_DEPLOYMENT_TARGET = 10.15;" in result:
        n = result.count("MACOSX_DEPLOYMENT_TARGET = 10.15;")
        result = result.replace(
            "MACOSX_DEPLOYMENT_TARGET = 10.15;",
            "MACOSX_DEPLOYMENT_TARGET = 13.0;",
        )
        PBX.write_text(result, encoding="utf-8")

        ok, msg = validate(PBX)
        if not ok:
            print(f"[ERR] 部署目标修改后格式损坏，回滚：{msg}",
                  file=sys.stderr)
            shutil.copy2(PBX.with_suffix(".pbxproj.bak"), PBX)
            return 1

        print(f"[OK] 部署目标 10.15 -> 13.0（{n} 处）")
    else:
        print("[SKIP] 部署目标已是 13.0+")

    return 0


if __name__ == "__main__":
    sys.exit(main())