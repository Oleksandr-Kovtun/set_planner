import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';

class DrawingPainter extends CustomPainter {
  final List<DrawnItem> items;
  final int? selectedIndex;
  final Set<int> selection;
  final Rect? marquee;
  final double scale;
  final Offset offset;
  final Color selectionColor;
  final Color rotationHandleColor;
  final int? editingId;

  DrawingPainter(
    this.items, {
    this.selectedIndex,
    this.selection = const {},
    this.marquee,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.selectionColor = Colors.blue,
    this.rotationHandleColor = Colors.green,
    this.editingId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    for (final item in items) {
      if (item.id == editingId) continue; // редагується на канвасі — малює overlay
      _drawItem(canvas, item);
    }
    _drawMultiHighlight(canvas);
    _drawSelection(canvas);
    _drawMarquee(canvas);
    canvas.restore();
  }

  void _withRotation(Canvas canvas, DrawnItem item, VoidCallback draw) {
    final rotate = item.rotation != 0 && item.points.length >= 2;
    if (rotate) {
      final c = item.bounds.center;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(item.rotation);
      canvas.translate(-c.dx, -c.dy);
    }
    draw();
    if (rotate) canvas.restore();
  }

  void _drawItem(Canvas canvas, DrawnItem item) {
    _withRotation(canvas, item, () {
      final stroke = Paint()
        ..color = item.strokeColor
        ..strokeWidth = item.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final fill = item.fillColor == null
          ? null
          : (Paint()..color = item.fillColor!..style = PaintingStyle.fill);
      final pts = item.points;

      switch (item.tool) {
        case Tool.select:
        case Tool.lasso:
          break;
        case Tool.pen:
          if (pts.length < 2) break;
          if (item.smoothed) {
            _drawSmoothCurve(canvas, stroke, pts);
          } else {
            final path = Path()..moveTo(pts.first.dx, pts.first.dy);
            for (int i = 1; i < pts.length; i++) {
              path.lineTo(pts[i].dx, pts[i].dy);
            }
            canvas.drawPath(path, stroke);
          }
        case Tool.line:
          if (pts.length > 2) {
            _drawSmoothCurve(canvas, stroke, pts);
          } else {
            canvas.drawLine(pts[0], pts[1], stroke);
          }
        case Tool.rectangle:
          final r = Rect.fromPoints(pts[0], pts[1]);
          if (fill != null) canvas.drawRect(r, fill);
          canvas.drawRect(r, stroke);
        case Tool.ellipse:
          final r = Rect.fromPoints(pts[0], pts[1]);
          if (fill != null) canvas.drawOval(r, fill);
          canvas.drawOval(r, stroke);
        case Tool.triangle:
          final path = _trianglePath(pts[0], pts[1]);
          if (fill != null) canvas.drawPath(path, fill);
          canvas.drawPath(path, stroke);
        case Tool.arrow:
          _drawArrow(canvas, stroke, pts,
              headStart: item.arrowHeadStart, headEnd: item.arrowHeadEnd);
        case Tool.star:
          final path = _starPath(pts[0], pts[1]);
          if (fill != null) canvas.drawPath(path, fill);
          canvas.drawPath(path, stroke);
        case Tool.svg:
          final pic = item.svgPicture;
          final sz = item.svgSize;
          if (pic != null && sz != null && sz.width > 0 && sz.height > 0) {
            final r = Rect.fromPoints(pts[0], pts[1]);
            canvas.save();
            canvas.translate(r.left, r.top);
            canvas.scale(r.width / sz.width, r.height / sz.height);
            canvas.drawPicture(pic);
            canvas.restore();
          }
        case Tool.svgPath:
          final sp = item.svgPath;
          final nb = item.svgPathBounds;
          if (sp != null && nb != null && nb.width > 0 && nb.height > 0) {
            final box = Rect.fromPoints(pts[0], pts[1]);
            canvas.save();
            canvas.translate(box.left, box.top);
            canvas.scale(box.width / nb.width, box.height / nb.height);
            canvas.translate(-nb.left, -nb.top);
            if (item.fillColor != null) {
              canvas.drawPath(sp,
                  Paint()..color = item.fillColor!..style = PaintingStyle.fill);
            }
            if (item.strokeWidth > 0) {
              canvas.drawPath(
                  sp,
                  Paint()
                    ..color = item.strokeColor
                    ..strokeWidth = item.strokeWidth
                    ..style = PaintingStyle.stroke);
            }
            canvas.restore();
          }
          case Tool.image:
          final img = item.image;
          if (img != null) {
            final dst = Rect.fromPoints(pts[0], pts[1]);
            final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
            canvas.drawImageRect(
              img,
              src,
              dst,
              Paint()
                ..filterQuality = FilterQuality.medium
                ..color = Color.fromRGBO(255, 255, 255, item.opacity),
            );
          }
          case Tool.text:
          final tp = TextPainter(
            text: TextSpan(
              text: item.text ?? '',
              style: TextStyle(
                color: item.strokeColor,
                fontSize: item.fontSize,
                fontWeight: item.bold ? FontWeight.bold : FontWeight.normal,
                fontStyle: item.italic ? FontStyle.italic : FontStyle.normal,
                fontFamily: item.fontFamily,
              ),
            ),
            textAlign: item.textAlign,
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, item.bounds.topLeft);
          
      }
    });
  }

  // Підсвічування кількох вибраних елементів + спільна рамка.
  void _drawMultiHighlight(Canvas canvas) {
    if (selection.length < 2) return;
    final thin = Paint()
      ..color = selectionColor
      ..strokeWidth = 1.0 / scale
      ..style = PaintingStyle.stroke;
    Rect? combined;
    for (final i in selection) {
      if (i < 0 || i >= items.length) continue;
      final item = items[i];
      _withRotation(canvas, item, () {
        canvas.drawRect(item.bounds.inflate(2), thin);
      });
      combined = combined == null
          ? item.visualBounds
          : combined.expandToInclude(item.visualBounds);
    }
    if (combined == null) return;

    final box = combined.inflate(selectionPadding);
    final boxPaint = Paint()
      ..color = selectionColor
      ..strokeWidth = 1.5 / scale
      ..style = PaintingStyle.stroke;
    canvas.drawRect(box, boxPaint);

    // ручка обертання групи
    final rot = Offset(box.center.dx, box.top - 24 / scale);
    canvas.drawLine(Offset(box.center.dx, box.top), rot, boxPaint);
    canvas.drawCircle(rot, 6 / scale, Paint()..color = rotationHandleColor);

    // 8 ручок пропорційного розміру
    final fill = Paint()..color = selectionColor;
    for (final f in boxHandleFactors) {
      canvas.drawCircle(
        Offset(box.left + f.dx * box.width, box.top + f.dy * box.height),
        5 / scale,
        fill,
      );
    }
  }

  void _drawSelection(Canvas canvas) {
    final i = selectedIndex;
    if (i == null || i >= items.length) return;
    final item = items[i];
    if (item.points.length < 2) return;

    _withRotation(canvas, item, () {
      final selBox = item.bounds.inflate(selectionPadding);
      final center = item.bounds.center;
      final box = Paint()
        ..color = item.locked ? const Color(0xFF9E9E9E) : selectionColor
        ..strokeWidth = 1.5 / scale
        ..style = PaintingStyle.stroke;
      canvas.drawRect(selBox, box);
      if (item.locked) return; // заблоковано — без ручок повороту/розміру

      final handleBase = Offset(center.dx, selBox.top);
      final rotPoint = Offset(center.dx, selBox.top - 24 / scale);
      canvas.drawLine(handleBase, rotPoint, box);
      canvas.drawCircle(rotPoint, 6 / scale, Paint()..color = rotationHandleColor);

      final fill = Paint()..color = selectionColor;
      if (item.tool != Tool.text) {
        if (toolIsBox(item.tool)) {
          for (final f in boxHandleFactors) {
            final pos = Offset(
              selBox.left + f.dx * selBox.width,
              selBox.top + f.dy * selBox.height,
            );
            canvas.drawCircle(pos, 5 / scale, fill);
          }
        } else {
          for (final p in item.points) {
            canvas.drawCircle(p, 5 / scale, fill);
          }
        }
      }
    });
  }

  void _drawMarquee(Canvas canvas) {
    final m = marquee;
    if (m == null) return;
    final r = Rect.fromLTRB(
      math.min(m.left, m.right),
      math.min(m.top, m.bottom),
      math.max(m.left, m.right),
      math.max(m.top, m.bottom),
    );
    canvas.drawRect(
        r, Paint()..color = selectionColor.withValues(alpha: 0.12)..style = PaintingStyle.fill);
    canvas.drawRect(
        r,
        Paint()
          ..color = selectionColor
          ..strokeWidth = 1.0 / scale
          ..style = PaintingStyle.stroke);
  }

  void _drawSmoothCurve(Canvas canvas, Paint paint, List<Offset> pts) {
    if (pts.length < 2) return;
    if (pts.length == 2) {
      canvas.drawLine(pts[0], pts[1], paint);
      return;
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final p0 = (i == 0) ? pts[0] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = (i + 2 < pts.length) ? pts[i + 2] : pts[i + 1];
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(path, paint);
  }

  Path _trianglePath(Offset a, Offset b) {
    final rect = Rect.fromPoints(a, b);
    return Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..close();
  }

  void _drawArrow(Canvas canvas, Paint paint, List<Offset> pts,
      {bool headStart = false, bool headEnd = true}) {
    if (pts.length < 2) return;
    if (pts.length > 2) {
      _drawSmoothCurve(canvas, paint, pts);
    } else {
      canvas.drawLine(pts[0], pts[1], paint);
    }
    if (headEnd) {
      _drawArrowHead(canvas, paint, pts[pts.length - 2], pts[pts.length - 1]);
    }
    if (headStart) {
      _drawArrowHead(canvas, paint, pts[1], pts[0]);
    }
  }

  void _drawArrowHead(Canvas canvas, Paint paint, Offset from, Offset to) {
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    const headLength = 14.0, headAngle = 0.5;
    final p1 = to - Offset(headLength * math.cos(angle - headAngle),
        headLength * math.sin(angle - headAngle));
    final p2 = to - Offset(headLength * math.cos(angle + headAngle),
        headLength * math.sin(angle + headAngle));
    canvas.drawLine(to, p1, paint);
    canvas.drawLine(to, p2, paint);
  }

  Path _starPath(Offset a, Offset b) {
    final rect = Rect.fromPoints(a, b);
    final cx = rect.center.dx, cy = rect.center.dy;
    final outer = math.min(rect.width, rect.height) / 2;
    final inner = outer * 0.4;
    const count = 5;
    final path = Path();
    for (int i = 0; i < count * 2; i++) {
      final r = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / count;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}