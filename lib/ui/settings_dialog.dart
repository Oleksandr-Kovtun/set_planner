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

  // Strings driven by the language currently selected inside the dialog,
  // so the UI preview updates in real-time when the user picks a language.
  AppStrings get _str => AppStrings.of(settings.language);

  @override
  void initState() {
    super.initState();
    settings = widget.initialSettings.copy();
  }

  @override
  Widget build(BuildContext context) {
    final s = _str;
    return AlertDialog(
      title: Text(s.settings),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionTitle(s.jpegOutput),
              const SizedBox(height: 12),
              _buildPaperSizeDropdown(s),
              const SizedBox(height: 12),
              _buildPaperOrientationDropdown(s),
              const Divider(height: 32),
              _buildSectionTitle(s.gridSection),
              const SizedBox(height: 12),
              _buildGridSizeSlider(s),
              const SizedBox(height: 16),
              _buildGridToggle(s),
              const SizedBox(height: 12),
              _buildSnapToGridToggle(s),
              const Divider(height: 32),
              _buildSectionTitle(s.cameras),
              const SizedBox(height: 12),
              _buildCameraNumberStyle(s),
              const SizedBox(height: 16),
              _buildCameraInfoDisplay(s),
              const Divider(height: 32),
              _buildSectionTitle(s.language),
              const SizedBox(height: 12),
              _buildLanguagePicker(s),
              const Divider(height: 32),
              _buildSectionTitle(s.uiSection),
              const SizedBox(height: 12),
              _buildColorPicker(s),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(settings);
            Navigator.pop(context);
          },
          child: Text(s.save),
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

  Widget _buildPaperSizeDropdown(AppStrings s) {
    return DropdownButtonFormField<PaperSize>(
      initialValue: settings.paperSize,
      decoration: InputDecoration(
        labelText: s.paperSize,
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

  Widget _buildPaperOrientationDropdown(AppStrings s) {
    return DropdownButtonFormField<PaperOrientation>(
      initialValue: settings.paperOrientation,
      decoration: InputDecoration(
        labelText: s.orientation,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(
          value: PaperOrientation.portrait,
          child: Text(s.portrait),
        ),
        DropdownMenuItem(
          value: PaperOrientation.landscape,
          child: Text(s.landscape),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => settings.paperOrientation = value);
        }
      },
    );
  }

  Widget _buildGridSizeSlider(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.gridSizeLabel}: ${settings.gridSize.toStringAsFixed(0)} px'),
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

  Widget _buildGridToggle(AppStrings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(s.showGrid),
        Switch(
          value: settings.showGrid,
          onChanged: (value) {
            setState(() => settings.showGrid = value);
          },
        ),
      ],
    );
  }

  Widget _buildCameraNumberStyle(AppStrings s) {
    return DropdownButtonFormField<CameraNumberStyle>(
      initialValue: settings.cameraNumberStyle,
      decoration: InputDecoration(
        labelText: s.cameraNumberStyle,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(
          value: CameraNumberStyle.numeric,
          child: Text(s.cameraNumberNumeric),
        ),
        DropdownMenuItem(
          value: CameraNumberStyle.alphabetic,
          child: Text(s.cameraNumberAlphabetic),
        ),
      ],
      onChanged: (v) {
        if (v != null) setState(() => settings.cameraNumberStyle = v);
      },
    );
  }

  Widget _buildLanguagePicker(AppStrings s) {
    return DropdownButtonFormField<String>(
      initialValue: settings.language,
      decoration: InputDecoration(
        labelText: s.language,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: [
        DropdownMenuItem(value: 'uk', child: Text(s.languageUk)),
        DropdownMenuItem(value: 'en', child: Text(s.languageEn)),
      ],
      onChanged: (v) {
        if (v != null) setState(() => settings.language = v);
      },
    );
  }

  Widget _buildCameraInfoDisplay(AppStrings s) {
    final fields = [
      (CameraInfoField.cameraModel, s.cameraModel),
      (CameraInfoField.shotTypes,   s.shotType),
      (CameraInfoField.lens,        s.lens),
      (CameraInfoField.viewfinder,  s.viewfinder),
      (CameraInfoField.headphones,  s.headphones),
      (CameraInfoField.tripod,      s.tripod),
      (CameraInfoField.wheels,      s.wheels),
      (CameraInfoField.podium,      s.podium),
      (CameraInfoField.description, s.description),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.cameraInfoDisplay,
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

  Widget _buildSnapToGridToggle(AppStrings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(s.snapToGrid),
        Switch(
          value: settings.snapToGrid,
          onChanged: (value) {
            setState(() => settings.snapToGrid = value);
          },
        ),
      ],
    );
  }

  Widget _buildColorPicker(AppStrings s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(s.primaryColor),
        GestureDetector(
          onTap: () async {
            final color = await showDialog<Color>(
              context: context,
              builder: (context) => _ColorPickerDialog(
                initialColor: settings.primaryColor,
                str: _str,
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
  final AppStrings str;

  const _ColorPickerDialog({required this.initialColor, required this.str});

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
      title: Text(widget.str.pickColor),
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
          child: Text(widget.str.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedColor),
          child: Text(widget.str.select),
        ),
      ],
    );
  }
}
