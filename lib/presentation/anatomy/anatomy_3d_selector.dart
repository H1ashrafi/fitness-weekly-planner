import 'dart:io';

import 'package:flutter/material.dart';
import 'package:interactive_3d/interactive_3d.dart';

import '../../core/design/app_palette.dart';
import '../../domain/entities/anatomy_region.dart';

final class Anatomy3dSelector extends StatelessWidget {
  const Anatomy3dSelector({
    required this.selectedRegions,
    required this.onRegionsChanged,
    this.controller,
    super.key,
  });

  final Set<AnatomyRegion> selectedRegions;
  final ValueChanged<Set<AnatomyRegion>> onRegionsChanged;
  final Interactive3dController? controller;

  static const String _asset = 'assets/models/anatomy.glb';

  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  List<String> get _preselected => <String>[
        for (final AnatomyRegion region in selectedRegions) ...<String>[
          region.name,
          '${region.name}.L',
          '${region.name}.R',
        ],
      ];

  static List<double> _rgba(Color color) =>
      <double>[color.r, color.g, color.b, 1.0];

  void _handleSelection(List<EntityData> entities) {
    final Set<AnatomyRegion> regions = <AnatomyRegion>{};
    for (final EntityData entity in entities) {
      final String base = entity.name.split('.').first;
      final AnatomyRegion? region = AnatomyRegion.tryParse(base);
      if (region != null) regions.add(region);
    }
    onRegionsChanged(regions);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final Color background = palette.surfaceRaised;

    return Interactive3d(
      key: const ValueKey<String>('anatomy-3d'),
      controller: controller,
      modelPath: _asset,
      preselectedEntities: _preselected,
      selectionColor: _rgba(palette.crimson),
      solidBackgroundColor: _rgba(background),
      backgroundColor: background,
      defaultZoom: 1.0,
      onSelectionChanged: _handleSelection,
    );
  }
}
