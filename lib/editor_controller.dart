import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models.dart';
import 'models/settings.dart';

enum _Interaction { none, drawing, moving, resizing, rotating, marquee }

class EditorController extends ChangeNotifier {
  static const double handleRadius = 25;
  static const double rotationHandleOffset = 40;
  static const double minScale = 0.25;
  static const double maxScale = 4.0;

  Tool _currentTool = Tool.pen;
  Tool get currentTool => _currentTool;

  final List<DrawnItem> _items = [];
  List<DrawnItem> get items => _items;

  // ---- вибір (множина індексів) ----
  final Set<int> _selection = {};
  Set<int> get selection => _selection;
  int? get selectedIndex => _selection.length == 1 ? _selection.first : null;
  DrawnItem? get selectedItem {
    final i = selectedIndex;
    return i == null ? null : _items[i];
  }
  List<DrawnItem> get selectedItems {
    final idx = _selection.toList()..sort();
    return [for (final i in idx) _items[i]];
  }
  bool get hasSelection => _selection.isNotEmpty;
  bool get isMultiSelection => _selection.length > 1;
  bool get selectionIsGroup {
    if (_selection.length < 2) return false;
    final g = _items[_selection.first].groupId;
    if (g == null) return false;
    return _selection.every((i) => _items[i].groupId == g);
  }
  void _setSelection(Iterable<int> idx) => _selection..clear()..addAll(idx);

  // ---- рамка виділення ----
  Offset? _marqueeStart, _marqueeCurrent;
  Rect? get marqueeRect => (_marqueeStart != null && _marqueeCurrent != null)
      ? Rect.fromPoints(_marqueeStart!, _marqueeCurrent!)
      : null;

  double _scale = 1.0;
  double get scale => _scale;
  Offset _offset = Offset.zero;
  Offset get offset => _offset;

  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  _Interaction _interaction = _Interaction.none;
  int _resizeHandle = 0;
  Offset _handleFactor = Offset.zero;
  Offset? _groupPivot;
  double? _groupPrevAngle;
  bool _editSnapshotTaken = false;
  DrawnItem? _activeItem;
  int _nextGroupId = 1;

  final List<List<DrawnItem>> _undoStack = [];
  final List<List<DrawnItem>> _redoStack = [];
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  List<DrawnItem> _snapshot() => _items.map((e) => e.copy()).toList();
  void _pushUndo() {
    _undoStack.add(_snapshot());
    _redoStack.clear();
  }

  void beginPropertyEdit() => _pushUndo();

  void selectTool(Tool tool) {
    _currentTool = tool;
    if (tool != Tool.select && tool != Tool.lasso) _selection.clear();
    notifyListeners();
  }

  bool get _additivePressed =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isMetaPressed;

  // ---- Text Editing ----
  int? _editingTextId;
  bool get isEditingText => _editingTextId != null;
  DrawnItem? get editingTextItem {
    if (_editingTextId == null) return null;
    for (final it in _items) {
      if (it.id == _editingTextId && it.tool == Tool.text) return it;
    }
    return null;
  }

  void startTextEditing(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].tool != Tool.text || _items[index].locked) return;
    _editingTextId = _items[index].id;
    notifyListeners();
  }

  void stopTextEditing() {
    if (_editingTextId == null) return;
    _editingTextId = null;
    notifyListeners();
  }

  int? _textItemAt(Offset canvasP) {
    for (int i = _items.length - 1; i >= 0; i--) {
      final it = _items[i];
      if (it.tool != Tool.text) continue;
      if (it.bounds.inflate(8).contains(_toLocal(it, canvasP))) return i;
    }
    return null;
  }

  // ---- групи ----
  List<int> _groupMembers(int index) {
    final g = _items[index].groupId;
    if (g == null) return [index];
    final out = <int>[];
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].groupId == g) out.add(i);
    }
    return out;
  }

  void groupSelection() {
    if (_selection.length < 2) return;
    _pushUndo();
    final g = _nextGroupId++;
    for (final i in _selection) {
      _items[i].groupId = g;
    }
    notifyListeners();
  }

  void ungroupSelection() {
    if (_selection.isEmpty) return;
    _pushUndo();
    for (final i in _selection) {
      _items[i].groupId = null;
    }
    notifyListeners();
  }

  // ---- z-рівні (бенди) ----
  void _insertByBand(DrawnItem item) {
    int pos = _items.length;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].band.index > item.band.index) {
        pos = i;
        break;
      }
    }
    _items.insert(pos, item);
  }

  ({int start, int end}) _bandRange(LayerBand band) {
    int start = -1, end = -1;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].band == band) {
        if (start == -1) start = i;
        end = i;
      }
    }
    return (start: start, end: end);
  }

  void bringForward() {
    final i = selectedIndex;
    if (i == null) return;
    final item = _items[i];
    if (i + 1 < _items.length && _items[i + 1].band == item.band) {
      _pushUndo();
      _items[i] = _items[i + 1];
      _items[i + 1] = item;
      _setSelection({i + 1});
      notifyListeners();
    }
  }

  void sendBackward() {
    final i = selectedIndex;
    if (i == null) return;
    final item = _items[i];
    if (i - 1 >= 0 && _items[i - 1].band == item.band) {
      _pushUndo();
      _items[i] = _items[i - 1];
      _items[i - 1] = item;
      _setSelection({i - 1});
      notifyListeners();
    }
  }

  void bringToFront() {
    final i = selectedIndex;
    if (i == null) return;
    final item = _items[i];
    final r = _bandRange(item.band);
    if (i == r.end) return;
    _pushUndo();
    _items.removeAt(i);
    _items.insert(r.end, item);
    _setSelection({r.end});
    notifyListeners();
  }

  void sendToBack() {
    final i = selectedIndex;
    if (i == null) return;
    final item = _items[i];
    final r = _bandRange(item.band);
    if (i == r.start) return;
    _pushUndo();
    _items.removeAt(i);
    _items.insert(r.start, item);
    _setSelection({r.start});
    notifyListeners();
  }

  void addSvg(ui.Picture picture, Size size) {
    double w = size.width, h = size.height;
    if (w <= 0 || h <= 0) { w = 200; h = 200; }
    const maxSide = 300.0;
    final fit = math.min(maxSide / w, maxSide / h);
    final tw = w * fit, th = h * fit;
    _pushUndo();
    final item = DrawnItem(
      Tool.svg,
      [const Offset(40, 40), Offset(40 + tw, 40 + th)],
      svgPicture: picture,
      svgSize: size,
    );
    _insertByBand(item);
    _setSelection({_items.indexOf(item)});
    _currentTool = Tool.select;
    notifyListeners();
  }

  void addItems(List<DrawnItem> items) {
    if (items.isEmpty) return;
    _pushUndo();
    // якщо елементів кілька — одразу обʼєднуємо їх у групу
    final int? g = items.length >= 2 ? _nextGroupId++ : null;
    for (final it in items) {
      it.groupId = g;
      _insertByBand(it);
    }
    _setSelection({for (final it in items) _items.indexOf(it)});
    _currentTool = Tool.select;
    notifyListeners();
  }

  void addImage(ui.Image image) {
    final w = image.width.toDouble(), h = image.height.toDouble();
    const maxSide = 400.0;
    final fit = (w <= 0 || h <= 0) ? 1.0 : maxSide / math.max(w, h);
    final tw = w * fit, th = h * fit;
    _pushUndo();
    final item = DrawnItem(
      Tool.image,
      [const Offset(40, 40), Offset(40 + tw, 40 + th)],
      image: image,
    );
    _insertByBand(item);
    _setSelection({_items.indexOf(item)});
    _currentTool = Tool.select;
    notifyListeners();
  }

  // ---- масштаб / зсув ----
  void setScale(double v) {
    final c = v.clamp(minScale, maxScale);
    if (c == _scale) return;
    _scale = c;
    notifyListeners();
  }

  void setTransform(double newScale, Offset newOffset) {
    _scale = newScale.clamp(minScale, maxScale);
    _offset = newOffset;
    notifyListeners();
  }

  void resetScale() {
    _scale = 1.0;
    _offset = Offset.zero;
    notifyListeners();
  }

  void zoomBy(double factor, Offset focalScreen) {
    final oldScale = _scale;
    final newScale = (oldScale * factor).clamp(minScale, maxScale);
    if (newScale == oldScale) return;
    final logical = (focalScreen - _offset) / oldScale;
    _offset = focalScreen - logical * newScale;
    _scale = newScale;
    notifyListeners();
  }

  void panBy(Offset screenDelta) {
    _offset += screenDelta;
    notifyListeners();
  }

  void updateSettings(AppSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  Offset _snapToGrid(Offset p) {
    if (!_settings.snapToGrid) return p;
    final gridSize = _settings.gridSize;
    return Offset(
      (p.dx / gridSize).round() * gridSize,
      (p.dy / gridSize).round() * gridSize,
    );
  }

  Offset _screenToCanvas(Offset screen) => (screen - _offset) / _scale;
  double get _hitRadius => handleRadius / _scale;
  Offset _toLocal(DrawnItem item, Offset p) =>
      rotateAround(p, item.bounds.center, -item.rotation);

  Offset _rotationHandlePos(DrawnItem item) {
    final center = item.bounds.center;
    final local = Offset(center.dx,
        item.bounds.inflate(selectionPadding).top - rotationHandleOffset / _scale);
    return rotateAround(local, center, item.rotation);
  }

  Offset _boxHandlePos(Rect box, Offset f) =>
      Offset(box.left + f.dx * box.width, box.top + f.dy * box.height);

  int? _itemAt(Offset canvasP) {
    for (int i = _items.length - 1; i >= 0; i--) {
      final it = _items[i];
      if (it.bounds.inflate(8).contains(_toLocal(it, canvasP))) return i;
    }
    return null;
  }

  void onTap(Offset screenP) {
    if (_currentTool == Tool.text) {
      _addFreeText(_screenToCanvas(screenP));
      return;
    }
    if (_currentTool != Tool.select && _currentTool != Tool.lasso) return;
    final p = _screenToCanvas(screenP);
    final hit = _itemAt(p);
    if (hit == null) {
      if (!_additivePressed && _selection.isNotEmpty) {
        _selection.clear();
        notifyListeners();
      }
      return;
    }
    final members = _groupMembers(hit);
    if (_additivePressed) {
      if (members.every(_selection.contains)) {
        _selection.removeAll(members);
      } else {
        _selection.addAll(members);
      }
    } else {
      _setSelection(members);
    }
    notifyListeners();
  }
  

  void onPanStart(Offset screenP) {
    _editSnapshotTaken = false;
    final p = _screenToCanvas(screenP);
    if (_currentTool == Tool.lasso) {
      _marqueeStart = p;
      _marqueeCurrent = p;
      _interaction = _Interaction.marquee;
      notifyListeners();
    } else if (_currentTool == Tool.select) {
      _handleSelectStart(p);
    } else if (_currentTool == Tool.text) {
      // створення тексту — по тапу (onTap)
    } else {
      _startDrawing(p);
    }
  }


  void onPanUpdate(Offset screenP, Offset screenDelta) {
    final p = _screenToCanvas(screenP);
    final delta = screenDelta / _scale;
    switch (_interaction) {
      case _Interaction.drawing:
        _extendDrawing(p);
      case _Interaction.moving:
        _moveSelected(delta);
      case _Interaction.resizing:
        _resizeSelected(delta);
      case _Interaction.rotating:
        _rotateSelected(p);
      case _Interaction.marquee:
        _marqueeCurrent = p;
        notifyListeners();
      case _Interaction.none:
        break;
    }
  }

  void onPanEnd() {
    if (_interaction == _Interaction.marquee) {
      final rect = marqueeRect;
      if (rect != null && (rect.width.abs() + rect.height.abs()) > 4) {
        _selectInRect(rect, additive: _additivePressed);
      }
      _marqueeStart = null;
      _marqueeCurrent = null;
      _interaction = _Interaction.none;
      notifyListeners();
      return;
    }

    final wasDrawing = _interaction == _Interaction.drawing;
    final wasMoving = _interaction == _Interaction.moving;
    final item = _activeItem;
    if (wasDrawing && item != null) {
      bool removed = false;
      if (item.tool == Tool.pen) {
        if (item.points.length < 2) {
          _items.remove(item);
          if (_undoStack.isNotEmpty) _undoStack.removeLast();
          removed = true;
        } 
      }
      if (!removed) {
        final idx = _items.indexOf(item);
        if (idx != -1) _setSelection({idx});
        _currentTool = Tool.select; // після малювання — у режим вибору
      }
      notifyListeners();
    } else if (wasMoving && _settings.snapToGrid) {
      // Привязуємо всі переміщені елементи до сітки
      for (final i in _selection) {
        if (!_items[i].locked) {
          for (int k = 0; k < _items[i].points.length; k++) {
            _items[i].points[k] = _snapToGrid(_items[i].points[k]);
          }
        }
      }
      notifyListeners();
    }
    _activeItem = null;
    _interaction = _Interaction.none;
    _editSnapshotTaken = false;
  }

  void cancelDrawing() {
    final item = _activeItem;
    if (_interaction == _Interaction.drawing && item != null) {
      _items.remove(item);
      if (_undoStack.isNotEmpty) _undoStack.removeLast();
      _activeItem = null;
      _interaction = _Interaction.none;
      notifyListeners();
    }
  }

  void _selectInRect(Rect rect, {bool additive = false}) {
    if (!additive) _selection.clear();
    final r = Rect.fromLTRB(
      math.min(rect.left, rect.right),
      math.min(rect.top, rect.bottom),
      math.max(rect.left, rect.right),
      math.max(rect.top, rect.bottom),
    );
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].bounds.overlaps(r)) _selection.add(i);
    }
    _expandGroups();
  }

  void _expandGroups() {
    final groups = <int>{};
    for (final i in _selection) {
      final g = _items[i].groupId;
      if (g != null) groups.add(g);
    }
    if (groups.isEmpty) return;
    for (int i = 0; i < _items.length; i++) {
      final g = _items[i].groupId;
      if (g != null && groups.contains(g)) _selection.add(i);
    }
  }

  void _simplifyPen(DrawnItem item) {
    final raw = item.points;
    if (raw.length <= 3) return;
    const minDist = 32.0;
    final simplified = <Offset>[raw.first];
    for (int i = 1; i < raw.length - 1; i++) {
      if ((raw[i] - simplified.last).distance >= minDist) {
        simplified.add(raw[i]);
      }
    }
    simplified.add(raw.last);
    item.points
      ..clear()
      ..addAll(simplified);
  }

  void _startDrawing(Offset p) {
    _pushUndo();
    final snappedP = _snapToGrid(p);
    final item = (_currentTool == Tool.pen)
        ? DrawnItem(Tool.pen, [snappedP])
        : DrawnItem(_currentTool, [snappedP, snappedP]);
    _insertByBand(item);
    _activeItem = item;
    _interaction = _Interaction.drawing;
    notifyListeners();
  }

  void _extendDrawing(Offset p) {
    final item = _activeItem;
    if (item == null) return;
    final snappedP = _snapToGrid(p);
    if (item.tool == Tool.pen) {
      item.points.add(snappedP);
    } else {
      item.points[1] = snappedP;
      item.applyAspectLock();
    }
    notifyListeners();
  }

  void _handleSelectStart(Offset p) {
    // ===== кілька вибраних (група) =====
    if (isMultiSelection) {
      final gb = _groupBounds();
      if (gb != null) {
        if ((_groupRotationHandlePos(gb) - p).distance <= _hitRadius) {
          _interaction = _Interaction.rotating;
          _groupPivot = gb.center;
          _groupPrevAngle = math.atan2(p.dy - gb.center.dy, p.dx - gb.center.dx);
          return;
        }
        final box = gb.inflate(selectionPadding);
        for (final f in boxHandleFactors) {
          if ((_boxHandlePos(box, f) - p).distance <= _hitRadius) {
            _interaction = _Interaction.resizing;
            _handleFactor = f;
            return;
          }
        }
      }
      final hit = _itemAt(p);
      if (hit != null) {
        if (_additivePressed) {
          _selection.addAll(_groupMembers(hit));
        } else if (!_selection.contains(hit)) {
          _setSelection(_groupMembers(hit));
        }
        _interaction = _Interaction.moving;
        notifyListeners();
        return;
      }
      _startMarquee(p); // порожнє місце → рамкове виділення
      return;
    }

    // ===== одна фігура =====
    final sel = selectedItem;
    if (sel != null && sel.points.length >= 2 && !sel.locked) {
      if ((_rotationHandlePos(sel) - p).distance <= _hitRadius) {
        _interaction = _Interaction.rotating;
        return;
      }
      final localP = _toLocal(sel, p);
      if (sel.tool != Tool.text) {
        if (toolIsBox(sel.tool)) {
          final box = sel.bounds.inflate(selectionPadding);
          for (final f in boxHandleFactors) {
            if ((_boxHandlePos(box, f) - localP).distance <= _hitRadius) {
              _interaction = _Interaction.resizing;
              _handleFactor = f;
              return;
            }
          }
        } else {
          for (int i = 0; i < sel.points.length; i++) {
            if ((sel.points[i] - localP).distance <= _hitRadius) {
              _interaction = _Interaction.resizing;
              _resizeHandle = i;
              return;
            }
          }
        }
      }
    }
    final hit = _itemAt(p);
    if (hit != null) {
      final members = _groupMembers(hit);
      if (_additivePressed) {
        _selection.addAll(members);
      } else if (!_selection.contains(hit)) {
        _setSelection(members);
      }
      _interaction = _Interaction.moving;
      notifyListeners();
      return;
    }
    _startMarquee(p); // порожнє місце → рамкове виділення
  }

  void _startMarquee(Offset p) {
    _marqueeStart = p;
    _marqueeCurrent = p;
    _interaction = _Interaction.marquee;
    notifyListeners();
  }

  void _moveSelected(Offset delta) {
    final movable = [for (final i in _selection) if (!_items[i].locked) i];
    if (movable.isEmpty) return;
    if (!_editSnapshotTaken) { _pushUndo(); _editSnapshotTaken = true; }
    final movedIds = <int>{};
    for (final i in movable) {
      _translate(_items[i], delta);
      movedIds.add(_items[i].id);
    }
    for (int i = 0; i < _items.length; i++) {
      final t = _items[i];
      if (t.tool == Tool.text &&
          t.boundToId != null &&
          movedIds.contains(t.boundToId) &&
          !_selection.contains(i) &&
          !t.locked) {
        _translate(t, delta);
      }
    }
    notifyListeners();
  }

  void _resizeSelected(Offset delta) {
    if (!_editSnapshotTaken) { _pushUndo(); _editSnapshotTaken = true; }
    if (isMultiSelection) {
      _resizeGroup(delta);
      return;
    }
    final item = selectedItem;
    if (item == null || item.locked) return;
    final localDelta = rotateAround(delta, Offset.zero, -item.rotation);
    if (toolIsBox(item.tool)) {
      _resizeBox(item, localDelta);
    } else {
      item.points[_resizeHandle] = item.points[_resizeHandle] + localDelta;
    }
    notifyListeners();
  }

  void _rotateSelected(Offset p) {
    if (!_editSnapshotTaken) { _pushUndo(); _editSnapshotTaken = true; }
    if (isMultiSelection) {
      _rotateGroup(p);
      return;
    }
    final item = selectedItem;
    if (item == null || item.locked) return;
    final center = item.bounds.center;
    final angle = math.atan2(p.dy - center.dy, p.dx - center.dx);
    item.rotation = angle + math.pi / 2;
    notifyListeners();
  }

  void _resizeBox(DrawnItem item, Offset d) {
    final f = _handleFactor;
    final before = item.bounds;
    final anchorLocal = _boxHandlePos(before, Offset(1 - f.dx, 1 - f.dy));
    final worldBefore = rotateAround(anchorLocal, before.center, item.rotation);

    double l = before.left, t = before.top, r = before.right, b = before.bottom;
    if (f.dx == 0) {
      l += d.dx;
    } else if (f.dx == 1) {
      r += d.dx;
    }
    if (f.dy == 0) {
      t += d.dy;
    } else if (f.dy == 1) {
      b += d.dy;
    }

    if (item.lockAspect && toolSupportsAspectLock(item.tool)) {
      final ratio = item.targetAspectRatio;
      final movesX = f.dx != 0.5;
      final movesY = f.dy != 0.5;
      if (movesX && movesY) {
        final ax = (f.dx == 0) ? r : l;
        final ay = (f.dy == 0) ? b : t;
        final mx = (f.dx == 0) ? l : r;
        final my = (f.dy == 0) ? t : b;
        final sw = mx - ax, sh = my - ay;
        double w, h;
        if (sw.abs() >= sh.abs() * ratio) {
          w = sw.abs();
          h = w / ratio;
        } else {
          h = sh.abs();
          w = h * ratio;
        }
        final nmx = ax + (sw.isNegative ? -w : w);
        final nmy = ay + (sh.isNegative ? -h : h);
        if (f.dx == 0) { l = nmx; } else { r = nmx; }
        if (f.dy == 0) { t = nmy; } else { b = nmy; }
      } else if (movesX) {
        final ax = (f.dx == 0) ? r : l;
        final mx = (f.dx == 0) ? l : r;
        final w = (mx - ax).abs();
        final h = w / ratio;
        final cy = (before.top + before.bottom) / 2;
        t = cy - h / 2;
        b = cy + h / 2;
      } else if (movesY) {
        final ay = (f.dy == 0) ? b : t;
        final my = (f.dy == 0) ? t : b;
        final h = (my - ay).abs();
        final w = h * ratio;
        final cx = (before.left + before.right) / 2;
        l = cx - w / 2;
        r = cx + w / 2;
      }
    }

    final after = Rect.fromLTRB(l, t, r, b);
    final worldAfter = rotateAround(anchorLocal, after.center, item.rotation);
    final shift = worldBefore - worldAfter;

    item.points[0] = Offset(after.left, after.top) + shift;
    item.points[1] = Offset(after.right, after.bottom) + shift;
  }

  Rect? _groupBounds() {
    Rect? r;
    for (final i in _selection) {
      final b = _items[i].visualBounds;
      r = (r == null) ? b : r.expandToInclude(b);
    }
    return r;
  }

  Offset _groupRotationHandlePos(Rect gb) {
    final box = gb.inflate(selectionPadding);
    return Offset(box.center.dx, box.top - rotationHandleOffset / _scale);
  }

  // Пропорційне (рівномірне) масштабування групи навколо протилежної ручки.
  void _resizeGroup(Offset delta) {
    final gb = _groupBounds();
    if (gb == null) return;
    final f = _handleFactor;
    final box = gb.inflate(selectionPadding);
    final anchor = _boxHandlePos(box, Offset(1 - f.dx, 1 - f.dy));
    final handlePos = _boxHandlePos(box, f);
    final v0 = handlePos - anchor;
    if (v0.distance < 1) return;
    final v1 = v0 + delta;
    final s = v1.distance / v0.distance;
    if (!s.isFinite || s <= 0.01 || s > 50) return;
    for (final i in _selection) {
      final item = _items[i];
      if (item.locked) continue;
      for (int k = 0; k < item.points.length; k++) {
        final p = item.points[k];
        item.points[k] = Offset(
          anchor.dx + (p.dx - anchor.dx) * s,
          anchor.dy + (p.dy - anchor.dy) * s,
        );
      }
    }
    notifyListeners();
  }

  // Обертання всієї групи навколо її центра.
  void _rotateGroup(Offset p) {
    final pivot = _groupPivot;
    final prev = _groupPrevAngle;
    if (pivot == null || prev == null) return;
    final ang = math.atan2(p.dy - pivot.dy, p.dx - pivot.dx);
    final d = ang - prev;
    if (d == 0) return;
    for (final i in _selection) {
      final item = _items[i];
      if (item.locked) continue;
      final c = item.bounds.center;
      final t = rotateAround(c, pivot, d) - c; // центр рухається по дузі навколо pivot
      for (int k = 0; k < item.points.length; k++) {
        item.points[k] = item.points[k] + t;
      }
      item.rotation += d;
    }
    _groupPrevAngle = ang;
    notifyListeners();
  }

  void onDoubleTap(Offset screenP) {
    if (_currentTool != Tool.select && _currentTool != Tool.lasso) return;
    final p = _screenToCanvas(screenP);
    // 1) подвійний клік по тексту → редагування на канвасі
    final textIdx = _textItemAt(p);
    if (textIdx != null && !_items[textIdx].locked) {
      _setSelection({textIdx});
      startTextEditing(textIdx);
      return;
    }
    // 2) видалити вузол пера
    final sel = selectedItem;
    if (sel != null && sel.tool == Tool.pen && sel.points.length > 2) {
      final localP = _toLocal(sel, p);
      for (int i = 0; i < sel.points.length; i++) {
        if ((sel.points[i] - localP).distance <= _hitRadius) {
          _pushUndo();
          sel.points.removeAt(i);
          notifyListeners();
          return;
        }
      }
    }
    // 3) подвійний клік по фігурі → додати привʼязаний текст
    final hit = _itemAtExcludingText(p);
    if (hit != null) _addBoundText(hit);
  }

  void onLongPress(Offset screenP) {
    if (_currentTool != Tool.select && _currentTool != Tool.lasso) return;
    final p = _screenToCanvas(screenP);
    for (int i = _items.length - 1; i >= 0; i--) {
      final it = _items[i];
      if (it.locked) continue;
      if (it.tool != Tool.line && it.tool != Tool.arrow && it.tool != Tool.pen) {
        continue;
      }
      final localP = _toLocal(it, p);
      final idx = _curvePointInsertIndex(it, localP, _hitRadius);
      if (idx >= 0) {
        _pushUndo();
        it.points.insert(idx, localP); // крива проходитиме через нову точку
        _setSelection({i});
        notifyListeners();
        return;
      }
    }
  }

  // Чи малюється елемент як гладка крива (а не прямі відрізки)?
  bool _renderAsCurve(DrawnItem it) {
    if (it.tool == Tool.line || it.tool == Tool.arrow) return it.points.length > 2;
    if (it.tool == Tool.pen) return it.smoothed;
    return false;
  }

  // Знаходить, у яке місце послідовності вставити точку, якщо натиск близько до лінії/кривої.
  // Повертає індекс вставки або -1, якщо не влучили.
  int _curvePointInsertIndex(DrawnItem item, Offset localP, double tol) {
    final pts = item.points;
    if (pts.length < 2) return -1;
    final curve = _renderAsCurve(item);
    const steps = 12;
    double best = double.infinity;
    int bestSeg = -1;
    for (int i = 0; i < pts.length - 1; i++) {
      Offset sampleAt(double t) {
        if (!curve) return Offset.lerp(pts[i], pts[i + 1], t)!;
        final p0 = (i == 0) ? pts[0] : pts[i - 1];
        final p1 = pts[i];
        final p2 = pts[i + 1];
        final p3 = (i + 2 < pts.length) ? pts[i + 2] : pts[i + 1];
        final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
        final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
        return _cubic(p1, cp1, cp2, p2, t);
      }
      for (int s = 0; s <= steps; s++) {
        final d = (sampleAt(s / steps) - localP).distance;
        if (d < best) {
          best = d;
          bestSeg = i;
        }
      }
    }
    if (best <= tol && bestSeg >= 0) return bestSeg + 1;
    return -1;
  }

  // Точка на кубічній кривій Безьє (та сама формула, що й при малюванні).
  Offset _cubic(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t;
    return Offset(
      a * p0.dx + b * p1.dx + c * p2.dx + d * p3.dx,
      a * p0.dy + b * p1.dy + c * p2.dy + d * p3.dy,
    );
  }

  void setArrowHeadStart(bool v) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.arrow || it.locked) return;
    _pushUndo(); it.arrowHeadStart = v; notifyListeners();
  }

  void setArrowHeadEnd(bool v) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.arrow || it.locked) return;
    _pushUndo(); it.arrowHeadEnd = v; notifyListeners();
  }
  
  void convertSelectedToCurve() {
    final it = selectedItem;
    if (it == null || it.tool != Tool.pen || it.smoothed || it.locked) return;
    _pushUndo();
    _simplifyPen(it);
    it.smoothed = true;
    notifyListeners();
  }
  // ---- властивості (застосовуються до всіх вибраних) ----
  void setStrokeWidth(double w) {
    final targets = [for (final i in _selection) if (!_items[i].locked) i];
    if (targets.isEmpty) return;
    for (final i in targets) {
      _items[i].strokeWidth = w;
    }
    notifyListeners();
  }
  void setStrokeColor(Color c) {
    final targets = [for (final i in _selection) if (!_items[i].locked) i];
    if (targets.isEmpty) return;
    _pushUndo();
    for (final i in targets) {
      _items[i].strokeColor = c;
    }
    notifyListeners();
  }
  void setFillColor(Color? c) {
    final targets = [for (final i in _selection) if (!_items[i].locked) i];
    if (targets.isEmpty) return;
    _pushUndo();
    for (final i in targets) {
      _items[i].fillColor = c;
    }
    notifyListeners();
  }
  
  void setLocked(bool v) {
    if (_selection.isEmpty) return;
    _pushUndo();
    for (final i in _selection) {
      _items[i].locked = v;
    }
    notifyListeners();
  }

  void setLockAspect(bool v) {
    final it = selectedItem; if (it == null) return;
    _pushUndo(); it.lockAspect = v; it.applyAspectLock(); notifyListeners();
  }

  void setRotationDegrees(double degrees) {
    final it = selectedItem; if (it == null) return;
    final newRotation = degrees * math.pi / 180;
    if (it.rotation == newRotation) return;
    _pushUndo();
    it.rotation = newRotation;
    notifyListeners();
  }

  void setOpacity(double v) {
    final it = selectedItem;
    if (it == null || it.locked) return;
    it.opacity = v.clamp(0.0, 1.0);
    notifyListeners();
  }

  void _translate(DrawnItem item, Offset delta) {
    for (int k = 0; k < item.points.length; k++) {
      item.points[k] = item.points[k] + delta;
    }
  }

  int? _itemAtExcludingText(Offset canvasP) {
    for (int i = _items.length - 1; i >= 0; i--) {
      final it = _items[i];
      if (it.tool == Tool.text) continue;
      if (it.bounds.inflate(8).contains(_toLocal(it, canvasP))) return i;
    }
    return null;
  }

  TextStyle _textStyle(DrawnItem item) => TextStyle(
        color: item.strokeColor,
        fontSize: item.fontSize,
        fontWeight: item.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: item.italic ? FontStyle.italic : FontStyle.normal,
        fontFamily: item.fontFamily,
      );

  Size _measureText(DrawnItem item) {
    final tp = TextPainter(
      text: TextSpan(
        text: (item.text ?? '').isEmpty ? ' ' : item.text,
        style: _textStyle(item),
      ),
      textAlign: item.textAlign,
      textDirection: TextDirection.ltr,
    )..layout();
    return Size(tp.width < 8 ? 8 : tp.width, tp.height < 8 ? 8 : tp.height);
  }

  // Перерахунок розмірів текстового поля (зберігаючи його центр).
  void _remeasureText(DrawnItem item) {
    final size = _measureText(item);
    final center = item.points.length >= 2 ? item.bounds.center : item.points.first;
    item.points
      ..clear()
      ..add(Offset(center.dx - size.width / 2, center.dy - size.height / 2))
      ..add(Offset(center.dx + size.width / 2, center.dy + size.height / 2));
  }

  DrawnItem _makeTextItem({
    required Offset center,
    int? boundToId,
    required LayerBand band,
  }) {
    return DrawnItem(
      Tool.text,
      [center, center],
      strokeColor: const Color(0xFF000000),
      text: 'Текст',
      boundToId: boundToId,
      band: band,
    );
  }

  void _addBoundText(int shapeIndex) {
    final shape = _items[shapeIndex];
    _pushUndo();
    final t = _makeTextItem(
        center: shape.bounds.center, boundToId: shape.id, band: shape.band);
    _remeasureText(t);
    _items.insert(shapeIndex + 1, t);
    final idx = shapeIndex + 1;
    _setSelection({idx});
    _currentTool = Tool.select;
    startTextEditing(idx);
  }

  void _addFreeText(Offset canvasP) {
    _pushUndo();
    final t = _makeTextItem(center: canvasP, boundToId: null, band: LayerBand.base);
    _remeasureText(t);
    _insertByBand(t);
    final idx = _items.indexOf(t);
    _setSelection({idx});
    _currentTool = Tool.select;
    startTextEditing(idx);
  }

  // ---- властивості тексту ----
  void setTextLive(String s) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.text) return;
    it.text = s;
    _remeasureText(it);
    notifyListeners();
  }
  void setFontSize(double v) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.text) return;
    it.fontSize = v;
    _remeasureText(it);
    notifyListeners();
  }
  void setBold(bool v) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.text) return;
    _pushUndo(); it.bold = v; _remeasureText(it); notifyListeners();
  }
  void setItalic(bool v) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.text) return;
    _pushUndo(); it.italic = v; _remeasureText(it); notifyListeners();
  }
  void setFontFamily(String? f) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.text) return;
    _pushUndo(); it.fontFamily = f; _remeasureText(it); notifyListeners();
  }
  void setTextAlign(TextAlign a) {
    final it = selectedItem;
    if (it == null || it.tool != Tool.text) return;
    _pushUndo(); it.textAlign = a; notifyListeners();
  }

  // ---- Видалення вибраних елементів ----
  void deleteSelected() {
    if (_selection.isEmpty) return;
    _editingTextId = null;
    final idx = [for (final i in _selection) if (!_items[i].locked) i]
      ..sort((a, b) => b.compareTo(a));
    if (idx.isEmpty) return;
    _pushUndo();
    for (final i in idx) {
      _items.removeAt(i);
    }
    _selection.clear();
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _editingTextId = null;
    _pushUndo();
    _items.clear();
    _selection.clear();
    notifyListeners();
  }

  void undo() {
    if (!canUndo) return;
    _editingTextId = null;
    _redoStack.add(_snapshot());
    final previous = _undoStack.removeLast();
    _items..clear()..addAll(previous);
    _selection.clear();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _editingTextId = null;
    _undoStack.add(_snapshot());
    final next = _redoStack.removeLast();
    _items..clear()..addAll(next);
    _selection.clear();
    notifyListeners();
  }
}