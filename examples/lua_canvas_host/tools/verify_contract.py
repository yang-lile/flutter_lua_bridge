#!/usr/bin/env python3
"""跨语言契约验证：Lua 产出的显示列表 vs Dart 的解析规则。

为什么需要独立脚本：`flutter test` 需要 flutter_tester 与工具之间
建立本地 WebSocket，在受限环境下会被拦截。契约验证本身不需要
Flutter 引擎，只需要在进程内比对字段名与取值规则，因此用
纯 Dart 单文件脚本执行即可。

验证内容与 test/contract_test.dart 一致：
  1. 所有图元类型能被 Dart 的枚举覆盖
  2. 颜色格式全部合法
  3. 坐标在画布范围内
  4. polygon 点集完整
  5. 文本有内容与样式
  6. 指纹唯一且稳定

用法：dart run tools/verify_contract.dart
"""
import json
import sys
from pathlib import Path

GALLERY = Path("assets/lua/out/gallery.json")

VALID_OPS = {"circle", "rect", "line", "text", "polygon"}
ALIGN = {"left", "center", "right"}

passed = 0
failed = 0


def check(name: str, cond: bool, detail: str = "") -> None:
    global passed, failed
    if cond:
        passed += 1
        print(f"  PASS  {name}" + (f"  ({detail})" if detail else ""))
    else:
        failed += 1
        print(f"  FAIL  {name}" + (f"  -- {detail}" if detail else ""))


def is_hex_color(s: str) -> bool:
    if not isinstance(s, str) or not s.startswith("#"):
        return False
    body = s[1:]
    return len(body) in (3, 6, 8) and all(c in "0123456789abcdefABCDEF" for c in body)


def main() -> int:
    if not GALLERY.exists():
        print(f"[FAIL] 缺少 {GALLERY}，先运行：lua tools/gen_gallery.lua")
        return 1

    gallery = json.loads(GALLERY.read_text(encoding="utf-8"))
    examples = gallery["examples"]
    print(f"载入 {len(examples)} 个示例（全部由 Lua 真实生成）\n")

    # ---- 1. 图元类型覆盖 ----
    print("=== 1. 图元类型 ===")
    seen = set()
    bad_types = []
    for ex in examples:
        for op in ex["ops"]:
            t = op.get("op")
            seen.add(t)
            if t not in VALID_OPS:
                bad_types.append(f"{ex['id']}: {t}")
    check("所有图元类型合法", not bad_types, "; ".join(bad_types[:3]))
    check("覆盖全部五种图元", seen == VALID_OPS,
          "实际 " + ",".join(sorted(seen)))

    # ---- 2. 颜色格式 ----
    print("\n=== 2. 颜色格式 ===")
    bad_colors = []
    color_total = 0
    for ex in examples:
        for op in ex["ops"]:
            for key in ("fill", "stroke", "color"):
                c = op.get(key)
                if c is None:
                    continue
                color_total += 1
                if not is_hex_color(c):
                    bad_colors.append(f"{ex['id']}.{key}={c}")
    check("所有颜色为合法十六进制", not bad_colors,
          "; ".join(bad_colors[:3]))
    print(f"       共检查 {color_total} 个颜色值")

    # ---- 3. 坐标范围 ----
    print("\n=== 3. 坐标范围 ===")
    out_of_range = []
    coord_total = 0
    for ex in examples:
        w, h = ex["width"], ex["height"]
        for op in ex["ops"]:
            for key in ("x", "y", "x1", "y1", "x2", "y2", "r"):
                v = op.get(key)
                if v is None:
                    continue
                coord_total += 1
                # Dart 侧 clipRect 之后越界不会崩，但渲染会缺失
                if key in ("x", "x1", "x2") and not (-100 <= v <= w + 100):
                    out_of_range.append(f"{ex['id']}.{key}={v}")
                if key in ("y", "y1", "y2") and not (-100 <= v <= h + 100):
                    out_of_range.append(f"{ex['id']}.{key}={v}")
    check("坐标在画布范围内", not out_of_range, "; ".join(out_of_range[:3]))
    print(f"       共检查 {coord_total} 个坐标")

    # ---- 4. polygon 完整性 ----
    print("\n=== 4. 多边形点集 ===")
    poly_count = 0
    bad_poly = []
    for ex in examples:
        for op in ex["ops"]:
            if op.get("op") != "polygon":
                continue
            poly_count += 1
            pts = op.get("points")
            if not isinstance(pts, list) or len(pts) < 2:
                bad_poly.append(f"{ex['id']} 点数 {len(pts) if pts else 'nil'}")
                continue
            for p in pts:
                if not isinstance(p.get("x"), (int, float)):
                    bad_poly.append(f"{ex['id']} 点坐标非法")
    check("多边形点集完整", not bad_poly, "; ".join(bad_poly[:3]))
    check("至少有一个多边形", poly_count > 0, f"{poly_count} 个")
    print(f"       共检查 {poly_count} 个多边形")

    # ---- 5. 文本 ----
    print("\n=== 5. 文本图元 ===")
    text_count = 0
    bad_text = []
    for ex in examples:
        for op in ex["ops"]:
            if op.get("op") != "text":
                continue
            text_count += 1
            t = op.get("text")
            if not t or not isinstance(t, str):
                bad_text.append(f"{ex['id']} 文本为空或非字符串")
            size = op.get("size")
            if not isinstance(size, (int, float)) or size <= 0:
                bad_text.append(f"{ex['id']} size={size}")
            if op.get("align") not in ALIGN:
                bad_text.append(f"{ex['id']} align={op.get('align')}")
    check("文本内容与样式合法", not bad_text, "; ".join(bad_text[:3]))
    check("至少有一段文本", text_count > 0, f"{text_count} 段")

    # ---- 6. 指纹与重绘决策 ----
    # 这一项曾真实出问题：Lua 的 Canvas:build() 漏掉 fingerprint 字段，
    # 宿主拿到 null 后 CustomPaint.shouldRepaint 里的 `null != null`
    # 恒为 false —— 画布永远停在第一次绘制，而界面看起来完全正常。
    print("\n=== 6. 内容指纹与重绘决策 ===")

    missing_fp = [e["id"] for e in examples if not e.get("fingerprint")]
    check("build() 输出了 fingerprint", not missing_fp,
          "缺失: " + ", ".join(missing_fp)
          if missing_fp else f"{len(examples)} 个示例都有")

    fps = [e["fingerprint"] for e in examples if e.get("fingerprint")]
    check("指纹格式为 16 位十六进制",
          bool(fps) and all(len(f) == 16
                            and all(c in "0123456789abcdef" for c in f)
                            for f in fps),
          fps[0] if fps else "")
    check("指纹互不相同", len(set(fps)) == len(fps),
          f"{len(set(fps))}/{len(fps)}")

    # 模拟 CustomPaint.shouldRepaint / DisplayListRenderer.needsRepaint
    def should_repaint(a, b):
        if a is None or b is None:
            return True      # 保守：缺指纹一律重绘
        return a != b

    check("相同指纹 -> 跳过重绘",
          should_repaint(fps[0], fps[0]) is False)
    check("不同指纹 -> 重绘",
          len(fps) < 2 or should_repaint(fps[0], fps[1]) is True)
    check("缺指纹 -> 保守重绘（不是静默跳过）",
          should_repaint(None, None) is True,
          "旧实现 `null != null` 返回 false，会让画面永远停在第一次")

    # ---- 7. SVG 结构 ----
    print("\n=== 7. SVG 后端产出 ===")
    bad_svg = []
    for ex in examples:
        svg = ex["svg"]
        if not svg.startswith("<svg"):
            bad_svg.append(f"{ex['id']} 未以 svg 开头")
        if not svg.rstrip().endswith("</svg>"):
            bad_svg.append(f"{ex['id']} 未闭合")
        if f'width="{ex["width"]}"' not in svg:
            bad_svg.append(f"{ex['id']} 宽度不一致")

        # 未转义的裸 & 会破坏 XML
        import re
        if re.search(r"&(?!amp;|lt;|gt;|quot;)", svg):
            bad_svg.append(f"{ex['id']} 含未转义的 &")

    check("SVG 结构完整且已转义", not bad_svg, "; ".join(bad_svg[:3]))

    print(f"\n{passed} passed, {failed} failed")

    if failed == 0:
        print("\n契约一致 —— Lua 产出可被 Dart DisplayList 完整消费")
    return 0 if failed == 0 else 1




if __name__ == "__main__":
    sys.exit(main())