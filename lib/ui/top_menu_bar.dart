import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../drawing_painter.dart';
import '../editor_controller.dart';
import '../l10n/app_strings.dart';
import '../models.dart';
import '../models/settings.dart';
import '../prefs.dart';
import '../project_io.dart';
import 'settings_dialog.dart';

class TopMenuBar extends StatefulWidget {
  final EditorController controller;
  const TopMenuBar({super.key, required this.controller});

  @override
  State<TopMenuBar> createState() => _TopMenuBarState();
}

class _TopMenuBarState extends State<TopMenuBar> {
  int _lastSaveSignal = 0;

  // GlobalKeys for buttons that trigger Share Sheet — needed on iPad to anchor the popover.
  final _saveKey      = GlobalKey();
  final _saveAsKey    = GlobalKey();
  final _exportImgKey = GlobalKey();
  final _exportPdfKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _lastSaveSignal = widget.controller.saveSignal;
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    final sig = controller.saveSignal;
    if (sig != _lastSaveSignal) {
      _lastSaveSignal = sig;
      _saveProject();
    }
  }

  // Returns the screen Rect of the widget identified by [key].
  // On non-iPad platforms returns null (share_plus ignores it).
  Rect? _anchor(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final pos = box.localToGlobal(Offset.zero);
    return pos & box.size; // Rect.fromLTWH shorthand
  }

  EditorController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: const Color(0xFF263238),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            tooltip: strings.settings,
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings_outlined),
            color: Colors.white,
          ),
          Text(
            strings.appTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
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
            key: _saveKey,
            tooltip: strings.saveProject,
            onPressed: _saveProject,
            icon: const Icon(Icons.save_outlined),
            color: Colors.white,
          ),
          IconButton(
            key: _saveAsKey,
            tooltip: strings.saveAsProject,
            onPressed: _saveAsProject,
            icon: const Icon(Icons.save_as_outlined),
            color: Colors.white,
          ),
          IconButton(
            key: _exportImgKey,
            tooltip: strings.exportImage,
            onPressed: _exportImage,
            icon: const Icon(Icons.image_outlined),
            color: Colors.white,
          ),
          IconButton(
            key: _exportPdfKey,
            tooltip: strings.exportPdf,
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            color: Colors.white,
          ),
          Expanded(
            child: Center(
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Text(
                  controller.projectName ?? strings.untitled,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => IconButton(
              tooltip: strings.toggleCameraKit,
              icon: Icon(controller.showCameraKit
                  ? Icons.table_chart
                  : Icons.table_chart_outlined),
              color: Colors.white,
              onPressed: controller.toggleCameraKit,
            ),
          ),
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

  Future<void> _saveAsProject() async {
    if (Platform.isIOS || Platform.isAndroid) {
      await _saveViaShareSheet(_saveAsKey);
      return;
    }
    final path = await _showSaveAsDialog();
    if (path == null) return;
    await _writeToPath(path);
  }

  Future<void> _saveProject() async {
    if (Platform.isIOS || Platform.isAndroid) {
      await _saveViaShareSheet(_saveKey);
      return;
    }
    final currentPath = controller.currentFilePath;
    if (currentPath != null) {
      await _writeToPath(currentPath);
    } else {
      final dir = await AppPrefs.instance.effectiveProjectsFolder();
      if (!mounted) return;
      final path = await showDialog<String>(
        context: context,
        builder: (ctx) => _SaveAsDialog(
          defaultDir: dir,
          defaultName: strings.untitled,
          extension: '.splan',
        ),
      );
      if (path == null) return;
      await _writeToPath(path);
    }
  }

  Future<void> _saveViaShareSheet(GlobalKey anchorKey) async {
    try {
      final xml = await ProjectSerializer.toXmlString(
        items: controller.items,
        settings: controller.settings,
        scale: controller.scale,
        offset: controller.offset,
      );
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/project.splan');
      await file.writeAsString(xml);
      await Share.shareXFiles(
        [XFile(file.path, name: 'project.splan', mimeType: 'application/octet-stream')],
        sharePositionOrigin: _anchor(anchorKey),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.saveError}: $e'),
              duration: const Duration(seconds: 3)),
        );
      }
    }
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
      AppPrefs.instance.lastFilePath = path;
      AppPrefs.instance.save();
      if (mounted) {
        controller.setCurrentFilePath(path);
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

  Future<String?> _showSaveAsDialog({
    String defaultName = 'project.splan',
    String extension = '.splan',
  }) async {
    final dir = await AppPrefs.instance.effectiveProjectsFolder();
    if (!mounted) return null;
    return showDialog<String>(
      context: context,
      builder: (ctx) => _SaveAsDialog(
        defaultDir: dir,
        defaultName: defaultName,
        extension: extension,
      ),
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
        controller.setCurrentFilePath(file.path);
        AppPrefs.instance.lastFilePath = file.path;
        AppPrefs.instance.save();
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

  // ── Export ────────────────────────────────────────────────────────────────

  Future<void> _exportImage() async {
    final items = controller.items;
    if (items.isEmpty) return;

    try {
      // Bounding box of all visible items (canvas coordinates).
      Rect? contentBounds;
      for (final item in items) {
        if (!item.visible) continue;
        contentBounds = contentBounds == null
            ? item.visualBounds
            : contentBounds.expandToInclude(item.visualBounds);
      }
      if (contentBounds == null || contentBounds.isEmpty) return;

      // Paper dimensions at 72 DPI (72 px/inch = 72/25.4 px/mm).
      const dpi = 72.0;
      const pxPerMm = dpi / 25.4;
      const marginPx = 20.0 * pxPerMm; // 2 cm = 20 mm

      final s = controller.settings;
      final mm = s.paperSize.mmSize;
      final landscape = s.paperOrientation == PaperOrientation.landscape;
      final paperW = (landscape ? mm.height : mm.width) * pxPerMm;
      final paperH = (landscape ? mm.width : mm.height) * pxPerMm;

      // Scale content to fit inside the printable area (preserving aspect ratio).
      final availW = paperW - 2 * marginPx;
      final availH = paperH - 2 * marginPx;
      final scaleFactor = math.min(
        availW / contentBounds.width,
        availH / contentBounds.height,
      );
      final scaledW = contentBounds.width * scaleFactor;
      final scaledH = contentBounds.height * scaleFactor;

      // Offset so content is centred on the page.
      final exportOffset = Offset(
        marginPx + (availW - scaledW) / 2 - contentBounds.left * scaleFactor,
        marginPx + (availH - scaledH) / 2 - contentBounds.top * scaleFactor,
      );

      // Render to an offscreen image.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, paperW, paperH),
        Paint()..color = Colors.white,
      );
      DrawingPainter(
        items,
        scale: scaleFactor,
        offset: exportOffset,
        showGrid: false,
        showBigGrid: s.showBigGrid,
        cameraInfoFields: s.cameraInfoFields,
      ).paint(canvas, Size(paperW, paperH));

      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(paperW.round(), paperH.round());
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      // Encode to JPEG.
      final rgbaBytes = byteData.buffer.asUint8List();
      final imgImage = img.Image.fromBytes(
        width: paperW.round(),
        height: paperH.round(),
        bytes: rgbaBytes.buffer,
        order: img.ChannelOrder.rgba,
      );
      final jpegBytes = img.encodeJpg(imgImage, quality: 92);

      // Save or share.
      if (Platform.isIOS || Platform.isAndroid) {
        final tmp = await getTemporaryDirectory();
        final file = File('${tmp.path}/export.jpg');
        await file.writeAsBytes(jpegBytes);
        await Share.shareXFiles(
          [XFile(file.path, name: 'export.jpg', mimeType: 'image/jpeg')],
          sharePositionOrigin: _anchor(_exportImgKey),
        );
      } else {
        final path = await _showSaveAsDialog(
          defaultName: 'export.jpg',
          extension: '.jpg',
        );
        if (path == null) return;
        await File(path).writeAsBytes(jpegBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(path), duration: const Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.exportError}: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ── PDF export ────────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    final cameras = controller.items
        .where((it) => it.tool == Tool.camera)
        .toList()
      ..sort((a, b) =>
          (a.cameraData?.number ?? 0).compareTo(b.cameraData?.number ?? 0));

    if (cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(strings.noCameras),
              duration: const Duration(seconds: 2)));
      }
      return;
    }

    try {
      final regular = await PdfGoogleFonts.robotoRegular();
      final bold = await PdfGoogleFonts.robotoBold();

      final doc = pw.Document(
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
      );

      final headers = [
        '#',
        strings.cameraModel,
        strings.lens,
        strings.pdfColViewfinder,
        strings.pdfColHeadphones,
        strings.tripod,
        strings.wheels,
        strings.podium,
        strings.description,
      ];

      String vfCell(CameraData cd) => switch (cd.viewfinder) {
            ViewfinderType.none => '—',
            ViewfinderType.small => strings.viewfinderSmall,
            ViewfinderType.big => strings.viewfinderBig,
          };

      String hpCell(CameraData cd) => switch (cd.headphones) {
            HeadphonesType.none => '—',
            HeadphonesType.single => strings.headphonesSingle,
            HeadphonesType.double_ => strings.headphonesDouble,
          };

      String boolCell(bool v, String desc) {
        if (!v) return '—';
        return desc.isNotEmpty ? '${strings.yes} ($desc)' : strings.yes;
      }

      final rows = cameras.map((cam) {
        final cd = cam.cameraData!;
        return [
          '${cd.number}',
          cd.cameraModel,
          cd.lens,
          vfCell(cd),
          hpCell(cd),
          boolCell(cd.tripod, cd.tripodDescription),
          cd.wheels ? strings.yes : '—',
          boolCell(cd.podium, cd.podiumDescription),
          cd.description,
        ];
      }).toList();

      // #455A64 (camera fill) as PDF colour components (0–1 range)
      const headerBg = PdfColor(0.271, 0.353, 0.392);
      const borderColor = PdfColor(0.690, 0.745, 0.773); // #B0BEC5

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
                color: PdfColors.white,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration:
                  const pw.BoxDecoration(color: headerBg),
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {0: pw.Alignment.center},
              cellHeight: 22,
              cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              columnWidths: {
                0: const pw.FixedColumnWidth(20),   // #
                1: const pw.FlexColumnWidth(2),      // model
                2: const pw.FlexColumnWidth(2),      // lens
                3: const pw.FlexColumnWidth(1),      // VF
                4: const pw.FlexColumnWidth(1.5),    // Headset
                5: const pw.FlexColumnWidth(2),      // tripod
                6: const pw.FixedColumnWidth(44),    // wheels (no wrap)
                7: const pw.FlexColumnWidth(2),      // podium
                8: const pw.FlexColumnWidth(3),      // description
              },
              border: pw.TableBorder.all(
                  color: borderColor, width: 0.5),
            ),
          ],
        ),
      );

      final bytes = await doc.save();

      if (Platform.isIOS || Platform.isAndroid) {
        final tmp = await getTemporaryDirectory();
        final file = File('${tmp.path}/cameras.pdf');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([
          XFile(file.path,
              name: 'cameras.pdf', mimeType: 'application/pdf'),
        ], sharePositionOrigin: _anchor(_exportPdfKey));
      } else {
        final path = await _showSaveAsDialog(
            defaultName: 'cameras.pdf', extension: '.pdf');
        if (path == null) return;
        await File(path).writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(path),
                duration: const Duration(seconds: 2)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${strings.exportError}: $e'),
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

}

// ── Save-As dialog ────────────────────────────────────────────────────────────

class _SaveAsDialog extends StatefulWidget {
  final String defaultDir;
  final String defaultName;
  final String extension;
  const _SaveAsDialog({
    required this.defaultDir,
    this.defaultName = 'project.splan',
    this.extension = '.splan',
  });

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
    _nameCtrl = TextEditingController(text: widget.defaultName);
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
      // Not available on this platform — user keeps the default path.
    }
  }

  void _confirm() {
    var name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (!name.endsWith(widget.extension)) name = '$name${widget.extension}';
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
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                hintText: widget.defaultName,
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
