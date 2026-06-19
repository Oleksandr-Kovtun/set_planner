import 'package:flutter/material.dart';
import '../editor_controller.dart';
import '../models.dart';
import '../l10n/app_strings.dart';
import 'package:file_selector/file_selector.dart';
import '../svg_import.dart';
import '../theme/app_theme.dart';

class ToolBar extends StatelessWidget {
  final EditorController controller;
  const ToolBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.toolBar,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Row(
          children: [
            const SizedBox(width: 8),
            _toolButton(Tool.select, Icons.near_me, strings.cursorMode),
            _divider(),
            _toolButton(Tool.lasso, Icons.highlight_alt, strings.selectMode),
            _divider(),
            IconButton(
              tooltip: strings.importSvg,
              onPressed: () => _importSvg(context),
              icon: const Icon(Icons.upload_file),
              color: AppColors.icon
            ),
            IconButton(
              tooltip: strings.importImage,
              onPressed: () => _importImage(context),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              color: AppColors.icon,
            ),
            _divider(),
            _toolButton(Tool.pen, Icons.gesture, strings.freeDraw),
            _toolButton(Tool.polyline, Icons.polyline, strings.toolPolyline),
            _divider(),
            _shapesMenu(),
            _divider(),
            _toolButton(Tool.camera, Icons.videocam, strings.cameras),
            _divider(),
            _rigsMenu(),
            _divider(),
            _toolButton(Tool.actor, Icons.person, strings.actors),
            _divider(),
            _toolButton(Tool.text, Icons.title, strings.textTool),
            const Spacer(),
            IconButton(
              tooltip: strings.clearAll,
              onPressed: () => _confirmClear(context),
              icon: const Icon(Icons.delete_outline),
              color: AppColors.icon,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _toolButton(Tool tool, IconData icon, String tooltip) {
    final selected = controller.currentTool == tool;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => controller.selectTool(tool),
      icon: Icon(icon),
      color: selected ? AppColors.accent : AppColors.icon,
    );
  }

  Widget _shapesMenu() {
    final active = shapeTools.contains(controller.currentTool);
    final color = active ? AppColors.accent : AppColors.icon;
    final icon = active ? toolIcon(controller.currentTool) : Icons.category_outlined;
    return PopupMenuButton<Tool>(
      color:AppColors.panel,
      tooltip: strings.shapes,
      onSelected: controller.selectTool,
      itemBuilder: (context) => [
        for (final t in shapeTools)
          PopupMenuItem<Tool>(
            value: t,
            child: Row(children: [
              Icon(toolIcon(t), size: 20),
              const SizedBox(width: 8),
              Text(strings.toolLabel(t)),
            ]),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color),
          Icon(Icons.arrow_drop_up, color: color),
        ]),
      ),
    );
  }

  Widget _rigsMenu() {
    final active = controller.currentTool == Tool.rig;
    final color = active ? AppColors.accent : AppColors.icon;
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () async {
          final result = await showDialog<RigType>(
            context: context,
            builder: (_) => _RigPickerDialog(currentType: controller.rigType),
          );
          if (result != null) controller.selectRigTool(result);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.movie_filter, color: color),
            Icon(Icons.arrow_drop_up, color: color),
          ]),
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 32, color: Colors.white24,
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(strings.clearTitle),
        content: Text(strings.clearMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(strings.clear)),
        ],
      ),
    );
    if (confirmed == true) controller.clear();
  }

  Future<void> _importSvg(BuildContext context) async {
    try {
      const typeGroup = XTypeGroup(
        label: 'SVG',
        extensions: ['svg'],
        uniformTypeIdentifiers: ['public.svg-image'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final svgString = await file.readAsString();
      final items = svgToItems(svgString);
      if (items.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(strings.svgImportError)),
          );
        }
        return;
      }
      controller.addItems(items);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.svgImportError)),
        );
      }
    }
  }
  
  Future<void> _importImage(BuildContext context) async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Images',
        extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
        uniformTypeIdentifiers: ['public.image'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      controller.addImage(image);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.imageImportError)),
        );
      }
    }
  }
}

// ── Rig picker dialog ─────────────────────────────────────────────────────────

class _RigPickerDialog extends StatelessWidget {
  final RigType currentType;
  const _RigPickerDialog({required this.currentType});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.panel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.toolRigs,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: RigType.values.map((t) => _RigTile(
                type: t,
                selected: t == currentType,
                onTap: () => Navigator.of(context).pop(t),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RigTile extends StatelessWidget {
  final RigType type;
  final bool selected;
  final VoidCallback onTap;
  const _RigTile({required this.type, required this.selected, required this.onTap});

  String get _label => switch (type) {
    RigType.jib   => strings.rigJib,
    RigType.dolly => strings.rigDolly,
    RigType.rail  => strings.rigRail,
    RigType.drone => strings.rigDrone,
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.accent : Colors.white24,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 120,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _RigPreviewPainter.naturalSize(type).width,
                  height: _RigPreviewPainter.naturalSize(type).height,
                  child: CustomPaint(painter: _RigPreviewPainter(type: type)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(_label,
                style: TextStyle(
                  color: selected ? AppColors.accent : null,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Rig preview painter ───────────────────────────────────────────────────────

class _RigPreviewPainter extends CustomPainter {
  final RigType type;
  const _RigPreviewPainter({required this.type});

  static Size naturalSize(RigType type) => switch (type) {
    RigType.jib   => const Size(160, 400),
    RigType.dolly => const Size(160, 160),
    RigType.rail  => const Size(160, 400),
    RigType.drone => const Size(160, 160),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()
      ..color = const Color(0xFFA7A9AC)
      ..style = PaintingStyle.fill;

    switch (type) {
      case RigType.jib:   _jib(canvas, size, stroke, fill);
      case RigType.dolly: _dolly(canvas, size, stroke, fill);
      case RigType.rail:  _rail(canvas, size, stroke);
      case RigType.drone: _drone(canvas, size, stroke, fill);
    }
  }

  void _jib(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final W = size.width, H = size.height;
    final boomH = H * 0.55;
    final ft = boomH; // top of fixed section

    void r(double x, double y, double w, double h, {bool rounded = false}) {
      final rect = Rect.fromLTWH(x * W, y, w * W, h);
      if (rounded) {
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(0.04 * W));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, stroke);
      } else {
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      }
    }

    r(0.43, 0,         0.14, boomH);                    // boom
    r(0.41, ft,        0.18, H * 0.22);                 // column
    r(0.20, ft + H * 0.25, 0.60, H * 0.20);            // body
    r(0.05, ft + H * 0.18, 0.13, H * 0.13, rounded: true); // legs
    r(0.82, ft + H * 0.18, 0.13, H * 0.13, rounded: true);
    r(0.05, ft + H * 0.37, 0.13, H * 0.13, rounded: true);
    r(0.82, ft + H * 0.37, 0.13, H * 0.13, rounded: true);
  }

  void _dolly(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final W = size.width, H = size.height;

    void r(double x, double y, double w, double h, {bool rounded = false}) {
      final rect = Rect.fromLTWH(x * W, y * H, w * W, h * H);
      if (rounded) {
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(0.04 * W));
        canvas.drawRRect(rr, fill);
        canvas.drawRRect(rr, stroke);
      } else {
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      }
    }

    r(0.12, 0.11, 0.10, 0.27, rounded: true);
    r(0.12, 0.61, 0.10, 0.27, rounded: true);
    r(0.78, 0.11, 0.10, 0.27, rounded: true);
    r(0.78, 0.61, 0.10, 0.27, rounded: true);
    r(0.22, 0.21, 0.56, 0.57);
  }

  void _rail(Canvas canvas, Size size, Paint stroke) {
    final W = size.width, H = size.height;
    const x1 = 0.22, x2 = 0.78;
    canvas.drawLine(Offset(x1 * W, 0.02 * H), Offset(x1 * W, 0.98 * H), stroke);
    canvas.drawLine(Offset(x2 * W, 0.02 * H), Offset(x2 * W, 0.98 * H), stroke);
    for (int i = 0; i < 7; i++) {
      final y = (0.07 + i * 0.14) * H;
      canvas.drawLine(Offset(x1 * W, y), Offset(x2 * W, y), stroke);
    }
  }

  void _drone(Canvas canvas, Size size, Paint stroke, Paint fill) {
    final W = size.width, H = size.height;
    final s = W / 1024.0;

    final bodyFill = Paint()..color = const Color(0xFF666666)..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(258.09 * s, 208.84 * s)
      ..lineTo(403.12 * s, 312.35 * s)
      ..cubicTo(468.26 * s, 358.85 * s, 555.75 * s, 358.85 * s, 620.89 * s, 312.35 * s)
      ..lineTo(765.92 * s, 208.84 * s)
      ..cubicTo(798.36 * s, 185.68 * s, 838.32 * s, 225.64 * s, 815.16 * s, 258.08 * s)
      ..lineTo(711.65 * s, 403.11 * s)
      ..cubicTo(665.15 * s, 468.25 * s, 665.15 * s, 555.74 * s, 711.65 * s, 620.88 * s)
      ..lineTo(815.16 * s, 765.91 * s)
      ..cubicTo(838.32 * s, 798.35 * s, 798.36 * s, 838.31 * s, 765.92 * s, 815.15 * s)
      ..lineTo(620.89 * s, 711.64 * s)
      ..cubicTo(555.75 * s, 665.14 * s, 468.26 * s, 665.14 * s, 403.12 * s, 711.64 * s)
      ..lineTo(258.09 * s, 815.15 * s)
      ..cubicTo(225.65 * s, 838.31 * s, 185.69 * s, 798.35 * s, 208.85 * s, 765.91 * s)
      ..lineTo(312.36 * s, 620.88 * s)
      ..cubicTo(358.86 * s, 555.74 * s, 358.86 * s, 468.25 * s, 312.36 * s, 403.11 * s)
      ..lineTo(208.85 * s, 258.08 * s)
      ..cubicTo(185.69 * s, 225.64 * s, 225.65 * s, 185.68 * s, 258.09 * s, 208.84 * s)
      ..close();
    canvas.drawPath(path, bodyFill);
    canvas.drawPath(path, stroke);

    final ringStroke = Paint()
      ..color = stroke.color..style = PaintingStyle.stroke..strokeWidth = stroke.strokeWidth;
    final hubFill = Paint()..color = const Color(0xFFCBCCD2)..style = PaintingStyle.fill;
    final propR = 169.63 * s;
    final hubR = 23.94 * s;
    // scale H separately since preview may not be square
    final hs = H / 1024.0;
    for (final c in [(241.63, 241.63), (782.37, 241.63), (241.63, 782.37), (782.37, 782.37)]) {
      final cx = c.$1 * s, cy = c.$2 * hs;
      canvas.drawCircle(Offset(cx, cy), propR, ringStroke);
      canvas.drawCircle(Offset(cx, cy), hubR, hubFill);
      canvas.drawCircle(Offset(cx, cy), hubR, stroke);
    }
  }

  @override
  bool shouldRepaint(_RigPreviewPainter old) => old.type != type;
}