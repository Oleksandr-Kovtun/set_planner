import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/settings.dart';
import '../prefs.dart';

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
  late final TextEditingController _folderCtrl;

  AppStrings get _str => AppStrings.of(settings.language);

  @override
  void initState() {
    super.initState();
    settings = widget.initialSettings.copy();
    _folderCtrl = TextEditingController(
      text: AppPrefs.instance.projectsFolder ?? '',
    );
  }

  @override
  void dispose() {
    _folderCtrl.dispose();
    super.dispose();
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
              if (!Platform.isIOS && !Platform.isAndroid) ...[
                const Divider(height: 32),
                _buildSectionTitle(s.projectsSection),
                const SizedBox(height: 12),
                _buildProjectsFolderRow(s),
              ],
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
            final folder = _folderCtrl.text.trim();
            AppPrefs.instance.projectsFolder = folder.isEmpty ? null : folder;
            AppPrefs.instance.save();
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

  Widget _buildProjectsFolderRow(AppStrings s) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _folderCtrl,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              hintText: s.projectsFolderHint,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: s.select,
          icon: const Icon(Icons.folder_open),
          onPressed: _pickProjectsFolder,
        ),
      ],
    );
  }

  Future<void> _pickProjectsFolder() async {
    try {
      final picked = await getDirectoryPath();
      if (picked != null && mounted) {
        _folderCtrl.text = picked;
      }
    } catch (_) {
      // Directory picking not available on this platform.
    }
  }
}
