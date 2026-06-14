import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../l10n/app_strings.dart';

class SettingsDialog extends StatefulWidget {
  final AppSettings initialSettings;
  final Function(AppSettings) onSave;

  const SettingsDialog({
    super.key,
    required this.initialSettings,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late AppSettings settings;

  @override
  void initState() {
    super.initState();
    settings = widget.initialSettings.copy();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Налаштування'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Розмір JPEG
              _buildSectionTitle('Вихідний файл JPEG'),
              const SizedBox(height: 12),
              _buildPaperSizeDropdown(),
              const SizedBox(height: 12),
              _buildPaperOrientationDropdown(),
              const Divider(height: 32),
              // Сітка
              _buildSectionTitle('Сітка для привʼязування'),
              const SizedBox(height: 12),
              _buildGridSizeSlider(),
              const SizedBox(height: 16),
              _buildGridToggle(),
              const SizedBox(height: 12),
              _buildSnapToGridToggle(),
              const Divider(height: 32),
              // Камери
              _buildSectionTitle('Камери'),
              const SizedBox(height: 12),
              _buildCameraNumberStyle(),
              const SizedBox(height: 16),
              _buildCameraInfoDisplay(),
              const Divider(height: 32),
              // Інтерфейс
              _buildSectionTitle(strings.language),
              const SizedBox(height: 12),
              _buildLanguagePicker(),
              const Divider(height: 32),
              _buildSectionTitle('Інтерфейс'),
              const SizedBox(height: 12),
              _buildColorPicker(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(settings);
            Navigator.pop(context);
          },
          child: const Text('Зберегти'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPaperSizeDropdown() {
    return DropdownButtonFormField<PaperSize>(
      initialValue: settings.paperSize,
      decoration: InputDecoration(
        labelText: 'Розмір',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: PaperSize.values.map((size) {
        return DropdownMenuItem(
          value: size,
          child: Text(size.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => settings.paperSize = value);
        }
      },
    );
  }

  Widget _buildPaperOrientationDropdown() {
    return DropdownButtonFormField<PaperOrientation>(
      initialValue: settings.paperOrientation,
      decoration: InputDecoration(
        labelText: 'Орієнтація',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: PaperOrientation.values.map((orientation) {
        return DropdownMenuItem(
          value: orientation,
          child: Text(orientation.displayName),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => settings.paperOrientation = value);
        }
      },
    );
  }

  Widget _buildGridSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Розмір комірки: ${settings.gridSize.toStringAsFixed(0)} px'),
        Slider(
          value: settings.gridSize,
          min: 5,
          max: 100,
          divisions: 19,
          onChanged: (value) {
            setState(() => settings.gridSize = value);
          },
        ),
      ],
    );
  }

  Widget _buildGridToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Показувати сітку'),
        Switch(
          value: settings.showGrid,
          onChanged: (value) {
            setState(() => settings.showGrid = value);
          },
        ),
      ],
    );
  }

  Widget _buildCameraNumberStyle() {
    return DropdownButtonFormField<CameraNumberStyle>(
      initialValue: settings.cameraNumberStyle,
      decoration: InputDecoration(
        labelText: 'Нумерація камер',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: CameraNumberStyle.numeric, child: Text('1, 2, 3...')),
        DropdownMenuItem(value: CameraNumberStyle.alphabetic, child: Text('A, B, C...')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => settings.cameraNumberStyle = v);
      },
    );
  }

  Widget _buildLanguagePicker() {
    return DropdownButtonFormField<String>(
      initialValue: settings.language,
      decoration: InputDecoration(
        labelText: strings.language,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: 'uk', child: Text(strings.languageUk)),
        DropdownMenuItem(value: 'en', child: Text(strings.languageEn)),
      ],
      onChanged: (v) {
        if (v != null) setState(() => settings.language = v);
      },
    );
  }

  Widget _buildCameraInfoDisplay() {
    final fields = [
      (CameraInfoField.cameraModel, strings.cameraModel),
      (CameraInfoField.shotTypes,   strings.shotType),
      (CameraInfoField.lens,        strings.lens),
      (CameraInfoField.viewfinder,  strings.viewfinder),
      (CameraInfoField.headphones,  strings.headphones),
      (CameraInfoField.tripod,      strings.tripod),
      (CameraInfoField.wheels,      strings.wheels),
      (CameraInfoField.podium,      strings.podium),
      (CameraInfoField.description, strings.description),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.cameraInfoDisplay,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        ...fields.map((entry) {
          final (field, label) = entry;
          final checked = settings.cameraInfoFields.contains(field);
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            value: checked,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  settings.cameraInfoFields.add(field);
                } else {
                  settings.cameraInfoFields.remove(field);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildSnapToGridToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Привʼязувати до сітки'),
        Switch(
          value: settings.snapToGrid,
          onChanged: (value) {
            setState(() => settings.snapToGrid = value);
          },
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Основний колір'),
        GestureDetector(
          onTap: () async {
            final color = await showDialog<Color>(
              context: context,
              builder: (context) => _ColorPickerDialog(
                initialColor: settings.primaryColor,
              ),
            );
            if (color != null) {
              setState(() => settings.primaryColor = color);
            }
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: settings.primaryColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.indigo,
    ];

    return AlertDialog(
      title: const Text('Оберіть колір'),
      content: GridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        children: colors.map((color) {
          final isSelected = selectedColor == color;
          return GestureDetector(
            onTap: () {
              setState(() => selectedColor = color);
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: Colors.black, width: 3)
                    : Border.all(color: Colors.grey, width: 1),
              ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: const Text('Вибрати'),
        ),
      ],
    );
  }
}
