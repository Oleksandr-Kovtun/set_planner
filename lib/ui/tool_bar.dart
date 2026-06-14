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
            _comingSoonMenu(Icons.person, strings.actors, strings.actorsComingSoon),
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

  Widget _comingSoonMenu(IconData icon, String label, String message) {
    return PopupMenuButton<String>(
      tooltip: label,
      itemBuilder: (context) => [
        PopupMenuItem<String>(enabled: false, child: Text(message)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white70),
          const Icon(Icons.arrow_drop_up, color: Colors.white70),
        ]),
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