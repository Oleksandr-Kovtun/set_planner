import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';
import 'models.dart';
import 'models/settings.dart';

// ─── Data container returned by the loader ───────────────────────────────────

class ProjectData {
  final List<DrawnItem> items;
  final AppSettings settings;
  final double scale;
  final Offset offset;
  const ProjectData({
    required this.items,
    required this.settings,
    required this.scale,
    required this.offset,
  });
}

// ─── Serializer ──────────────────────────────────────────────────────────────

class ProjectSerializer {
  static String _hex(Color c) {
    int ch(double x) => (x * 255.0).round().clamp(0, 255);
    return '${ch(c.a).toRadixString(16).padLeft(2, '0')}'
        '${ch(c.r).toRadixString(16).padLeft(2, '0')}'
        '${ch(c.g).toRadixString(16).padLeft(2, '0')}'
        '${ch(c.b).toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  static Future<String> toXmlString({
    required List<DrawnItem> items,
    required AppSettings settings,
    required double scale,
    required Offset offset,
  }) async {
    // Collect image bytes first (async)
    final Map<int, String> imageB64 = {};
    for (final item in items) {
      if (item.tool == Tool.image && item.image != null) {
        final bytes =
            await item.image!.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          imageB64[item.id] = base64Encode(bytes.buffer.asUint8List());
        }
      }
    }

    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8"');
    b.element('SetPlannerProject', attributes: {'version': '1'}, nest: () {
      _writeSettings(b, settings);
      b.element('Viewport', attributes: {
        'scale': scale.toString(),
        'offsetX': offset.dx.toString(),
        'offsetY': offset.dy.toString(),
      });
      b.element('Items', nest: () {
        for (final item in items) {
          _writeItem(b, item, imageB64);
        }
      });
    });

    return b.buildDocument().toXmlString(pretty: true);
  }

  static void _writeSettings(XmlBuilder b, AppSettings s) {
    b.element('Settings', attributes: {
      'paperSize': s.paperSize.name,
      'paperOrientation': s.paperOrientation.name,
      'gridSize': s.gridSize.toString(),
      'showGrid': s.showGrid.toString(),
      'snapToGrid': s.snapToGrid.toString(),
      'primaryColor': _hex(s.primaryColor),
      'cameraNumberStyle': s.cameraNumberStyle.name,
      'cameraInfoFields': s.cameraInfoFields.map((f) => f.name).join(','),
      'language': s.language,
    });
  }

  static void _writeItem(
      XmlBuilder b, DrawnItem item, Map<int, String> imageB64) {
    final attrs = <String, String>{
      'id': item.id.toString(),
      'tool': item.tool.name,
      'band': item.band.name,
      'strokeWidth': item.strokeWidth.toString(),
      'strokeColor': _hex(item.strokeColor),
      'lockAspect': item.lockAspect.toString(),
      'rotation': item.rotation.toString(),
      'opacity': item.opacity.toString(),
      'locked': item.locked.toString(),
      'smoothed': item.smoothed.toString(),
      'arrowHeadStart': item.arrowHeadStart.toString(),
      'arrowHeadEnd': item.arrowHeadEnd.toString(),
      'visible': item.visible.toString(),
      'fontSize': item.fontSize.toString(),
      'bold': item.bold.toString(),
      'italic': item.italic.toString(),
      'textAlign': item.textAlign.name,
    };
    if (item.fillColor != null) attrs['fillColor'] = _hex(item.fillColor!);
    if (item.groupId != null) attrs['groupId'] = item.groupId.toString();
    if (item.boundToId != null) attrs['boundToId'] = item.boundToId.toString();
    if (item.fontFamily != null) attrs['fontFamily'] = item.fontFamily!;

    b.element('Item', attributes: attrs, nest: () {
      // Points
      b.element('Points', nest: () {
        for (final p in item.points) {
          b.element('P',
              attributes: {'x': p.dx.toString(), 'y': p.dy.toString()});
        }
      });

      // Free text content (child element to preserve special chars / newlines)
      if (item.text != null) {
        b.element('Text', nest: () => b.cdata(item.text!));
      }

      // Camera
      if (item.cameraData != null) _writeCameraData(b, item.cameraData!);
      // Actor
      if (item.actorData != null) {
        b.element('ActorData', nest: () {
          b.element('Name', nest: () => b.cdata(item.actorData!.name));
          b.element('Desc', nest: () => b.cdata(item.actorData!.description));
          b.element('Props', nest: () => b.cdata(item.actorData!.props));
        });
      }
      // Rig
      if (item.rigData != null) {
        b.element('RigData', attributes: {'type': item.rigData!.type.name});
      }
      // Raster image
      if (item.tool == Tool.image && imageB64.containsKey(item.id)) {
        b.element('ImageData', nest: imageB64[item.id]);
      }
      // SVG path
      if (item.tool == Tool.svgPath && item.svgPathD != null) {
        b.element('SvgPathD', nest: () => b.cdata(item.svgPathD!));
        if (item.svgPathBounds != null) {
          final nb = item.svgPathBounds!;
          b.element('SvgPathBounds', attributes: {
            'left': nb.left.toString(),
            'top': nb.top.toString(),
            'right': nb.right.toString(),
            'bottom': nb.bottom.toString(),
          });
        }
      }
    });
  }

  static void _writeCameraData(XmlBuilder b, CameraData c) {
    b.element('CameraData', attributes: {
      'number': c.number.toString(),
      'showNumber': c.showNumber.toString(),
      'shotTypes': c.shotTypes.join(','),
      'viewfinder': c.viewfinder.name,
      'headphones': c.headphones.name,
      'tripod': c.tripod.toString(),
      'wheels': c.wheels.toString(),
      'podium': c.podium.toString(),
      'allowResize': c.allowResize.toString(),
      if (c.tableOffset != null) 'tableOffsetX': c.tableOffset!.dx.toString(),
      if (c.tableOffset != null) 'tableOffsetY': c.tableOffset!.dy.toString(),
    }, nest: () {
      b.element('Model', nest: () => b.cdata(c.cameraModel));
      b.element('Lens', nest: () => b.cdata(c.lens));
      b.element('TripodDesc', nest: () => b.cdata(c.tripodDescription));
      b.element('PodiumDesc', nest: () => b.cdata(c.podiumDescription));
      b.element('Description', nest: () => b.cdata(c.description));
    });
  }
}

// ─── Loader ──────────────────────────────────────────────────────────────────

class ProjectLoader {
  static Color _color(String? hex, Color fallback) {
    if (hex == null) return fallback;
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static bool _b(String? s, [bool def = false]) => s == null ? def : s == 'true';
  static double _d(String? s, [double def = 0]) =>
      s == null ? def : (double.tryParse(s) ?? def);
  static int _i(String? s, [int def = 0]) =>
      s == null ? def : (int.tryParse(s) ?? def);
  static String _cdata(XmlElement? el) => el?.innerText.trim() ?? '';

  static Future<ProjectData> fromXmlString(String xml) async {
    final doc = XmlDocument.parse(xml);
    final root = doc.rootElement;

    final settings = _parseSettings(root.findElements('Settings').firstOrNull);

    double scale = 1.0;
    Offset offset = Offset.zero;
    final vp = root.findElements('Viewport').firstOrNull;
    if (vp != null) {
      scale = _d(vp.getAttribute('scale'), 1.0);
      offset = Offset(_d(vp.getAttribute('offsetX')), _d(vp.getAttribute('offsetY')));
    }

    final items = <DrawnItem>[];
    final itemsEl = root.findElements('Items').firstOrNull;
    if (itemsEl != null) {
      for (final el in itemsEl.findElements('Item')) {
        final item = await _parseItem(el);
        if (item != null) items.add(item);
      }
    }

    // Ensure future IDs don't collide with loaded ones
    for (final item in items) {
      DrawnItem.ensureIdSeqAbove(item.id);
    }

    return ProjectData(items: items, settings: settings, scale: scale, offset: offset);
  }

  static AppSettings _parseSettings(XmlElement? el) {
    if (el == null) return AppSettings();

    PaperSize paperSize = PaperSize.a4;
    try { paperSize = PaperSize.values.byName(el.getAttribute('paperSize') ?? ''); } catch (_) {}

    PaperOrientation paperOrientation = PaperOrientation.landscape;
    try { paperOrientation = PaperOrientation.values.byName(el.getAttribute('paperOrientation') ?? ''); } catch (_) {}

    CameraNumberStyle cameraNumberStyle = CameraNumberStyle.numeric;
    try { cameraNumberStyle = CameraNumberStyle.values.byName(el.getAttribute('cameraNumberStyle') ?? ''); } catch (_) {}

    final infoFields = <CameraInfoField>{};
    for (final name in (el.getAttribute('cameraInfoFields') ?? '').split(',')) {
      try { infoFields.add(CameraInfoField.values.byName(name.trim())); } catch (_) {}
    }

    return AppSettings(
      paperSize: paperSize,
      paperOrientation: paperOrientation,
      gridSize: _d(el.getAttribute('gridSize'), 20.0),
      showGrid: _b(el.getAttribute('showGrid'), true),
      snapToGrid: _b(el.getAttribute('snapToGrid'), true),
      primaryColor: _color(el.getAttribute('primaryColor'), Colors.blue),
      cameraNumberStyle: cameraNumberStyle,
      cameraInfoFields: infoFields,
      language: el.getAttribute('language') ?? 'uk',
    );
  }

  static Future<DrawnItem?> _parseItem(XmlElement el) async {
    Tool tool;
    try { tool = Tool.values.byName(el.getAttribute('tool') ?? ''); } catch (_) { return null; }

    LayerBand band = LayerBand.base;
    try { band = LayerBand.values.byName(el.getAttribute('band') ?? ''); } catch (_) {}

    final pointsEl = el.findElements('Points').firstOrNull;
    final points = <Offset>[];
    if (pointsEl != null) {
      for (final p in pointsEl.findElements('P')) {
        points.add(Offset(_d(p.getAttribute('x')), _d(p.getAttribute('y'))));
      }
    }
    if (points.isEmpty) return null;

    TextAlign textAlign = TextAlign.center;
    try { textAlign = TextAlign.values.byName(el.getAttribute('textAlign') ?? ''); } catch (_) {}

    final strokeColor = _color(el.getAttribute('strokeColor'), const Color(0xFF000000));
    final fillColor = el.getAttribute('fillColor') != null
        ? _color(el.getAttribute('fillColor'), Colors.transparent)
        : null;

    // Text content
    final textEl = el.findElements('Text').firstOrNull;
    final text = textEl?.innerText.trim();

    // Camera data
    CameraData? cameraData;
    final camEl = el.findElements('CameraData').firstOrNull;
    if (camEl != null) cameraData = _parseCameraData(camEl);

    // Actor data
    ActorData? actorData;
    final actEl = el.findElements('ActorData').firstOrNull;
    if (actEl != null) {
      actorData = ActorData(
        name: _cdata(actEl.findElements('Name').firstOrNull),
        description: _cdata(actEl.findElements('Desc').firstOrNull),
        props: _cdata(actEl.findElements('Props').firstOrNull),
      );
    }

    // Rig data
    RigData? rigData;
    final rigEl = el.findElements('RigData').firstOrNull;
    if (rigEl != null) {
      try { rigData = RigData(type: RigType.values.byName(rigEl.getAttribute('type') ?? '')); } catch (_) {}
    }

    // Raster image
    ui.Image? image;
    final imgEl = el.findElements('ImageData').firstOrNull;
    if (imgEl != null && tool == Tool.image) {
      try {
        final bytes = base64Decode(imgEl.innerText.trim());
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        image = frame.image;
      } catch (_) {}
    }

    // SVG path
    ui.Path? svgPath;
    Rect? svgPathBounds;
    String? svgPathD;
    final svgDEl = el.findElements('SvgPathD').firstOrNull;
    if (svgDEl != null && tool == Tool.svgPath) {
      svgPathD = svgDEl.innerText.trim();
      try {
        svgPath = parseSvgPathData(svgPathD);
        final boundsEl = el.findElements('SvgPathBounds').firstOrNull;
        if (boundsEl != null) {
          svgPathBounds = Rect.fromLTRB(
            _d(boundsEl.getAttribute('left')),
            _d(boundsEl.getAttribute('top')),
            _d(boundsEl.getAttribute('right')),
            _d(boundsEl.getAttribute('bottom')),
          );
        } else {
          svgPathBounds = svgPath.getBounds();
        }
      } catch (_) {}
    }

    return DrawnItem(
      tool,
      points,
      id: _i(el.getAttribute('id')),
      band: band,
      strokeWidth: _d(el.getAttribute('strokeWidth'), 3.0),
      strokeColor: strokeColor,
      fillColor: fillColor,
      lockAspect: _b(el.getAttribute('lockAspect')),
      rotation: _d(el.getAttribute('rotation')),
      opacity: _d(el.getAttribute('opacity'), 1.0),
      locked: _b(el.getAttribute('locked')),
      smoothed: _b(el.getAttribute('smoothed')),
      arrowHeadStart: _b(el.getAttribute('arrowHeadStart')),
      arrowHeadEnd: _b(el.getAttribute('arrowHeadEnd')),
      visible: _b(el.getAttribute('visible'), true),
      fontSize: _d(el.getAttribute('fontSize'), 24.0),
      bold: _b(el.getAttribute('bold')),
      italic: _b(el.getAttribute('italic')),
      textAlign: textAlign,
      groupId: el.getAttribute('groupId') != null ? _i(el.getAttribute('groupId')) : null,
      boundToId: el.getAttribute('boundToId') != null ? _i(el.getAttribute('boundToId')) : null,
      fontFamily: el.getAttribute('fontFamily'),
      text: text,
      cameraData: cameraData,
      actorData: actorData,
      rigData: rigData,
      image: image,
      svgPath: svgPath,
      svgPathD: svgPathD,
      svgPathBounds: svgPathBounds,
    );
  }

  static CameraData _parseCameraData(XmlElement el) {
    ViewfinderType viewfinder = ViewfinderType.big;
    try { viewfinder = ViewfinderType.values.byName(el.getAttribute('viewfinder') ?? ''); } catch (_) {}

    HeadphonesType headphones = HeadphonesType.double_;
    try { headphones = HeadphonesType.values.byName(el.getAttribute('headphones') ?? ''); } catch (_) {}

    final shotTypesStr = el.getAttribute('shotTypes') ?? '';
    final shotTypes = shotTypesStr.isEmpty
        ? <String>{}
        : shotTypesStr.split(',').where((s) => s.isNotEmpty).toSet();

    Offset? tableOffset;
    final tox = el.getAttribute('tableOffsetX');
    final toy = el.getAttribute('tableOffsetY');
    if (tox != null && toy != null) {
      tableOffset = Offset(_d(tox), _d(toy));
    }

    return CameraData(
      number: _i(el.getAttribute('number'), 1),
      showNumber: _b(el.getAttribute('showNumber'), true),
      cameraModel: _cdata(el.findElements('Model').firstOrNull),
      shotTypes: shotTypes,
      lens: _cdata(el.findElements('Lens').firstOrNull),
      viewfinder: viewfinder,
      headphones: headphones,
      tripod: _b(el.getAttribute('tripod')),
      tripodDescription: _cdata(el.findElements('TripodDesc').firstOrNull),
      wheels: _b(el.getAttribute('wheels')),
      podium: _b(el.getAttribute('podium')),
      podiumDescription: _cdata(el.findElements('PodiumDesc').firstOrNull),
      description: _cdata(el.findElements('Description').firstOrNull),
      tableOffset: tableOffset,
      allowResize: _b(el.getAttribute('allowResize')),
    );
  }
}
