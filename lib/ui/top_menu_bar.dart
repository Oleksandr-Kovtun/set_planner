import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../editor_controller.dart';
import '../l10n/app_strings.dart';
import '../project_io.dart';
import 'settings_dialog.dart';

class TopMenuBar extends StatefulWidget {
  final EditorController controller;
  const TopMenuBar({super.key, required this.controller});

  @override
  State<TopMenuBar> createState() => _TopMenuBarState();
}

class _TopMenuBarState extends State<TopMenuBar> {
  // Remembered save path — reused on subsequent Ctrl+S presses.
  String? _savePath;

  EditorController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: const Color(0xFF263238),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showSettings(context),
              child: Text(
                strings.appTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
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
            tooltip: strings.openProject,
            onPressed: _openProject,
            icon: const Icon(Icons.folder_open_outlined),
            color: Colors.white,
          ),
          IconButton(
            tooltip: strings.saveProject,
            onPressed: _saveProject,
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
        icon: const Icon(Icons.search),
        color: Colors.white,
        onPressed: () =>
            menuController.isOpen ? menuController.close() : menuController.open(),
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _saveProject() async {
    // Reuse last path; show "Save As" dialog when saving for the first time.
    final path = _savePath ?? await _showSaveAsDialog();
    if (path == null) return;
    await _writeToPath(path);
  }

  Future<void> _writeToPath(String path) async {
    try {
      final xml = await ProjectSerializer.toXmlString(
        items: controller.items,
        settings: controller.settings,
        scale: controller.scale,
        offset: controller.offset,
      );
      await File(path).writeAsString(xml);
      if (mounted) {
        setState(() => _savePath = path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.saveProject}: $path'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.saveError}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String?> _showSaveAsDialog() async {
    final docsDir = await getApplicationDocumentsDirectory();
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (ctx) => _SaveAsDialog(defaultDir: docsDir.path),
    );
  }

  // ── Open ─────────────────────────────────────────────────────────────────

  Future<void> _openProject() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'Set Planner',
        extensions: ['splan'],
        uniformTypeIdentifiers: ['public.data'],
      );
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      final xml = await file.readAsString();
      final data = await ProjectLoader.fromXmlString(xml);
      if (mounted) {
        controller.restoreFromProject(
          items: data.items,
          settings: data.settings,
          scale: data.scale,
          offset: data.offset,
        );
        setState(() => _savePath = file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.openError}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        initialSettings: controller.settings,
        onSave: (newSettings) => controller.updateSettings(newSettings),
      ),
    );
  }

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

// ── Save-As dialog ────────────────────────────────────────────────────────────

class _SaveAsDialog extends StatefulWidget {
  final String defaultDir;
  const _SaveAsDialog({required this.defaultDir});

  @override
  State<_SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<_SaveAsDialog> {
  late String _dir;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _dir = widget.defaultDir;
    _nameCtrl = TextEditingController(text: 'project.splan');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDir() async {
    try {
      final picked = await getDirectoryPath();
      if (picked != null && mounted) setState(() => _dir = picked);
    } on UnimplementedError {
      // getDirectoryPath not available — user can type the path manually
    }
  }

  void _confirm() {
    var name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (!name.endsWith('.splan')) name = '$name.splan';
    Navigator.pop(context, '$_dir${Platform.pathSeparator}$name');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(strings.saveProject),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  _dir,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDir,
                icon: const Icon(Icons.folder_open, size: 18),
                label: Text(strings.select),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                hintText: 'project.splan',
              ),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(strings.save),
        ),
      ],
    );
  }
}
