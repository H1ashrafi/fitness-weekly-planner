import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/muscle_catalog_controller.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/anatomy_region.dart';
import '../../domain/entities/muscle_group.dart';
import '../anatomy/muscle_picker_screen.dart';

final class MuscleSelectionField extends ConsumerWidget {
  const MuscleSelectionField({
    required this.selectedGroupIds,
    required this.onChanged,
    super.key,
  });

  final Set<String> selectedGroupIds;
  final ValueChanged<Set<String>> onChanged;

  List<String> _labels(List<MuscleGroup> catalog) => <String>[
        for (final String id in selectedGroupIds)
          if (id.startsWith('region:'))
            if (AnatomyRegion.tryParse(id.substring(7)) case final AnatomyRegion region)
              region.label
            else
              id
          else
            catalog
                .where((MuscleGroup group) => group.id == id)
                .map((MuscleGroup group) => group.displayName)
                .firstOrNull ??
                id,
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MuscleGroup> catalog =
        ref.watch(muscleCatalogProvider).value ?? const <MuscleGroup>[];
    final List<String> labels = _labels(catalog);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: () async {
            final Set<String>? result = await showMusclePicker(
              context,
              initialSelection: selectedGroupIds,
            );
            if (result != null) onChanged(result);
          },
          icon: const Icon(Icons.view_in_ar_rounded),
          label: Text(
            labels.isEmpty ? 'Choose target muscles' : 'Edit target muscles',
          ),
        ),
        if (labels.isNotEmpty) ...<Widget>[
          const SizedBox(height: FibonacciSpace.compact),
          Wrap(
            spacing: FibonacciSpace.compact,
            runSpacing: FibonacciSpace.compact,
            children: <Widget>[
              for (final String label in labels) Chip(label: Text(label)),
            ],
          ),
        ],
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
