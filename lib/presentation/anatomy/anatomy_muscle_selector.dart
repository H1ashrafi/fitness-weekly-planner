import 'package:flutter/material.dart';

import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/anatomy_region.dart';
import 'anatomy_body_map.dart';

final class AnatomyMuscleSelector extends StatefulWidget {
  const AnatomyMuscleSelector({
    required this.selectedRegions,
    required this.onToggle,
    super.key,
  });

  final Set<AnatomyRegion> selectedRegions;
  final ValueChanged<AnatomyRegion> onToggle;

  @override
  State<AnatomyMuscleSelector> createState() => _AnatomyMuscleSelectorState();
}

final class _AnatomyMuscleSelectorState extends State<AnatomyMuscleSelector> {
  AnatomyFacing _facing = AnatomyFacing.anterior;

  @override
  Widget build(BuildContext context) => Column(
        children: <Widget>[
          _FacingToggle(
            facing: _facing,
            onChanged: (AnatomyFacing facing) => setState(() => _facing = facing),
          ),
          const SizedBox(height: FibonacciSpace.regular),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: FibonacciSpace.expansive * 3),
            child: AnatomyBodyMap(
              facing: _facing,
              intensities: <AnatomyRegion, double>{
                for (final AnatomyRegion region in widget.selectedRegions) region: 1,
              },
              onRegionTap: widget.onToggle,
            ),
          ),
        ],
      );
}

final class _FacingToggle extends StatelessWidget {
  const _FacingToggle({required this.facing, required this.onChanged});

  final AnatomyFacing facing;
  final ValueChanged<AnatomyFacing> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SegmentedButton<AnatomyFacing>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: palette.crimson,
        selectedForegroundColor: palette.onCrimson,
      ),
      segments: const <ButtonSegment<AnatomyFacing>>[
        ButtonSegment<AnatomyFacing>(
          value: AnatomyFacing.anterior,
          label: Text('Front'),
          icon: Icon(Icons.accessibility_new_rounded),
        ),
        ButtonSegment<AnatomyFacing>(
          value: AnatomyFacing.posterior,
          label: Text('Back'),
          icon: Icon(Icons.airline_seat_recline_normal_rounded),
        ),
      ],
      selected: <AnatomyFacing>{facing},
      onSelectionChanged: (Set<AnatomyFacing> selection) =>
          onChanged(selection.first),
    );
  }
}
