import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum Tool { select, pen, polyline, line, rectangle, ellipse, triangle, arrow, star, svg, svgPath, lasso, text, image }

// Групи рівнів (z-порядок): base завжди внизу, далі actor, найвище camera.
enum LayerBand { base, actor, camera }

const List<Tool> shapeTools = [
  Tool.rectangle, 
  Tool.ellipse, 
  Tool.triangle,
  Tool.star, 
  Tool.arrow, 
];

bool toolSupportsFill(Tool t) =>
    t == Tool.rectangle || 
    t == Tool.ellipse || 
    t == Tool.triangle || 
    t == Tool.star ||
    t == Tool.svg ||
    t == Tool.svgPath;

bool toolSupportsAspectLock(Tool t) =>
    t == Tool.rectangle || 
    t == Tool.ellipse || 
    t == Tool.triangle || 
    t == Tool.star || 
    t == Tool.svg || 
    t == Tool.svgPath ||
    t == Tool.image;

// "Коробкові" фігури — задаються прямокутником, мають 8 ручок розміру.
bool toolIsBox(Tool t) =>
    t == Tool.rectangle ||
    t == Tool.ellipse ||
    t == Tool.triangle ||
    t == Tool.star ||
    t == Tool.svg ||
    t == Tool.svgPath ||
    t == Tool.image;

// Відступ рамки виділення (і позицій ручок) від самої фігури.
const double selectionPadding = 6.0;

// Розташування 8 ручок як частки ширини/висоти рамки (без центру).
const List<Offset> boxHandleFactors = [
  Offset(0, 0), Offset(0.5, 0), Offset(1, 0),
  Offset(0, 0.5), Offset(1, 0.5),
  Offset(0, 1), Offset(0.5, 1), Offset(1, 1),
];

// Обертання точки навколо центра на заданий кут (радіани).
Offset rotateAround(Offset point, Offset center, double angle) {
  final s = math.sin(angle), c = math.cos(angle);
  final dx = point.dx - center.dx, dy = point.dy - center.dy;
  return Offset(center.dx + dx * c - dy * s, center.dy + dx * s + dy * c);
}

class DrawnItem {
  final Tool tool;
  final List<Offset> points;
  final ui.Picture? svgPicture; // розпарсений малюнок (для Tool.svg)
  final Size? svgSize;          // власний розмір svg
  final ui.Path? svgPath;    // контур елемента (у власних координатах SVG)
  final ui.Image? image;
  final Rect? svgPathBounds; // межі цього контуру у тих самих координатах
  double opacity = 1.0; // Image Opacity
  double strokeWidth;
  Color strokeColor;
  Color? fillColor;
  bool lockAspect;
  double rotation; // кут обертання в радіанах
  LayerBand band;
  int? groupId; // елементи з однаковим groupId — одна група
  static int _idSeq = 0;
  final int id;            // стабільний ідентифікатор (для прив'язки тексту)
  String? text;            // вміст текстового поля
  double fontSize;
  String? fontFamily;
  bool bold;
  bool italic;
  TextAlign textAlign;
  int? boundToId;          // id фігури, до якої прив'язано текст (null = вільний)
  bool locked;
  bool smoothed;
  bool arrowHeadStart; // вістря на початку
  bool arrowHeadEnd;   // вістря в кінці

  DrawnItem(
    this.tool,
    this.points, {
    this.strokeWidth = 3,
    this.strokeColor = const Color(0xFF000000),
    this.fillColor,
    this.lockAspect = false,
    this.rotation = 0,
    this.band = LayerBand.base,
    this.svgPicture,
    this.svgSize,
    this.svgPath,
    this.svgPathBounds,
    this.image,
    this.opacity = 1.0,
    this.groupId,
    int? id,
    this.text,
    this.fontSize = 24,
    this.fontFamily,
    this.bold = false,
    this.italic = false,
    this.textAlign = TextAlign.center,
    this.boundToId,
    this.locked = false,
    this.smoothed = false,
    this.arrowHeadStart = false,
    this.arrowHeadEnd = false,
  }) : id = id ?? (++_idSeq);

  DrawnItem copy() => DrawnItem(
        tool,
        List<Offset>.of(points),
        strokeWidth: strokeWidth,
        strokeColor: strokeColor,
        fillColor: fillColor,
        lockAspect: lockAspect,
        rotation: rotation,
        band: band,
        svgPicture: svgPicture,
        svgSize: svgSize,
        svgPath: svgPath,
        svgPathBounds: svgPathBounds,
        image: image,
        opacity: opacity,
        groupId: groupId,
        id: id,
        text: text,
        fontSize: fontSize,
        fontFamily: fontFamily,
        bold: bold,
        italic: italic,
        textAlign: textAlign,
        boundToId: boundToId,
        locked: locked,
        smoothed: smoothed,
        arrowHeadStart: arrowHeadStart,
        arrowHeadEnd: arrowHeadEnd,
      );

  Rect get bounds {
    double minX = points.first.dx, maxX = minX;
    double minY = points.first.dy, maxY = minY;
    for (final p in points) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  
  // Межі з урахуванням повороту (охоплюють фігуру так, як вона виглядає).
  Rect get visualBounds {
    if (rotation == 0 || points.length < 2) return bounds;
    final b = bounds, c = b.center;
    final cs = [b.topLeft, b.topRight, b.bottomRight, b.bottomLeft]
        .map((p) => rotateAround(p, c, rotation));
    double minX = double.infinity, minY = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity;
    for (final p in cs) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // Бажане співвідношення ширина/висота для "зберігати пропорції".
  // Для SVG-фігури — її оригінальне співвідношення; для решти — 1:1 (квадрат).
  double get targetAspectRatio {
    if (tool == Tool.svgPath && svgPathBounds != null) {
      final nb = svgPathBounds!;
      if (nb.width > 0 && nb.height > 0) return nb.width / nb.height;
    }
    if (tool == Tool.image && image != null) {
      final w = image!.width.toDouble(), h = image!.height.toDouble();
      if (w > 0 && h > 0) return w / h;
    }
    return 1.0;
  }

  void applyAspectLock() {
    if (!lockAspect || points.length < 2 || !toolSupportsAspectLock(tool)) return;
    final p0 = points[0], p1 = points[1];
    final dx = p1.dx - p0.dx, dy = p1.dy - p0.dy;
    final ratio = targetAspectRatio;
    final aw = dx.abs(), ah = dy.abs();
    double w, h;
    if (aw >= ah * ratio) {
      w = aw;
      h = w / ratio;
    } else {
      h = ah;
      w = h * ratio;
    }
    points[1] = Offset(
      p0.dx + (dx.isNegative ? -w : w),
      p0.dy + (dy.isNegative ? -h : h),
    );
  }
}

IconData toolIcon(Tool t) {
  switch (t) {
    case Tool.select: return Icons.near_me;
    case Tool.pen: return Icons.gesture;
    case Tool.polyline: return Icons.polyline;
    case Tool.line: return Icons.horizontal_rule;
    case Tool.rectangle: return Icons.crop_square;
    case Tool.ellipse: return Icons.circle_outlined;
    case Tool.triangle: return Icons.change_history;
    case Tool.arrow: return Icons.horizontal_rule; // TODO: замінити на іконку стрілки
    case Tool.star: return Icons.star_border;
    case Tool.svg: return Icons.image;
    case Tool.svgPath: return Icons.polyline;
    case Tool.lasso: return Icons.highlight_alt;
    case Tool.text: return Icons.title;
    case Tool.image: return Icons.photo;
  }
}