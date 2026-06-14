import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../editor_controller.dart';
import '../models.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class PropertiesPanel extends StatelessWidget {
  final EditorController controller;
  const PropertiesPanel({super.key, required this.controller});

  static const List<Color> _palette = [
    Colors.black, Colors.white, Colors.grey,
    Colors.red, Colors.orange, Colors.yellow,
    Colors.green, Colors.blue, Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panel,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (!controller.hasSelection) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(strings.nothingSelected, textAlign: TextAlign.center),
              ),
            );
          }
          if (controller.isMultiSelection) {
            return _multiPanel();
          }
          return _singlePanel(controller.selectedItem!);
        },
      ),
    );
  }

  // Панель для кількох вибраних елементів / групи.
  Widget _multiPanel() {
    final items = controller.selectedItems;
    final first = items.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.selectionMultiple}: ${items.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Text(strings.lineColor),
          const SizedBox(height: 4),
          _ColorRow(
            selected: first.strokeColor,
            onPick: (c) => controller.setStrokeColor(c!),
          ),
          const SizedBox(height: 12),
          Text(strings.fillColor),
          const SizedBox(height: 4),
          _ColorRow(
            selected: first.fillColor,
            onPick: controller.setFillColor,
            includeNone: true,
          ),
          const SizedBox(height: 16),
          if (controller.selectionIsGroup)
            FilledButton.icon(
              onPressed: controller.ungroupSelection,
              icon: const Icon(Icons.call_split),
              label: Text(strings.ungroup),
            )
          else
            FilledButton.icon(
              onPressed: controller.groupSelection,
              icon: const Icon(Icons.join_full),
              label: Text(strings.group),
            ),
          _lockRow(controller.selectedItems.every((e) => e.locked)),  
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: controller.deleteSelected,
            icon: const Icon(Icons.delete_outline),
            label: Text(strings.delete),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  // Панель для однієї фігури.
  Widget _singlePanel(DrawnItem item) {
    if (item.tool == Tool.text) return _textPanel(item);
    if (item.locked) return _lockedPanel(strings.toolLabel(item.tool));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.properties}: ${strings.toolLabel(item.tool)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _lockRow(item.locked),
          const SizedBox(height: 4),

          if (item.tool != Tool.svg && item.tool != Tool.svgPath && item.tool != Tool.image) ...[
            Text('${strings.lineThickness}: ${item.strokeWidth.toStringAsFixed(0)}'),
            Slider(
              value: item.strokeWidth,
              min: 1, max: 20,
              onChangeStart: (_) => controller.beginPropertyEdit(),
              onChanged: (v) => controller.setStrokeWidth(v),
            ),
            const SizedBox(height: 8),
            Text(strings.lineColor),
            const SizedBox(height: 4),
            _ColorRow(
              selected: item.strokeColor,
              onPick: (c) => controller.setStrokeColor(c!),
            ),
            const SizedBox(height: 12),
          ],

          if (toolSupportsFill(item.tool)) ...[
            Text(strings.fillColor),
            const SizedBox(height: 4),
            _ColorRow(
              selected: item.fillColor,
              onPick: controller.setFillColor,
              includeNone: true,
            ),
            const SizedBox(height: 12),
          ],

          if (item.tool == Tool.arrow) ...[
            Row(children: [
              Checkbox(
                value: item.arrowHeadStart,
                onChanged: (v) => controller.setArrowHeadStart(v ?? false),
              ),
              Expanded(child: Text(strings.arrowHeadStart)),
            ]),
            Row(children: [
              Checkbox(
                value: item.arrowHeadEnd,
                onChanged: (v) => controller.setArrowHeadEnd(v ?? false),
              ),
              Expanded(child: Text(strings.arrowHeadEnd)),
            ]),
            const SizedBox(height: 12),
          ],

          if (item.tool == Tool.image) ...[
            Text('${strings.opacity}: ${(item.opacity * 100).round()}%'),
            Slider(
              value: item.opacity,
              min: 0.0,
              max: 1.0,
              onChangeStart: (_) => controller.beginPropertyEdit(),
              onChanged: controller.setOpacity,
            ),
            const SizedBox(height: 12),
          ],

          Text(strings.rotationAngle),
          const SizedBox(height: 4),
          _RotationField(
            degrees: item.rotation * 180 / math.pi,
            onSubmit: controller.setRotationDegrees,
          ),
          const SizedBox(height: 12),

          if (toolSupportsAspectLock(item.tool))
            Row(children: [
              Checkbox(
                value: item.lockAspect,
                onChanged: (v) => controller.setLockAspect(v ?? false),
              ),
              Expanded(child: Text(strings.keepAspect)),
            ]),

          if (item.band == LayerBand.base) ...[
            Text(strings.layer),
            const SizedBox(height: 4),
            Row(children: [
              IconButton(
                tooltip: strings.toBack,
                onPressed: controller.sendToBack,
                icon: const Icon(Icons.vertical_align_bottom),
              ),
              IconButton(
                tooltip: strings.backward,
                onPressed: controller.sendBackward,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: strings.forward,
                onPressed: controller.bringForward,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: strings.toFront,
                onPressed: controller.bringToFront,
                icon: const Icon(Icons.vertical_align_top),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          if (item.tool == Tool.pen && !item.smoothed) ...[
            FilledButton.icon(
              onPressed: controller.convertSelectedToCurve,
              icon: const Icon(Icons.gesture),
              label: Text(strings.convertToCurve),
            ),
            const SizedBox(height: 8),
          ],
          
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: controller.deleteSelected,
            icon: const Icon(Icons.delete_outline),
            label: Text(strings.delete),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
  Widget _lockRow(bool locked) {
    return Row(children: [
      Checkbox(value: locked, onChanged: (v) => controller.setLocked(v ?? false)),
      Expanded(child: Text(strings.locked)),
    ]);
  }

  Widget _lockedPanel(String title) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.properties}: $title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _lockRow(true),
          const SizedBox(height: 8),
          Text(strings.lockedHint),
        ],
      ),
    );
  }

  Widget _textPanel(DrawnItem item) {
    if (item.locked) return _lockedPanel(strings.textTool);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.properties}: ${strings.textTool}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Text(strings.textContent),
          _lockRow(item.locked),
          const SizedBox(height: 4),
          _TextContentField(
            text: item.text ?? '',
            onEditStart: controller.beginPropertyEdit,
            onChanged: controller.setTextLive,
          ),
          const SizedBox(height: 12),
          Text('${strings.fontSizeLabel}: ${item.fontSize.toStringAsFixed(0)}'),
          Slider(
            value: item.fontSize.clamp(8, 96),
            min: 8, max: 96,
            onChangeStart: (_) => controller.beginPropertyEdit(),
            onChanged: controller.setFontSize,
          ),
          const SizedBox(height: 8),
          Text(strings.colorLabel),
          const SizedBox(height: 4),
          _ColorRow(
            selected: item.strokeColor,
            onPick: (c) => controller.setStrokeColor(c!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _toggleButton(Icons.format_bold, item.bold,
                () => controller.setBold(!item.bold)),
            _toggleButton(Icons.format_italic, item.italic,
                () => controller.setItalic(!item.italic)),
          ]),
          const SizedBox(height: 12),
          Text(strings.alignment),
          const SizedBox(height: 4),
          Row(children: [
            _toggleButton(Icons.format_align_left,
                item.textAlign == TextAlign.left,
                () => controller.setTextAlign(TextAlign.left)),
            _toggleButton(Icons.format_align_center,
                item.textAlign == TextAlign.center,
                () => controller.setTextAlign(TextAlign.center)),
            _toggleButton(Icons.format_align_right,
                item.textAlign == TextAlign.right,
                () => controller.setTextAlign(TextAlign.right)),
          ]),
          const SizedBox(height: 12),
          Text(strings.fontFamily),
          const SizedBox(height: 4),
          DropdownButton<String?>(
            isExpanded: true,
            value: item.fontFamily,
            items: [
              DropdownMenuItem(value: null, child: Text(strings.fontDefault)),
              const DropdownMenuItem(value: 'serif', child: Text('Serif')),
              const DropdownMenuItem(value: 'monospace', child: Text('Monospace')),
            ],
            onChanged: controller.setFontFamily,
          ),
          const SizedBox(height: 12),
          Text(strings.rotationAngle),
          const SizedBox(height: 4),
          _RotationField(
            degrees: item.rotation * 180 / math.pi,
            onSubmit: controller.setRotationDegrees,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.deleteSelected,
            icon: const Icon(Icons.delete_outline),
            label: Text(strings.delete),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(IconData icon, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? Colors.blue : Colors.white,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 20, color: active ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _RotationField extends StatefulWidget {
  final double degrees;
  final ValueChanged<double> onSubmit;
  const _RotationField({required this.degrees, required this.onSubmit});

  @override
  State<_RotationField> createState() => _RotationFieldState();
}

class _RotationFieldState extends State<_RotationField> {
  late final TextEditingController _ctrl;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _format(widget.degrees));
  }

  @override
  void didUpdateWidget(covariant _RotationField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.degrees != old.degrees) {
      _ctrl.text = _format(widget.degrees);
    }
  }

  String _format(double d) => ((d % 360).round() % 360).toString();

  void _apply() {
    final parsed = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (parsed != null) {
      widget.onSubmit(parsed);
    } else {
      _ctrl.text = _format(widget.degrees);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          suffixText: '°',
        ),
        onSubmitted: (_) => _apply(),
        onTapOutside: (_) {
          if (_focus.hasFocus) {
            _focus.unfocus();
            _apply();
          }
        },
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final Color? selected;
  final void Function(Color?) onPick;
  final bool includeNone;
  const _ColorRow({required this.selected, required this.onPick, this.includeNone = false});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: [
        if (includeNone)
          _swatch(color: null, isSelected: selected == null, onTap: () => onPick(null)),
        for (final c in PropertiesPanel._palette)
          _swatch(color: c, isSelected: selected == c, onTap: () => onPick(c)),
      ],
    );
  }

  Widget _swatch({required Color? color, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.black26,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: color == null ? const Icon(Icons.block, size: 18, color: Colors.black45) : null,
      ),
    );
  }
}

class _TextContentField extends StatefulWidget {
  final String text;
  final ValueChanged<String> onChanged;
  final VoidCallback onEditStart;
  const _TextContentField(
      {required this.text, required this.onChanged, required this.onEditStart});

  @override
  State<_TextContentField> createState() => _TextContentFieldState();
}

// Текстове поле для редагування вмісту текстового елемента. Важливо, щоб воно не оновлювалося під час редагування, інакше курсор буде стрибати.
class _TextContentFieldState extends State<_TextContentField> {
  late final TextEditingController _c;
  final FocusNode _focus = FocusNode();
  bool _snapshotted = false;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.text);
    _focus.addListener(() {
      if (_focus.hasFocus && !_snapshotted) {
        _snapshotted = true;
        widget.onEditStart();
      } else if (!_focus.hasFocus) {
        _snapshotted = false;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _TextContentField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.text != _c.text) _c.text = widget.text;
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      focusNode: _focus,
      minLines: 1,
      maxLines: null,
      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
      onChanged: widget.onChanged,
    );
  }
}