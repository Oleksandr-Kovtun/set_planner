import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'models.dart';
import 'models/settings.dart';
import 'l10n/app_strings.dart';

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
  final double gridSize;
  final bool showGrid;
  final bool showBigGrid;
  final DrawnItem? activePolyline;
  final Offset? polylineCursorPos;
  final Set<CameraInfoField> cameraInfoFields;

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
    this.gridSize = 20.0,
    this.showGrid = true,
    this.showBigGrid = false,
    this.activePolyline,
    this.polylineCursorPos,
    this.cameraInfoFields = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    if (showBigGrid) {
      _drawBigGrid(canvas, size);
    }
    if (showGrid) {
      _drawGrid(canvas, size);
    }
    for (final item in items) {
      if (item.id == editingId) continue; // редагується на канвасі — малює overlay
      _drawItem(canvas, item);
    }
    _drawPolylinePreview(canvas);
    _drawMultiHighlight(canvas);
    _drawSelection(canvas);
    _drawMarquee(canvas);
    canvas.restore();
  }

  void _drawBigGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..strokeWidth = 1.0 / scale;

    const bigGridSize = 100.0;

    final visibleLeft = -offset.dx / scale;
    final visibleTop = -offset.dy / scale;
    final visibleRight = visibleLeft + size.width / scale;
    final visibleBottom = visibleTop + size.height / scale;

    final startX = (visibleLeft / bigGridSize).floor() * bigGridSize;
    for (double x = startX; x <= visibleRight; x += bigGridSize) {
      canvas.drawLine(Offset(x, visibleTop), Offset(x, visibleBottom), paint);
    }
    final startY = (visibleTop / bigGridSize).floor() * bigGridSize;
    for (double y = startY; y <= visibleBottom; y += bigGridSize) {
      canvas.drawLine(Offset(visibleLeft, y), Offset(visibleRight, y), paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1 / scale;

    final scaledGridSize = gridSize;
    
    // Розраховуємо видиму область
    final visibleLeft = -offset.dx / scale;
    final visibleTop = -offset.dy / scale;
    final visibleRight = visibleLeft + size.width / scale;
    final visibleBottom = visibleTop + size.height / scale;

    // Малюємо вертикальні лінії
    final startX = (visibleLeft / scaledGridSize).floor() * scaledGridSize;
    for (double x = startX; x <= visibleRight; x += scaledGridSize) {
      canvas.drawLine(Offset(x, visibleTop), Offset(x, visibleBottom), paint);
    }

    // Малюємо горизонтальні лінії
    final startY = (visibleTop / scaledGridSize).floor() * scaledGridSize;
    for (double y = startY; y <= visibleBottom; y += scaledGridSize) {
      canvas.drawLine(Offset(visibleLeft, y), Offset(visibleRight, y), paint);
    }
  }

  void _withRotation(Canvas canvas, DrawnItem item, VoidCallback draw) {
    final rotate = item.rotation != 0 && item.points.length >= 2;
    if (rotate) {
      final c = _rotationPivot(item);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(item.rotation);
      canvas.translate(-c.dx, -c.dy);
    }
    draw();
    if (rotate) canvas.restore();
  }

  // JIB rotates around body center; all other items rotate around bounding-box center.
  static Offset _rotationPivot(DrawnItem item) {
    final b = item.bounds;
    if (item.rigData?.type == RigType.jib) {
      return Offset(b.center.dx, b.bottom - 184.5 * b.width / 304.0);
    }
    return b.center;
  }

  void _drawItem(Canvas canvas, DrawnItem item) {
    if (!item.visible) return;
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
        case Tool.polyline:
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

        case Tool.camera:
          _drawCamera(canvas, item, stroke, fill);
        case Tool.actor:
          _drawActor(canvas, item, stroke);
        case Tool.rig:
          _drawRig(canvas, item, stroke, fill);
      }
    });
    // Info table is drawn after rotation so it stays horizontal on screen.
    if (item.tool == Tool.camera) {
      _drawCameraInfoTable(canvas, item);
    }
  }

  // Camera icon — polygon scaled from SVG (viewBox 152×152):
  // points="32 16 67.28 65.13 34.47 68.72 32.95 126.36 45.66 136
  //         106.34 136 119.05 126.36 117.53 68.72 84.72 65.13 120 16"
  void _drawCamera(Canvas canvas, DrawnItem item, Paint stroke, Paint? fill) {
    final pts = item.points;
    if (pts.length < 2) return;
    final r = Rect.fromPoints(pts[0], pts[1]);
    final W = r.width, H = r.height;
    final l = r.left, t = r.top;

    final bodyColor = item.fillColor ?? const Color(0xFF455A64);
    final bodyFill = Paint()..color = bodyColor..style = PaintingStyle.fill;

    // Coordinates normalised by dividing original SVG values by 152
    final path = Path()
      ..moveTo(l + 0.2105 * W, t + 0.1053 * H)  // 32, 16
      ..lineTo(l + 0.4426 * W, t + 0.4285 * H)  // 67.28, 65.13
      ..lineTo(l + 0.2268 * W, t + 0.4521 * H)  // 34.47, 68.72
      ..lineTo(l + 0.2167 * W, t + 0.8313 * H)  // 32.95, 126.36
      ..lineTo(l + 0.3004 * W, t + 0.8947 * H)  // 45.66, 136
      ..lineTo(l + 0.6996 * W, t + 0.8947 * H)  // 106.34, 136
      ..lineTo(l + 0.7832 * W, t + 0.8313 * H)  // 119.05, 126.36
      ..lineTo(l + 0.7732 * W, t + 0.4521 * H)  // 117.53, 68.72
      ..lineTo(l + 0.5574 * W, t + 0.4285 * H)  // 84.72, 65.13
      ..lineTo(l + 0.7895 * W, t + 0.1053 * H)  // 120, 16
      ..close();

    canvas.drawPath(path, bodyFill);
    canvas.drawPath(path, stroke);
  }

  // Actor shape from SVG viewBox 152×152:
  // head: circle cx=76 cy=75.57 r=31.07 → (0.5, 0.4972, r=0.2044)
  // body: ellipse cx=76 cy=87.36 rx=71.25 ry=33.75 → centre (0.5, 0.5747), size (0.9375×0.4440)
  void _drawActor(Canvas canvas, DrawnItem item, Paint stroke) {
    final pts = item.points;
    if (pts.length < 2) return;
    final r = Rect.fromPoints(pts[0], pts[1]);
    final W = r.width, H = r.height;
    final l = r.left, t = r.top;

    final bodyColor = item.fillColor ?? const Color(0xFF43A047);
    final bodyFill = Paint()..color = bodyColor..style = PaintingStyle.fill;

    // Body ellipse
    final bodyCenter = Offset(l + 0.5 * W, t + 0.5747 * H);
    final bodyRect = Rect.fromCenter(center: bodyCenter, width: 0.9375 * W, height: 0.4440 * H);
    canvas.drawOval(bodyRect, bodyFill);
    canvas.drawOval(bodyRect, stroke);

    // Head circle (radius relative to the smaller axis to stay circular)
    final headCenter = Offset(l + 0.5 * W, t + 0.4972 * H);
    final headR = 0.2044 * math.min(W, H);
    canvas.drawCircle(headCenter, headR, bodyFill);
    canvas.drawCircle(headCenter, headR, stroke);
  }

  void _drawRig(Canvas canvas, DrawnItem item, Paint stroke, Paint? fill) {
    final pts = item.points;
    if (pts.length < 2 || item.rigData == null) return;
    final r = Rect.fromPoints(pts[0], pts[1]);
    final W = r.width, H = r.height;
    final l = r.left, t = r.top;
    switch (item.rigData!.type) {
      case RigType.jib:   _drawJib(canvas, l, t, W, H, stroke, fill);
      case RigType.dolly: _drawDolly(canvas, l, t, W, H, stroke, fill);
      case RigType.rail:  _drawRail(canvas, l, t, W, H, stroke);
    }
  }

  // Jib crane — SVG viewBox 304×800, all coords normalised by W/H.
  // Rounded-rect legs: rx = 11.48/304 × W ≈ 0.0378 × W.
  void _drawJib(Canvas canvas, double l, double t, double W, double H, Paint stroke, Paint? fill) {
    final rr = Radius.circular(0.04 * W);

    void filled(Rect rect, {bool rounded = false}) {
      if (fill != null) {
        if (rounded) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, rr), fill);
        } else {
          canvas.drawRect(rect, fill);
        }
      }
      if (rounded) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, rr), stroke);
      } else {
        canvas.drawRect(rect, stroke);
      }
    }

    // All fixed components scale with W only (SVG viewBox 304×800).
    // The upper boom fills whatever height remains above the fixed base.
    final double s = W / 304.0; // px per SVG unit

    // Fixed base section: lower column (200u) + everything below it (282u) = 482u total
    final double fixedH = 482.0 * s;
    final double boomH = (H - fixedH).clamp(0.0, double.infinity);
    final double ft = t + boomH; // top of fixed section on screen

    // Upper boom (variable — only this part stretches when height changes)
    if (boomH > 0) {
      filled(Rect.fromLTWH(l + 0.4588 * W, t, 0.0822 * W, boomH));
    }
    // Lower column
    filled(Rect.fromLTWH(l + 0.4425 * W, ft, 0.1151 * W, 200.0 * s));
    // Base column (wider, below lower column)
    filled(Rect.fromLTWH(l + 0.4096 * W, ft + 200.0 * s, 0.1809 * W, 255.0 * s));
    // Body block (overlaps the lower/base column area)
    filled(Rect.fromLTWH(l + 0.2204 * W, ft + 212.5 * s, 0.5592 * W, 170.0 * s));
    // 4 legs (rounded)
    filled(Rect.fromLTWH(l + 0.1217 * W, ft + 182.5 * s, 0.0987 * W, 80.0 * s), rounded: true);
    filled(Rect.fromLTWH(l + 0.7796 * W, ft + 182.5 * s, 0.0987 * W, 80.0 * s), rounded: true);
    filled(Rect.fromLTWH(l + 0.1217 * W, ft + 332.5 * s, 0.0987 * W, 80.0 * s), rounded: true);
    filled(Rect.fromLTWH(l + 0.7796 * W, ft + 332.5 * s, 0.0987 * W, 80.0 * s), rounded: true);
  }

  // Dolly cart — SVG viewBox 300×300, rounded-rect legs: rx = 11.48/300 × W ≈ 0.0383 × W.
  void _drawDolly(Canvas canvas, double l, double t, double W, double H, Paint stroke, Paint? fill) {
    final rr = Radius.circular(0.04 * W);

    void filled(Rect rect, {bool rounded = false}) {
      if (fill != null) {
        if (rounded) {
          canvas.drawRRect(RRect.fromRectAndRadius(rect, rr), fill);
        } else {
          canvas.drawRect(rect, fill);
        }
      }
      if (rounded) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, rr), stroke);
      } else {
        canvas.drawRect(rect, stroke);
      }
    }

    Rect box(double x, double y, double w, double h) =>
        Rect.fromLTWH(l + x * W, t + y * H, w * W, h * H);

    // 4 wheel posts (rounded)
    filled(box(0.1167, 0.1083, 0.1000, 0.2667), rounded: true);
    filled(box(0.1167, 0.6083, 0.1000, 0.2667), rounded: true);
    filled(box(0.7833, 0.1083, 0.1000, 0.2667), rounded: true);
    filled(box(0.7833, 0.6083, 0.1000, 0.2667), rounded: true);
    // Body platform
    filled(box(0.2167, 0.2083, 0.5667, 0.5667));
  }

  // Camera rails — SVG viewBox 304×800, stroke only (fill ignored).
  void _drawRail(Canvas canvas, double l, double t, double W, double H, Paint stroke) {
    // Left and right rails
    canvas.drawLine(Offset(l + 0.2204 * W, t + 0.0319 * H), Offset(l + 0.2204 * W, t + 0.9631 * H), stroke);
    canvas.drawLine(Offset(l + 0.7796 * W, t + 0.0319 * H), Offset(l + 0.7796 * W, t + 0.9631 * H), stroke);
    // Cross-ties (14 total)
    for (final yf in const [
      0.0475, 0.1225, 0.1975, 0.2725, 0.3475, 0.4225,
      0.4975, 0.5725, 0.6475, 0.7225, 0.7975, 0.8725, 0.9475,
    ]) {
      canvas.drawLine(Offset(l + 0.2204 * W, t + yf * H), Offset(l + 0.7796 * W, t + yf * H), stroke);
    }
  }

  void _drawCameraInfoTable(Canvas canvas, DrawnItem item) {
    final cd = item.cameraData;
    if (cd == null || cameraInfoFields.isEmpty) return;

    final rows = <String>[];

    if (cameraInfoFields.contains(CameraInfoField.cameraModel) && cd.cameraModel.isNotEmpty) {
      rows.add('${strings.cameraModel}: ${cd.cameraModel}');
    }
    if (cameraInfoFields.contains(CameraInfoField.shotTypes) && cd.shotTypes.isNotEmpty) {
      rows.add('${strings.shotType}: ${cd.shotTypes.join(', ')}');
    }
    if (cameraInfoFields.contains(CameraInfoField.lens) && cd.lens.isNotEmpty) {
      rows.add('${strings.lens}: ${cd.lens}');
    }
    if (cameraInfoFields.contains(CameraInfoField.viewfinder) && cd.viewfinder != ViewfinderType.none) {
      final v = cd.viewfinder == ViewfinderType.small ? strings.viewfinderSmall : strings.viewfinderBig;
      rows.add('${strings.viewfinder}: ${strings.yes} ($v)');
    }
    if (cameraInfoFields.contains(CameraInfoField.headphones) && cd.headphones != HeadphonesType.none) {
      final h = cd.headphones == HeadphonesType.single ? strings.headphonesSingle : strings.headphonesDouble;
      rows.add('${strings.headphones}: ${strings.yes} ($h)');
    }
    if (cameraInfoFields.contains(CameraInfoField.tripod) && cd.tripod) {
      final desc = cd.tripodDescription.isNotEmpty ? ' (${cd.tripodDescription})' : '';
      rows.add('${strings.tripod}: ${strings.yes}$desc');
    }
    if (cameraInfoFields.contains(CameraInfoField.wheels) && cd.wheels) {
      rows.add('${strings.wheels}: ${strings.yes}');
    }
    if (cameraInfoFields.contains(CameraInfoField.podium) && cd.podium) {
      final desc = cd.podiumDescription.isNotEmpty ? ' (${cd.podiumDescription})' : '';
      rows.add('${strings.podium}: ${strings.yes}$desc');
    }
    if (cameraInfoFields.contains(CameraInfoField.description) && cd.description.isNotEmpty) {
      rows.add('${strings.description}: ${cd.description}');
    }

    if (rows.isEmpty) return;

    const fontSize = 20.0;
    const padding = 8.0;
    const gap = 12.0;

    final tp = TextPainter(
      text: TextSpan(
        text: rows.join('\n'),
        style: const TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: FontWeight.normal,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout();

    final r = item.visualBounds;
    final tableW = tp.width + padding * 2;
    final tableH = tp.height + padding * 2;
    final Offset tableTopLeft;
    final tableOffset = item.cameraData!.tableOffset;
    if (tableOffset != null) {
      tableTopLeft = r.center + tableOffset;
    } else {
      // Default: below the camera number label (if present), otherwise below the camera.
      final labelItem = items.where(
        (it) => it.tool == Tool.text && it.boundToId == item.id,
      ).firstOrNull;
      final anchorBottom = labelItem != null ? labelItem.bounds.bottom : r.bottom;
      tableTopLeft = Offset(r.center.dx - tableW / 2, anchorBottom + gap);
    }
    final tableRect = Rect.fromLTWH(tableTopLeft.dx, tableTopLeft.dy, tableW, tableH);

    canvas.drawRect(tableRect,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawRect(
        tableRect,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);

    tp.paint(canvas, tableTopLeft + const Offset(padding, padding));
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
    final rot = Offset(box.center.dx, box.top - 56 / scale);
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
      final rotPoint = Offset(center.dx, selBox.top - 56 / scale);
      canvas.drawLine(handleBase, rotPoint, box);
      canvas.drawCircle(rotPoint, 6 / scale, Paint()..color = rotationHandleColor);

      final fill = Paint()..color = selectionColor;
      if (item.tool != Tool.text) {
        if (toolIsBox(item.tool)) {
          final showHandles = item.tool == Tool.actor ||
              item.tool != Tool.camera ||
              (item.cameraData?.allowResize ?? false);
          if (showHandles) {
            for (final f in boxHandleFactors) {
              final pos = Offset(
                selBox.left + f.dx * selBox.width,
                selBox.top + f.dy * selBox.height,
              );
              canvas.drawCircle(pos, 5 / scale, fill);
            }
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

  void _drawPolylinePreview(Canvas canvas) {
    final poly = activePolyline;
    final cursor = polylineCursorPos;
    if (poly == null || cursor == null || poly.points.isEmpty) return;
    final preview = Paint()
      ..color = poly.strokeColor.withValues(alpha: 0.5)
      ..strokeWidth = poly.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(poly.points.last, cursor, preview);
    canvas.drawCircle(
      cursor,
      5 / scale,
      Paint()..color = poly.strokeColor.withValues(alpha: 0.8),
    );
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