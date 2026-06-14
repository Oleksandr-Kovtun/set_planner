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
          const SizedBox(height: 8),
          if (controller.canJoinLines)
            FilledButton.icon(
              onPressed: controller.joinSelectedLines,
              icon: const Icon(Icons.call_received_sharp),
              label: Text(strings.joinLines),
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
    if (item.tool == Tool.actor) {
      return item.locked
          ? _lockedPanel(strings.toolActor)
          : _ActorPanel(controller: controller);
    }
    if (item.tool == Tool.camera) {
      return item.locked
          ? _lockedPanel(strings.toolCamera)
          : _CameraPanel(controller: controller);
    }
    if (item.tool == Tool.text) {
      // Якщо це мітка камери — показуємо спеціальну панель
      final cam = controller.parentCamera(item);
      if (cam != null) return _CameraLabelPanel(controller: controller, label: item, camera: cam);
      return _textPanel(item);
    }
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

          if ((item.tool == Tool.pen || item.tool == Tool.polyline) && !item.smoothed) ...[
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

// ---- Текстове поле, що не оновлює controller під час фокусу ----
class _LiveTextField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;
  const _LiveTextField({required this.value, required this.onChanged, required this.label});
  @override
  State<_LiveTextField> createState() => _LiveTextFieldState();
}

class _LiveTextFieldState extends State<_LiveTextField> {
  late final TextEditingController _c;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _LiveTextField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value != _c.text) _c.text = widget.value;
  }

  @override
  void dispose() { _c.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        focusNode: _focus,
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          labelText: widget.label,
        ),
        onChanged: widget.onChanged,
      );
}

// ---- Панель властивостей актора ----
class _ActorPanel extends StatelessWidget {
  final EditorController controller;
  const _ActorPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final item = controller.selectedItem!;
    final actor = item.actorData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.properties}: ${strings.toolActor}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),

          Text(strings.colorLabel),
          const SizedBox(height: 4),
          _ColorRow(
            selected: item.fillColor,
            onPick: controller.setFillColor,
            includeNone: false,
          ),
          const SizedBox(height: 12),

          _LiveTextField(
            value: actor.name,
            label: strings.actorName,
            onChanged: controller.setActorName,
          ),
          const SizedBox(height: 12),

          _LiveTextField(
            value: actor.description,
            label: strings.description,
            onChanged: controller.setActorDescription,
          ),
          const SizedBox(height: 12),

          _LiveTextField(
            value: actor.props,
            label: strings.actorProps,
            onChanged: controller.setActorProps,
          ),

          const Divider(height: 24),
          Text(strings.rotationAngle),
          const SizedBox(height: 4),
          _RotationField(
            degrees: item.rotation * 180 / math.pi,
            onSubmit: controller.setRotationDegrees,
          ),
          const SizedBox(height: 12),

          Row(children: [
            Checkbox(
              value: item.locked,
              onChanged: (v) => controller.setLocked(v ?? false),
            ),
            Expanded(child: Text(strings.locked)),
          ]),
          const SizedBox(height: 12),

          const Divider(height: 24),
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
}

// ---- Панель властивостей камери ----
class _CameraPanel extends StatelessWidget {
  final EditorController controller;
  const _CameraPanel({required this.controller});

  @override
  Widget build(BuildContext context) {
    final item = controller.selectedItem!;
    final cam = item.cameraData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${strings.properties}: ${strings.toolCamera}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),

          // Номер камери
          Text(strings.cameraNumber),
          const SizedBox(height: 4),
          _CameraNumberField(
            number: cam.number,
            onSubmit: controller.setCameraNumber,
          ),
          const SizedBox(height: 8),

          // Показувати номер
          Row(children: [
            Checkbox(
              value: cam.showNumber,
              onChanged: (v) => controller.setShowCameraNumber(v ?? true),
            ),
            Expanded(child: Text(strings.showNumber)),
          ]),

          // Дозволити зміну розміру
          Row(children: [
            Checkbox(
              value: cam.allowResize,
              onChanged: (v) => controller.setCameraAllowResize(v ?? false),
            ),
            Expanded(child: Text(strings.allowResize)),
          ]),
          const Divider(height: 24),

          // Колір камери
          Text(strings.cameraColor),
          const SizedBox(height: 4),
          _ColorRow(
            selected: item.fillColor,
            onPick: controller.setFillColor,
            includeNone: false,
          ),
          const SizedBox(height: 12),

          // Модель камери
          _LiveTextField(
            value: cam.cameraModel,
            label: strings.cameraModel,
            onChanged: controller.setCameraModel,
          ),
          const SizedBox(height: 12),

          // Об'єктив
          _LiveTextField(
            value: cam.lens,
            label: strings.lens,
            onChanged: controller.setCameraLens,
          ),
          const SizedBox(height: 12),

          // Тип кадру (теги)
          Text(strings.shotType),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final type in kShotTypes)
                _ShotTypeChip(
                  label: type,
                  selected: cam.shotTypes.contains(type),
                  onTap: () => controller.toggleCameraShotType(type),
                ),
            ],
          ),
          const Divider(height: 24),

          // Видошукач
          Text(strings.viewfinder),
          const SizedBox(height: 4),
          _RadioGroup<ViewfinderType>(
            value: cam.viewfinder,
            options: [
              (ViewfinderType.none, strings.viewfinderNone),
              (ViewfinderType.small, strings.viewfinderSmall),
              (ViewfinderType.big, strings.viewfinderBig),
            ],
            onChanged: controller.setCameraViewfinder,
          ),
          const SizedBox(height: 12),

          // Навушники
          Text(strings.headphones),
          const SizedBox(height: 4),
          _RadioGroup<HeadphonesType>(
            value: cam.headphones,
            options: [
              (HeadphonesType.none, strings.headphonesNone),
              (HeadphonesType.single, strings.headphonesSingle),
              (HeadphonesType.double_, strings.headphonesDouble),
            ],
            onChanged: controller.setCameraHeadphones,
          ),
          const Divider(height: 24),

          // Штатив
          Row(children: [
            Checkbox(
              value: cam.tripod,
              onChanged: (v) => controller.setCameraTripod(v ?? false),
            ),
            Expanded(child: Text(strings.tripod)),
          ]),
          if (cam.tripod) ...[
            const SizedBox(height: 4),
            _LiveTextField(
              value: cam.tripodDescription,
              label: strings.tripodDescription,
              onChanged: controller.setCameraTripodDescription,
            ),
            const SizedBox(height: 8),
          ],

          // Колеса
          Row(children: [
            Checkbox(
              value: cam.wheels,
              onChanged: (v) => controller.setCameraWheels(v ?? false),
            ),
            Expanded(child: Text(strings.wheels)),
          ]),

          // Подіум
          Row(children: [
            Checkbox(
              value: cam.podium,
              onChanged: (v) => controller.setCameraPodium(v ?? false),
            ),
            Expanded(child: Text(strings.podium)),
          ]),
          if (cam.podium) ...[
            const SizedBox(height: 4),
            _LiveTextField(
              value: cam.podiumDescription,
              label: strings.podiumDescription,
              onChanged: controller.setCameraPodiumDescription,
            ),
            const SizedBox(height: 8),
          ],

          const Divider(height: 24),

          // Опис
          _LiveTextField(
            value: cam.description,
            label: strings.description,
            onChanged: controller.setCameraDescription,
          ),
          const SizedBox(height: 12),

          const Divider(height: 24),
          // Кут обертання
          Text(strings.rotationAngle),
          const SizedBox(height: 4),
          _RotationField(
            degrees: item.rotation * 180 / math.pi,
            onSubmit: controller.setRotationDegrees,
          ),
          const SizedBox(height: 12),

          // Заблоковано
          Row(children: [
            Checkbox(
              value: item.locked,
              onChanged: (v) => controller.setLocked(v ?? false),
            ),
            Expanded(child: Text(strings.locked)),
          ]),
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
}

// ---- Панель мітки камери ----
class _CameraLabelPanel extends StatelessWidget {
  final EditorController controller;
  final DrawnItem label;
  final DrawnItem camera;
  const _CameraLabelPanel({
    required this.controller,
    required this.label,
    required this.camera,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.cameraLabelItem,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text('${strings.cameraNumber}: ${label.text ?? ""}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),

          // Форматування тексту
          Text('${strings.fontSizeLabel}: ${label.fontSize.toStringAsFixed(0)}'),
          Slider(
            value: label.fontSize.clamp(8, 96),
            min: 8, max: 96,
            onChanged: controller.setCameraLabelFontSize,
          ),
          const SizedBox(height: 8),
          Text(strings.colorLabel),
          const SizedBox(height: 4),
          _ColorRow(
            selected: label.strokeColor,
            onPick: (c) => controller.setStrokeColor(c!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            _toggleButton(Icons.format_bold, label.bold,
                () => controller.setCameraLabelBold(!label.bold)),
            _toggleButton(Icons.format_italic, label.italic,
                () => controller.setCameraLabelItalic(!label.italic)),
          ]),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.selectParentCamera,
            icon: const Icon(Icons.videocam),
            label: Text(strings.goToCamera),
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

// ---- Числове поле для номера камери ----
class _CameraNumberField extends StatefulWidget {
  final int number;
  final ValueChanged<int> onSubmit;
  const _CameraNumberField({required this.number, required this.onSubmit});
  @override
  State<_CameraNumberField> createState() => _CameraNumberFieldState();
}

class _CameraNumberFieldState extends State<_CameraNumberField> {
  late final TextEditingController _c;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.number.toString());
  }

  @override
  void didUpdateWidget(covariant _CameraNumberField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.number != old.number) {
      _c.text = widget.number.toString();
    }
  }

  void _apply() {
    final v = int.tryParse(_c.text.trim());
    if (v != null && v >= 1) {
      widget.onSubmit(v);
    } else {
      _c.text = widget.number.toString();
    }
  }

  @override
  void dispose() { _c.dispose(); _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 80,
        child: TextField(
          controller: _c,
          focusNode: _focus,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          onSubmitted: (_) => _apply(),
          onTapOutside: (_) { if (_focus.hasFocus) { _focus.unfocus(); _apply(); } },
        ),
      );
}

// ---- Тег типу кадру ----
class _ShotTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ShotTypeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.transparent,
            border: Border.all(color: selected ? Colors.blue : Colors.black38),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
}

// ---- Radio-група для enum ----
class _RadioGroup<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  const _RadioGroup({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (final (opt, label) in options)
            Row(children: [
              // ignore: deprecated_member_use
              Radio<T>(
                value: opt,
                // ignore: deprecated_member_use
                groupValue: value,
                // ignore: deprecated_member_use
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
              Expanded(child: GestureDetector(
                onTap: () => onChanged(opt),
                child: Text(label),
              )),
            ]),
        ],
      );
}