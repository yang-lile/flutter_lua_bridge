// lib/display_list.dart
//
// 显示列表的数据模型。这是 Lua 与 Flutter 之间唯一的契约。
//
// 设计要点：整个模型是纯数据，没有任何 Flutter 类型。
// 这让 Lua 侧和 Dart 侧的测试都能脱离渲染引擎运行。

import 'dart:ui' show Color, Offset;

import 'deep_equality.dart';

/// 图元类型。与 Lua 侧 Canvas.OP 一一对应。
enum OpType { circle, rect, line, text, polygon }

/// 解析图元类型，兼容 Lua 传来的字符串。
OpType parseOpType(String raw) {
  switch (raw) {
    case 'circle':
      return OpType.circle;
    case 'rect':
      return OpType.rect;
    case 'line':
      return OpType.line;
    case 'text':
      return OpType.text;
    case 'polygon':
      return OpType.polygon;
    default:
      throw ArgumentError('unknown op type: $raw');
  }
}

/// 颜色解析：接受 #rrggbb / #aarrggbb / 常见 CSS 命名。
///
/// 优先用 dart:ui 的 Color 构造，它比 Flutter MaterialColor 轻。
Color parseColor(String hex, {Color fallback = const Color(0xFF000000)}) {
  var s = hex.trim();
  if (s.startsWith('#')) s = s.substring(1);

  if (s.length == 6) {
    final v = int.tryParse('ff$s', radix: 16);
    return v == null ? fallback : Color(v);
  }
  if (s.length == 8) {
    final v = int.tryParse(s, radix: 16);
    return v == null ? fallback : Color(v);
  }
  if (s.length == 3) {
    // #abc -> #aabbcc
    final expanded = s.split('').map((c) => '$c$c').join();
    final v = int.tryParse('ff$expanded', radix: 16);
    return v == null ? fallback : Color(v);
  }
  return fallback;
}

/// 文本对齐方式。
enum TextAlignMode { left, center, right }

/// 一个绘制指令。
///
/// 字段是可选的，因为不同op 用不同子集。
/// 这是刻意的：可选字段让 JSON 编解码保持扁平，Dart 侧解析也更快。
class DrawOp {
  final OpType type;

  // circle / rect / text
  final double? x, y, w, h, r, size;

  // line
  final double? x1, y1, x2, y2;

  // rect
  final double? radius, strokeWidth;

  // text
  final String? text;
  final String? align;

  // polygon
  final List<Offset>? points;

  final String? fill, stroke, color;

  const DrawOp({
    required this.type,
    this.x,
    this.y,
    this.w,
    this.h,
    this.r,
    this.size,
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.radius,
    this.strokeWidth,
    this.text,
    this.align,
    this.points,
    this.fill,
    this.stroke,
    this.color,
  });

  factory DrawOp.fromJson(Map<String, dynamic> j) {
    List<Offset>? pts;
    final rawPts = j['points'];
    if (rawPts is List) {
      pts = rawPts
          .cast<Map>()
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList(growable: false);
    }

    double? d(String k) => (j[k] as num?)?.toDouble();

    return DrawOp(
      type: parseOpType(j['op'] as String),
      x: d('x'),
      y: d('y'),
      w: d('w'),
      h: d('h'),
      r: d('r'),
      size: d('size'),
      x1: d('x1'),
      y1: d('y1'),
      x2: d('x2'),
      y2: d('y2'),
      radius: d('radius'),
      strokeWidth: d('stroke_width'),
      text: j['text'] as String?,
      align: j['align'] as String?,
      points: pts,
      fill: j['fill'] as String?,
      stroke: j['stroke'] as String?,
      color: j['color'] as String?,
    );
  }
}

/// 完整的一帧显示列表。
class DisplayList {
  final int version;
  final double width, height;
  final Color background;
  final List<DrawOp> ops;

  /// Lua 侧算出的内容指纹。
  ///
  /// **只当 O(1) 快路径用** —— 它是哈希，会碰撞。
  /// 最终判断由 [sameAs] 里的结构比较做。
  final String? fingerprint;

  /// 从 JSON 解析出来的**原始结构**（已去掉 `fingerprint`）。
  ///
  /// 去掉是因为它是从内容**派生**出来的：内容相同而指纹不同是完全可能的
  /// （哈希碰撞，或者 Lua 侧换了指纹实现）。留着它的话，
  /// "内容相同"这个判断永远不成立。
  ///
  /// 比较发生在它上面而不是 [ops] 上，两个原因：
  ///   1. `DrawOp` 用 `dart:ui` 的 Color/Offset，纯 Dart VM 跑不起来
  ///      （本项目的已知环境限制），而原始 JSON 是纯 Dart 的，
  ///      所以 `tools/verify_change_detect.dart` 能完整覆盖这一层。
  ///   2. 不用为比较再解析一遍，也就没有"两套解析规则不一致"的风险。
  final Map<String, dynamic> raw;

  const DisplayList({
    required this.version,
    required this.width,
    required this.height,
    required this.background,
    required this.ops,
    this.fingerprint,
    this.raw = const {},
  });

  factory DisplayList.fromJson(Map<String, dynamic> j) {
    final rawOps = (j['ops'] as List?) ?? const [];
    return DisplayList(
      version: (j['version'] as num?)?.toInt() ?? 1,
      width: (j['width'] as num).toDouble(),
      height: (j['height'] as num).toDouble(),
      background: parseColor(j['background'] as String? ?? '#000000'),
      ops: rawOps
          .cast<Map<String, dynamic>>()
          .map(DrawOp.fromJson)
          .toList(growable: false),
      fingerprint: j['fingerprint'] as String?,
      // 剥掉派生字段（指纹由内容算出，不参与内容比较）
      raw: contentOf(j),
    );
  }

  /// 内容是否与上一帧相同。
  ///
  /// 与 UI 侧同一个思路（见 `ui_tree.dart` 的 `uiTreeEquals`）：
  /// **指纹只当 O(1) 快路径，结构比较才是权威。**
  ///
  /// 以前只看指纹，而指纹是 Lua 侧算的哈希——哈希会碰撞，
  /// 碰撞的表现是**静默漏渲染**：画面停住不更新，且没有任何报错。
  ///
  /// 缺指纹时（比如 Lua 侧刚升级、还没跑过一帧）一律当作"变了"：
  /// 宁可多渲染一帧，也不能漏掉这次更新。
  bool sameAs(DisplayList? other) {
    if (other == null) return false;

    if (fingerprint != null &&
        other.fingerprint != null &&
        fingerprint == other.fingerprint) {
      return true;
    }

    // 指纹不同只说明"可能变了"。结构相同就放过，
    // 这样即使哈希碰撞也不会白白重建 / 漏更新。
    return deepEquals(raw, other.raw);
  }

  /// 与另一帧的第一处差异，写进 [out]。诊断用。
  List<String> diffFrom(DisplayList other) {
    final out = <String>[];
    findFirstDifference(raw, other.raw, 'displayList', out);
    return out;
  }
}