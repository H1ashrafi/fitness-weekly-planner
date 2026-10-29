import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/movement_library_controller.dart';
import '../../application/muscle_catalog_controller.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/muscle_group.dart';
import 'muscle_selection_field.dart';

Future<String?> showMovementComposer(
  BuildContext context, {
  Movement? existing,
}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MovementComposerSheet(existing: existing),
    );

final class MovementComposerSheet extends ConsumerStatefulWidget {
  const MovementComposerSheet({this.existing, super.key});

  final Movement? existing;

  @override
  ConsumerState<MovementComposerSheet> createState() =>
      _MovementComposerSheetState();
}

final class _MovementComposerSheetState
    extends ConsumerState<MovementComposerSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _summary =
      TextEditingController(text: widget.existing?.summary ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final Set<String> _selectedGroupIds = <String>{
    for (final MuscleGroup group in widget.existing?.muscleGroups ??
        const <MuscleGroup>[])
      group.id,
  };

  bool get _isEditing => widget.existing != null;

  bool get _canSave => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _summary.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            FibonacciSpace.comfortable,
            FibonacciSpace.compact,
            FibonacciSpace.comfortable,
            FibonacciSpace.comfortable,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _isEditing ? 'Edit movement' : 'New movement',
                style: text.headlineMedium,
              ),
              const SizedBox(height: FibonacciSpace.tight),
              Text(
                'Define it once — videos, notes and target muscles are '
                'reused every day you add it.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: FibonacciSpace.comfortable),
              TextField(
                controller: _name,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Barbell Bench Press',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: FibonacciSpace.regular),
              TextField(
                controller: _summary,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Short description',
                  hintText: 'One line shown under the name (optional)',
                ),
              ),
              const SizedBox(height: FibonacciSpace.regular),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Details',
                  hintText: 'How to perform it, cues, setup… (optional)',
                ),
              ),
              const SizedBox(height: FibonacciSpace.comfortable),
              Text('Target muscles', style: text.titleMedium),
              const SizedBox(height: FibonacciSpace.compact),
              MuscleSelectionField(
                selectedGroupIds: _selectedGroupIds,
                onChanged: (Set<String> next) => setState(() {
                  _selectedGroupIds
                    ..clear()
                    ..addAll(next);
                }),
              ),
              const SizedBox(height: FibonacciSpace.roomy),
              FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(_isEditing ? 'Save changes' : 'Create movement'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MuscleGroup> get _selectedGroups {
    final List<MuscleGroup> catalog =
        ref.read(muscleCatalogProvider).value ?? const <MuscleGroup>[];
    return catalog
        .where((MuscleGroup group) => _selectedGroupIds.contains(group.id))
        .toList(growable: false);
  }

  Future<void> _save() async {
    final MovementLibraryController controller =
        ref.read(movementLibraryProvider.notifier);
    final Movement? existing = widget.existing;

    String? resultId;
    if (existing == null) {
      resultId = await controller.createMovement(
        name: _name.text,
        summary: _summary.text,
        description: _description.text,
        muscleGroups: _selectedGroups,
      );
    } else {
      await controller.updateDetails(
        existing,
        name: _name.text,
        summary: _summary.text,
        description: _description.text,
        muscleGroups: _selectedGroups,
      );
      resultId = existing.id;
    }

    if (mounted) Navigator.of(context).pop(resultId);
  }
}
