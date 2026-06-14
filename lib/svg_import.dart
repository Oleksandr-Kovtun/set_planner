import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:path_drawing/path_drawing.dart';
import 'models.dart';

class _Style {
  Color? fill;
  bool fillSet = false;
  Color? stroke;
  bool strokeSet = false;
  double? strokeWidth;
}

// Перетворює текст SVG на список редагованих фігур.
List<DrawnItem> svgToItems(
  String svgString, {
  Offset origin = const Offset(40, 40),
  double target = 400,
}) {
  final doc = XmlDocument.parse(svgString);
  final svg = doc.findAllElements('svg').first;

  Rect viewBox;
  final vb = svg.getAttribute('viewBox');
  if (vb != null) {
    final n = vb.trim().split(RegExp(r'[ ,]+')).map(double.parse).toList();
    viewBox = Rect.fromLTWH(n[0], n[1], n[2], n[3]);
  } else {
    final w = double.tryParse(svg.getAttribute('width') ?? '') ?? 1024;
    final h = double.tryParse(svg.getAttribute('height') ?? '') ?? 1024;
    viewBox = Rect.fromLTWH(0, 0, w, h);
  }

  final classRules = _parseStyleBlocks(svg);
  final k = target / (viewBox.width > viewBox.height ? viewBox.width : viewBox.height);
  Offset place(Offset p) =>
      origin + Offset((p.dx - viewBox.left) * k, (p.dy - viewBox.top) * k);

  final items = <DrawnItem>[];
  for (final el in svg.descendants.whereType<XmlElement>()) {
    final path = _elementToPath(el);
    if (path == null) continue;
    final nb = path.getBounds();
    if (nb.width <= 0 && nb.height <= 0) continue;

    final st = _resolveStyle(el, classRules);
    items.add(DrawnItem(
      Tool.svgPath,
      [place(nb.topLeft), place(nb.bottomRight)],
      svgPath: path,
      svgPathBounds: nb,
      fillColor: st.fill,
      strokeColor: st.stroke ?? const Color(0xFF000000),
      strokeWidth: (st.stroke != null) ? (st.strokeWidth ?? 1) * k : 0,
    ));
  }
  return items;
}

ui.Path? _elementToPath(XmlElement el) {
  switch (el.name.local) {
    case 'path':
      final d = el.getAttribute('d');
      if (d == null) return null;
      try {
        return parseSvgPathData(d);
      } catch (_) {
        return null;
      }
    case 'rect':
      final w = _d(el, 'width'), h = _d(el, 'height');
      if (w <= 0 || h <= 0) return null;
      final rect = Rect.fromLTWH(_d(el, 'x'), _d(el, 'y'), w, h);
      final rx = _dn(el, 'rx'), ry = _dn(el, 'ry');
      final p = ui.Path();
      if (rx != null || ry != null) {
        p.addRRect(RRect.fromRectAndRadius(
            rect, Radius.elliptical(rx ?? ry ?? 0, ry ?? rx ?? 0)));
      } else {
        p.addRect(rect);
      }
      return p;
    case 'circle':
      final r = _d(el, 'r');
      if (r <= 0) return null;
      return ui.Path()
        ..addOval(Rect.fromCircle(center: Offset(_d(el, 'cx'), _d(el, 'cy')), radius: r));
    case 'ellipse':
      final rx = _d(el, 'rx'), ry = _d(el, 'ry');
      if (rx <= 0 || ry <= 0) return null;
      return ui.Path()
        ..addOval(Rect.fromCenter(
            center: Offset(_d(el, 'cx'), _d(el, 'cy')), width: rx * 2, height: ry * 2));
    case 'line':
      return ui.Path()
        ..moveTo(_d(el, 'x1'), _d(el, 'y1'))
        ..lineTo(_d(el, 'x2'), _d(el, 'y2'));
    case 'polygon':
    case 'polyline':
      final pts = _points(el.getAttribute('points'));
      if (pts.length < 2) return null;
      final p = ui.Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final q in pts.skip(1)) {
        p.lineTo(q.dx, q.dy);
      }
      if (el.name.local == 'polygon') p.close();
      return p;
    default:
      return null;
  }
}

double _d(XmlElement el, String a) => double.tryParse(el.getAttribute(a) ?? '') ?? 0;
double? _dn(XmlElement el, String a) {
  final v = el.getAttribute(a);
  return v == null ? null : double.tryParse(v);
}

List<Offset> _points(String? s) {
  if (s == null) return [];
  final n = s
      .trim()
      .split(RegExp(r'[ ,]+'))
      .where((e) => e.isNotEmpty)
      .map(double.parse)
      .toList();
  final out = <Offset>[];
  for (int i = 0; i + 1 < n.length; i += 2) {
    out.add(Offset(n[i], n[i + 1]));
  }
  return out;
}

Map<String, _Style> _parseStyleBlocks(XmlElement svg) {
  final rules = <String, _Style>{};
  final styles =
      svg.descendants.whereType<XmlElement>().where((e) => e.name.local == 'style');
  final re = RegExp(r'\.([A-Za-z0-9_-]+)\s*\{([^}]*)\}');
  for (final styleEl in styles) {
    for (final m in re.allMatches(styleEl.innerText)) {
      final st = _Style();
      _applyDecls(m.group(2)!, st);
      rules[m.group(1)!] = st;
    }
  }
  return rules;
}

void _applyDecls(String body, _Style st) {
  for (final decl in body.split(';')) {
    final i = decl.indexOf(':');
    if (i < 0) continue;
    final prop = decl.substring(0, i).trim();
    final val = decl.substring(i + 1).trim();
    switch (prop) {
      case 'fill':
        st.fill = _color(val);
        st.fillSet = true;
      case 'stroke':
        st.stroke = _color(val);
        st.strokeSet = true;
      case 'stroke-width':
        st.strokeWidth = double.tryParse(val.replaceAll('px', ''));
    }
  }
}

_Style _resolveStyle(XmlElement el, Map<String, _Style> classRules) {
  final st = _Style();
  final cls = el.getAttribute('class');
  if (cls != null) {
    for (final c in cls.trim().split(RegExp(r'\s+'))) {
      final r = classRules[c];
      if (r != null) _merge(st, r);
    }
  }
  final f = el.getAttribute('fill');
  if (f != null) { st.fill = _color(f); st.fillSet = true; }
  final s = el.getAttribute('stroke');
  if (s != null) { st.stroke = _color(s); st.strokeSet = true; }
  final sw = el.getAttribute('stroke-width');
  if (sw != null) st.strokeWidth = double.tryParse(sw.replaceAll('px', ''));
  final inline = el.getAttribute('style');
  if (inline != null) _applyDecls(inline, st);
  if (!st.fillSet) st.fill = const Color(0xFF000000); // дефолтна заливка SVG — чорна
  return st;
}

void _merge(_Style dst, _Style src) {
  if (src.fillSet) { dst.fill = src.fill; dst.fillSet = true; }
  if (src.strokeSet) { dst.stroke = src.stroke; dst.strokeSet = true; }
  if (src.strokeWidth != null) dst.strokeWidth = src.strokeWidth;
}

Color? _color(String raw) {
  var v = raw.trim().toLowerCase();
  if (v == 'none' || v == 'transparent') return null;
  if (v.startsWith('#')) {
    v = v.substring(1);
    if (v.length == 3) v = v.split('').map((c) => '$c$c').join();
    if (v.length == 6) return Color(int.parse('FF$v', radix: 16));
    if (v.length == 8) return Color(int.parse(v, radix: 16));
    return null;
  }
  if (v.startsWith('rgb')) {
    final nums = RegExp(r'[\d.]+').allMatches(v).map((m) => m.group(0)!).toList();
    if (nums.length >= 3) {
      int c(int i) => double.parse(nums[i]).round().clamp(0, 255);
      return Color.fromARGB(255, c(0), c(1), c(2));
    }
    return null;
  }
  return _named[v];
}

const Map<String, Color> _named = {
  'black': Color(0xFF000000), 'white': Color(0xFFFFFFFF), 'red': Color(0xFFFF0000),
  'lime': Color(0xFF00FF00), 'green': Color(0xFF008000), 'blue': Color(0xFF0000FF),
  'yellow': Color(0xFFFFFF00), 'cyan': Color(0xFF00FFFF), 'aqua': Color(0xFF00FFFF),
  'magenta': Color(0xFFFF00FF), 'fuchsia': Color(0xFFFF00FF), 'gray': Color(0xFF808080),
  'grey': Color(0xFF808080), 'silver': Color(0xFFC0C0C0), 'maroon': Color(0xFF800000),
  'olive': Color(0xFF808000), 'navy': Color(0xFF000080), 'teal': Color(0xFF008080),
  'purple': Color(0xFF800080), 'orange': Color(0xFFFFA500),
};