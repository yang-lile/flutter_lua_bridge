// lib/display_list_renderer.dart
//
// 显示列表 -> Flutter Canvas 的批量渲染。
//
// 这是整个架构里唯一接触 Flutter 绘制 API 的文件。
// 上层（Lua）完全不知道它的存在。

import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flutter/painting.dart'
    show TextPainter, TextDirection, TextSpan, TextStyle;

import 'display_list.dart';

/// 把显示列表画到 Canvas 上。
///
/// 性能要点：
///   1. Paint 对象按 (颜色, 描边宽度) 复用，避免每个图元新建
///   2. Path 按类型缓存
///   3. TextPainter 复用，只在文本变化时重建
class DisplayListRenderer {
  DisplayListRenderer();

  final Map<int, ui.Paint> _paintCache = {};
  final Map<int, ui.Path> _pathCache = {};
  final Map<String, TextPainter> _textCache = {};

  /// 上一帧的显示列表，用于判断是否需要重绘。
  DisplayList? _lastList;

  /// 内容是否与上一帧不同。仅用于诊断与统计。
  ///
  /// **注意：这个方法不参与绘制决策。** 早先的 `render()` 拿它做提前
  /// return，结果窗口拖动（容器尺寸变化、显示列表没变）时整帧被跳过，
  /// 画布变空白。内容没变只意味着缓存可复用，绘制仍必须执行——
  /// 那是 Flutter 通过 [CustomPainter.shouldRepaint] 管的另一层事。
  bool needsRepaint(DisplayList? next) {
    if (next == null) return false;
    if (_lastList == null) return true;
    return !_lastList!.sameAs(next);
  }

  /// 统计信息，用于诊断。
  int renderCount = 0;
  int skippedCount = 0;

  /// 把显示列表画到 [size] 给定的画布上。
  ///
  /// [size] 是画布的像素尺寸，由宿主按 [scale] 算好后传进来。
  /// [scale] 是"1 个逻辑像素 -> 多少屏幕像素"。
  ///
  /// **1:1 是默认且推荐的做法。** 显示列表的坐标就是像素坐标，
  /// scale = 1 时每个逻辑像素对应一个物理像素，所见即所得。
  /// 放大只是给"看不清细节"时的辅助手段，由用户手动拖滑条控制。
  ///
  /// [drawFrame] 画一圈画布边界，让画布范围一目了然。
  /// 这里**不用棋盘底**——每帧几千个 drawRect 会把 UI 拖死，
  /// 边界线已经足够说明画布在哪。
  void render(
    ui.Canvas canvas,
    ui.Size size,
    DisplayList list, {
    double scale = 1.0,
    bool drawFrame = true,
  }) {
    if (size.width <= 0 || size.height <= 0) return;
    if (scale <= 0 || !scale.isFinite) return;

    final logicalW = list.width > 0 ? list.width : 1.0;
    final logicalH = list.height > 0 ? list.height : 1.0;

    // 画布原点固定在左上角，不做居中——居中会在容器尺寸变化时
    // 让画布"飘"，而左上角锚定更符合"画布"的直觉。
    canvas.save();
    canvas.clipRect(ui.Rect.fromLTWH(0, 0, size.width, size.height));

    // 逻辑坐标 -> 物理坐标
    canvas.scale(scale);

    // 背景
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, logicalW, logicalH),
      _fillPaint(list.background),
    );

    // 按顺序遍历图元，保证 z-order
    for (final op in list.ops) {
      switch (op.type) {
        case OpType.circle:
          _renderCircle(canvas, op);
        case OpType.rect:
          _renderRect(canvas, op);
        case OpType.line:
          _renderLine(canvas, op);
        case OpType.text:
          _renderText(canvas, op);
        case OpType.polygon:
          _renderPolygon(canvas, op);
      }
    }

    canvas.restore();

    // 边界线画在物理坐标上，保证 1px 不会被缩放放大
    if (drawFrame) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, size.width - 1, size.height - 1),
        _framePaint,
      );
    }

    _lastList = list;
    renderCount++;
  }

  /// 画布边界线。半透明，不遮挡内容。
  late final ui.Paint _framePaint = ui.Paint()
    ..color = const Color(0xFF4A5160)
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 1.0;

  // ============ 各图元渲染 ============

  void _renderCircle(ui.Canvas canvas, DrawOp op) {
    final center = ui.Offset(op.x ?? 0, op.y ?? 0);
    final radius = op.r ?? 0;
    if (radius <= 0) return;

    if (op.fill != null) {
      canvas.drawCircle(center, radius, _fillPaint(parseColor(op.fill!)));
    }
    if (op.stroke != null && (op.strokeWidth ?? 0) > 0) {
      canvas.drawCircle(
        center,
        radius,
        _strokePaint(parseColor(op.stroke!), op.strokeWidth!),
      );
    }
  }

  void _renderRect(ui.Canvas canvas, DrawOp op) {
    final rect = ui.Rect.fromLTWH(
      op.x ?? 0,
      op.y ?? 0,
      op.w ?? 0,
      op.h ?? 0,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    final rrect = ui.RRect.fromRectAndRadius(
      rect,
      ui.Radius.circular(op.radius ?? 0),
    );

    if (op.fill != null) {
      canvas.drawRRect(rrect, _fillPaint(parseColor(op.fill!)));
    }
    if (op.stroke != null && (op.strokeWidth ?? 0) > 0) {
      canvas.drawRRect(
        rrect,
        _strokePaint(parseColor(op.stroke!), op.strokeWidth!),
      );
    }
  }

  void _renderLine(ui.Canvas canvas, DrawOp op) {
    canvas.drawLine(
      ui.Offset(op.x1 ?? 0, op.y1 ?? 0),
      ui.Offset(op.x2 ?? 0, op.y2 ?? 0),
      _strokePaint(parseColor(op.stroke ?? '#ffffff'), op.strokeWidth ?? 1),
    );
  }

  void _renderPolygon(ui.Canvas canvas, DrawOp op) {
    final pts = op.points;
    if (pts == null || pts.length < 2) return;

    final path = ui.Path();
    if (pts.length >= 3) {
      // 闭合多边形，可以填充
      path.moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
    } else {
      // 两点：退化为折线
      path.moveTo(pts[0].dx, pts[0].dy);
      path.lineTo(pts[1].dx, pts[1].dy);
    }

    if (op.fill != null) {
      canvas.drawPath(path, _fillPaint(parseColor(op.fill!)));
    }
    if (op.stroke != null && (op.strokeWidth ?? 0) > 0) {
      canvas.drawPath(
        path,
        _strokePaint(parseColor(op.stroke!), op.strokeWidth!),
      );
    }
  }

  void _renderText(ui.Canvas canvas, DrawOp op) {
    final text = op.text;
    if (text == null || text.isEmpty) return;

    // 缓存键包含内容与样式，命中即复用。
    // 用 TextPainter 而非底层 Paragraph：Paragraph.paint 在
    // Flutter 3.44 已不再是公开 API，TextPainter 是官方绘制路径。
    final key = '${op.text}|${op.size}|${op.color}|${op.align}';
    final painter = _textCache[key] ??= _buildTextPainter(
      text,
      size: op.size ?? 14,
      color: parseColor(op.color ?? '#ffffff'),
      align: _alignOf(op.align),
    );

    // 按对齐方式反推绘制原点
    final x = op.x!;
    final y = op.y!;
    final dx = switch (op.align ?? 'left') {
      'right' => x - painter.width,
      'center' => x - painter.width / 2,
      _ => x,
    };

    painter.paint(canvas, ui.Offset(dx, y - painter.height));
  }

  static ui.TextAlign _alignOf(String? align) {
    switch (align) {
      case 'right':
        return ui.TextAlign.right;
      case 'center':
        return ui.TextAlign.center;
      default:
        return ui.TextAlign.left;
    }
  }

  static TextPainter _buildTextPainter(
    String text, {
    required double size,
    required ui.Color color,
    required ui.TextAlign align,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
  }

  // ============ Paint 复用 ============

  /// 填充 Paint 缓存。颜色是最常见的区分维度。
  ui.Paint _fillPaint(ui.Color color) {
    final key = color.toARGB32();
    return _paintCache.putIfAbsent(key, () {
      return ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.fill
        ..isAntiAlias = true;
    });
  }

  /// 描边 Paint 缓存。key 组合颜色与描边宽度。
  ///
  /// [width] 是**逻辑坐标**下的宽度：渲染时已经 `canvas.scale(k)`，
  /// 所以屏幕上的实际线宽是 `width * k`。这是内容等比缩放应有的行为。
  ///
  /// 前提是所有图元用同一个 k——当前渲染器就是这样做的。
  /// 若将来支持"某条线固定屏幕像素宽"（比如网格线），
  /// key 必须加上 k，否则会命中错误的缓存。
  ui.Paint _strokePaint(ui.Color color, double width) {
    final key = (color.toARGB32() << 8) ^ width.toInt();
    return _paintCache.putIfAbsent(-key, () {
      return ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = width
        ..isAntiAlias = true
        ..strokeCap = ui.StrokeCap.round
        ..strokeJoin = ui.StrokeJoin.round;
    });
  }

  void dispose() {
    _paintCache.clear();
    _pathCache.clear();
    _textCache.clear();
  }
}