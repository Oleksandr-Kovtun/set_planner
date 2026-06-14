import 'package:flutter/material.dart';
import '../editor_controller.dart';
import '../l10n/app_strings.dart';

class TopMenuBar extends StatelessWidget {
  final EditorController controller;
  const TopMenuBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: const Color(0xFF263238),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(strings.appTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(width: 16),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Row(children: [
              IconButton(
                tooltip: strings.undo,
                onPressed: controller.canUndo ? controller.undo : null,
                icon: const Icon(Icons.undo),
                color: Colors.white, disabledColor: Colors.white24,
              ),
              IconButton(
                tooltip: strings.redo,
                onPressed: controller.canRedo ? controller.redo : null,
                icon: const Icon(Icons.redo),
                color: Colors.white, disabledColor: Colors.white24,
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 28, color: Colors.white24),
          const SizedBox(width: 8),
          IconButton(
            tooltip: strings.saveProject,
            onPressed: () => _soon(context, strings.saveComingSoon),
            icon: const Icon(Icons.save_outlined),
            color: Colors.white,
          ),
          IconButton(
            tooltip: strings.exportImage,
            onPressed: () => _soon(context, strings.exportComingSoon),
            icon: const Icon(Icons.image_outlined),
            color: Colors.white,
          ),
          const Spacer(),
          _zoomMenu(),
        ],
      ),
    );
  }

  Widget _zoomMenu() {
    return MenuAnchor(
      alignmentOffset: const Offset(-200, 8),
      menuChildren: [
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final pct = (controller.scale * 100).round();
            return SizedBox(
              width: 240,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${strings.zoom}: $pct%'),
                    Slider(
                      value: controller.scale,
                      min: EditorController.minScale,
                      max: EditorController.maxScale,
                      onChanged: controller.setScale,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: controller.resetScale,
                        child: Text(strings.resetZoom),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
      builder: (context, menuController, child) => IconButton(
        tooltip: strings.zoom,
        icon: const Icon(Icons.search), // лупа
        color: Colors.white,
        onPressed: () =>
            menuController.isOpen ? menuController.close() : menuController.open(),
      ),
    );
  }

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}