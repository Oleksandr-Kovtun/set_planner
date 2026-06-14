import 'package:flutter/material.dart';
import '../editor_controller.dart';
import '../models.dart';
import '../l10n/app_strings.dart';

class CameraListPanel extends StatefulWidget {
  final EditorController controller;
  const CameraListPanel({super.key, required this.controller});

  @override
  State<CameraListPanel> createState() => _CameraListPanelState();
}

class _CameraListPanelState extends State<CameraListPanel> {
  final Set<int> _collapsed = {};

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final cameras = widget.controller.cameras;
        final selected = widget.controller.selectedItem;
        final fields = widget.controller.settings.cameraInfoFields;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey.shade200,
                child: Text(
                  strings.cameras,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: cameras.isEmpty
                    ? Center(
                        child: Text(
                          strings.noCameras,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(6),
                        itemCount: cameras.length,
                        itemBuilder: (context, index) {
                          final cam = cameras[index];
                          final cd = cam.cameraData!;
                          final isSelected = cam.id == selected?.id;
                          final isCollapsed = _collapsed.contains(cam.id);
                          final rows = _buildRows(cd, fields);

                          return _CameraCard(
                            camera: cam,
                            label: widget.controller.cameraLabel(cd.number),
                            isSelected: isSelected,
                            isCollapsed: isCollapsed,
                            rows: rows,
                            onSelect: () => widget.controller.selectCamera(cam),
                            onToggle: rows.isEmpty
                                ? null
                                : () => setState(() {
                                      if (isCollapsed) {
                                        _collapsed.remove(cam.id);
                                      } else {
                                        _collapsed.add(cam.id);
                                      }
                                    }),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static List<String> _buildRows(CameraData cd, Set<CameraInfoField> fields) {
    if (fields.isEmpty) return [];
    final rows = <String>[];
    if (fields.contains(CameraInfoField.cameraModel) && cd.cameraModel.isNotEmpty) {
      rows.add('${strings.cameraModel}: ${cd.cameraModel}');
    }
    if (fields.contains(CameraInfoField.shotTypes) && cd.shotTypes.isNotEmpty) {
      rows.add('${strings.shotType}: ${cd.shotTypes.join(', ')}');
    }
    if (fields.contains(CameraInfoField.lens) && cd.lens.isNotEmpty) {
      rows.add('${strings.lens}: ${cd.lens}');
    }
    if (fields.contains(CameraInfoField.viewfinder) && cd.viewfinder != ViewfinderType.none) {
      final v = cd.viewfinder == ViewfinderType.small ? strings.viewfinderSmall : strings.viewfinderBig;
      rows.add('${strings.viewfinder}: ${strings.yes} ($v)');
    }
    if (fields.contains(CameraInfoField.headphones) && cd.headphones != HeadphonesType.none) {
      final h = cd.headphones == HeadphonesType.single ? strings.headphonesSingle : strings.headphonesDouble;
      rows.add('${strings.headphones}: ${strings.yes} ($h)');
    }
    if (fields.contains(CameraInfoField.tripod) && cd.tripod) {
      final desc = cd.tripodDescription.isNotEmpty ? ' (${cd.tripodDescription})' : '';
      rows.add('${strings.tripod}: ${strings.yes}$desc');
    }
    if (fields.contains(CameraInfoField.wheels) && cd.wheels) {
      rows.add('${strings.wheels}: ${strings.yes}');
    }
    if (fields.contains(CameraInfoField.podium) && cd.podium) {
      final desc = cd.podiumDescription.isNotEmpty ? ' (${cd.podiumDescription})' : '';
      rows.add('${strings.podium}: ${strings.yes}$desc');
    }
    if (fields.contains(CameraInfoField.description) && cd.description.isNotEmpty) {
      rows.add('${strings.description}: ${cd.description}');
    }
    return rows;
  }
}

class _CameraCard extends StatelessWidget {
  final DrawnItem camera;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final List<String> rows;
  final VoidCallback onSelect;
  final VoidCallback? onToggle;

  const _CameraCard({
    required this.camera,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.rows,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cd = camera.cameraData!;
    final camColor = camera.fillColor ?? const Color(0xFF455A64);

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: camColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (cd.cameraModel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cd.cameraModel,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (onToggle != null)
                    GestureDetector(
                      onTap: onToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Icon(
                          isCollapsed ? Icons.expand_more : Icons.expand_less,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Properties table
            if (onToggle != null && !isCollapsed) ...[
              Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows
                      .map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(r, style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
