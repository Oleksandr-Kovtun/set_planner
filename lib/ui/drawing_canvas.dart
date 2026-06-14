import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../editor_controller.dart';
import '../drawing_painter.dart';
import '../theme/app_theme.dart';

class DrawingCanvas extends StatefulWidget {
  final EditorController controller;
  const DrawingCanvas({super.key, required this.controller});
  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  double _baseScale = 1;
  Offset _baseOffset = Offset.zero;
  Offset _startFocal = Offset.zero;
  bool _zooming = false;
  bool _middlePanning = false;
  EditorController get controller => widget.controller;

  // ----- коліщатко: зум у точку курсора -----
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final dy = event.scrollDelta.dy;
      if (dy == 0) return;
      final factor = dy < 0 ? 1.12 : 1 / 1.12;
      controller.zoomBy(factor, event.localPosition);
    }
  }

  // ----- натиснуте коліщатко: панорамування -----
  void _onPointerDown(PointerDownEvent event) {
    if ((event.buttons & kMiddleMouseButton) != 0) {
      _middlePanning = true;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_middlePanning && (event.buttons & kMiddleMouseButton) != 0) {
      controller.panBy(event.delta);
    }
  }

  void _endMiddlePan() {
    _middlePanning = false;
  }

  // ----- основні жести: ЛКМ/палець — малювання; два пальці — зум -----
  void _onScaleStart(ScaleStartDetails d) {
    if (_middlePanning) return;
    _baseScale = controller.scale;
    _baseOffset = controller.offset;
    _startFocal = d.localFocalPoint;
    _zooming = false;
    if (d.pointerCount == 1) {
      controller.onPanStart(d.localFocalPoint);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    if (_middlePanning) return;
    if (d.pointerCount >= 2) {
      if (!_zooming) {
        controller.cancelDrawing();
        _zooming = true;
      }
      final newScale = _baseScale * d.scale;
      final logicalFocal = (_startFocal - _baseOffset) / _baseScale;
      final newOffset = d.localFocalPoint - logicalFocal * newScale;
      controller.setTransform(newScale, newOffset);
    } else if (!_zooming) {
      controller.onPanUpdate(d.localFocalPoint, d.focalPointDelta);
    }
  }

  void _onScaleEnd(ScaleEndDetails d) {
    if (_middlePanning) return;
    controller.onPanEnd();
  }

  @override
  Widget build(BuildContext context) {
    final canvas = Listener(
      onPointerSignal: _onPointerSignal,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerHover: (event) => controller.updatePolylineCursor(event.localPosition),
      onPointerUp: (_) => _endMiddlePan(),
      onPointerCancel: (_) => _endMiddlePan(),
      child: ClipRect(
        child: Container(
          color: AppColors.canvas,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => controller.onTap(d.localPosition),
            onDoubleTapDown: (details) =>
                controller.onDoubleTap(details.localPosition),
            onLongPressStart: (d) => controller.onLongPress(d.localPosition),
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => CustomPaint(
                painter: DrawingPainter(
                  controller.items,
                  selectedIndex: controller.selectedIndex,
                  selection: controller.selection,
                  marquee: controller.marqueeRect,
                  scale: controller.scale,
                  offset: controller.offset,
                  selectionColor: AppColors.selection,
                  rotationHandleColor: AppColors.rotationHandle,
                  editingId: controller.editingTextItem?.id,
                  gridSize: controller.settings.gridSize,
                  showGrid: controller.settings.showGrid,
                  activePolyline: controller.activePolyline,
                  polylineCursorPos: controller.polylineCursorPos,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            canvas,
            if (controller.editingTextItem != null)
              Positioned.fill(
                child: _CanvasTextEditor(
                  key: ValueKey(controller.editingTextItem!.id),
                  controller: controller,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CanvasTextEditor extends StatefulWidget {
  final EditorController controller;
  const _CanvasTextEditor({super.key, required this.controller});
  @override
  State<_CanvasTextEditor> createState() => _CanvasTextEditorState();
}

class _CanvasTextEditorState extends State<_CanvasTextEditor> {
  late final TextEditingController _tc;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final item = widget.controller.editingTextItem;
    _tc = TextEditingController(text: item?.text ?? '');
    _tc.selection = TextSelection.collapsed(offset: _tc.text.length);
    _focus.addListener(_onFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _onFocus() {
    if (!_focus.hasFocus) widget.controller.stopTextEditing();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _tc.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final item = widget.controller.editingTextItem;
        if (item == null) return const SizedBox.expand();
        final scale = widget.controller.scale;
        final offset = widget.controller.offset;
        // центр тексту на екрані (центр не зсувається під час набору)
        final sc = offset + item.bounds.center * scale;
        return Stack(
          children: [
            Positioned(
              left: sc.dx,
              top: sc.dy,
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.5), // центруємо блок на точці
                child: Transform.rotate(
                  angle: item.rotation,
                  child: IntrinsicWidth( // ширина = ширина тексту
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: 24 * scale),
                      child: TextField(
                        controller: _tc,
                        focusNode: _focus,
                        maxLines: null, // висота росте з кількістю рядків
                        textAlign: item.textAlign,
                        style: TextStyle(
                          color: item.strokeColor,
                          fontSize: item.fontSize * scale,
                          fontWeight:
                              item.bold ? FontWeight.bold : FontWeight.normal,
                          fontStyle:
                              item.italic ? FontStyle.italic : FontStyle.normal,
                          fontFamily: item.fontFamily,
                          height: 1.0,
                        ),
                        cursorColor: Colors.blue,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: widget.controller.setTextLive,
                        onTapOutside: (_) => _focus.unfocus(), // клік поза полем завершує редагування
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}