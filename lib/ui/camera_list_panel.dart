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
  final Set<int> _cameraCollapsed = {};
  final Set<int> _actorCollapsed = {};
  bool _camerasExpanded = true;
  bool _actorsExpanded = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final cameras = widget.controller.cameras;
        final actors = widget.controller.actors;
        final selected = widget.controller.selectedItem;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Cameras section ----
                _SectionHeader(
                  title: strings.cameras,
                  expanded: _camerasExpanded,
                  onTap: () => setState(() => _camerasExpanded = !_camerasExpanded),
                ),
                if (_camerasExpanded) ...[
                  if (cameras.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        strings.noCameras,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: cameras.map((cam) {
                          final cd = cam.cameraData!;
                          final isSelected = cam.id == selected?.id;
                          final isCollapsed = _cameraCollapsed.contains(cam.id);
                          final rows = _buildCameraRows(cd);
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
                                        _cameraCollapsed.remove(cam.id);
                                      } else {
                                        _cameraCollapsed.add(cam.id);
                                      }
                                    }),
                          );
                        }).toList(),
                      ),
                    ),
                ],

                // ---- Actors section ----
                _SectionHeader(
                  title: strings.actors,
                  expanded: _actorsExpanded,
                  onTap: () => setState(() => _actorsExpanded = !_actorsExpanded),
                ),
                if (_actorsExpanded) ...[
                  if (actors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        strings.noActors,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: actors.map((actor) {
                          final ad = actor.actorData!;
                          final isSelected = actor.id == selected?.id;
                          final isCollapsed = _actorCollapsed.contains(actor.id);
                          final hasDetails = ad.description.isNotEmpty || ad.props.isNotEmpty;
                          return _ActorCard(
                            actor: actor,
                            isSelected: isSelected,
                            isCollapsed: isCollapsed,
                            hasDetails: hasDetails,
                            onSelect: () => widget.controller.selectActor(actor),
                            onToggle: !hasDetails
                                ? null
                                : () => setState(() {
                                      if (isCollapsed) {
                                        _actorCollapsed.remove(actor.id);
                                      } else {
                                        _actorCollapsed.add(actor.id);
                                      }
                                    }),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  static List<String> _buildCameraRows(CameraData cd) {
    final rows = <String>[];
    if (cd.cameraModel.isNotEmpty) rows.add('${strings.cameraModel}: ${cd.cameraModel}');
    if (cd.shotTypes.isNotEmpty) rows.add('${strings.shotType}: ${cd.shotTypes.join(', ')}');
    if (cd.lens.isNotEmpty) rows.add('${strings.lens}: ${cd.lens}');
    if (cd.viewfinder != ViewfinderType.none) {
      final v = cd.viewfinder == ViewfinderType.small ? strings.viewfinderSmall : strings.viewfinderBig;
      rows.add('${strings.viewfinder}: ${strings.yes} ($v)');
    }
    if (cd.headphones != HeadphonesType.none) {
      final h = cd.headphones == HeadphonesType.single ? strings.headphonesSingle : strings.headphonesDouble;
      rows.add('${strings.headphones}: ${strings.yes} ($h)');
    }
    if (cd.tripod) {
      final desc = cd.tripodDescription.isNotEmpty ? ' (${cd.tripodDescription})' : '';
      rows.add('${strings.tripod}: ${strings.yes}$desc');
    }
    if (cd.wheels) rows.add('${strings.wheels}: ${strings.yes}');
    if (cd.podium) {
      final desc = cd.podiumDescription.isNotEmpty ? ' (${cd.podiumDescription})' : '';
      rows.add('${strings.podium}: ${strings.yes}$desc');
    }
    if (cd.description.isNotEmpty) rows.add('${strings.description}: ${cd.description}');
    return rows;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;

  const _SectionHeader({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.grey.shade200,
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
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

class _ActorCard extends StatelessWidget {
  final DrawnItem actor;
  final bool isSelected;
  final bool isCollapsed;
  final bool hasDetails;
  final VoidCallback onSelect;
  final VoidCallback? onToggle;

  const _ActorCard({
    required this.actor,
    required this.isSelected,
    required this.isCollapsed,
    required this.hasDetails,
    required this.onSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ad = actor.actorData!;
    final actorColor = actor.fillColor ?? const Color(0xFF43A047);
    final displayName = ad.name.isNotEmpty ? ad.name : '—';

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: actorColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
            if (hasDetails && !isCollapsed) ...[
              Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ad.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('${strings.description}: ${ad.description}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                    if (ad.props.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('${strings.actorProps}: ${ad.props}',
                            style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
