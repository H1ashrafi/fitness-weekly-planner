import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interactive_3d/interactive_3d.dart';

import '../../application/muscle_catalog_controller.dart';
import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/anatomy_region.dart';
import '../../domain/entities/muscle_group.dart';
import 'anatomy_3d_selector.dart';
import 'anatomy_muscle_selector.dart';

String regionGroupId(AnatomyRegion region) => 'region:${region.name}';

enum _BodyView { model3d, map2d }

Future<Set<String>?> showMusclePicker(
  BuildContext context, {
  required Set<String> initialSelection,
}) =>
    Navigator.of(context).push<Set<String>>(
      MaterialPageRoute<Set<String>>(
        fullscreenDialog: true,
        builder: (_) => MusclePickerScreen(initialSelection: initialSelection),
      ),
    );

final class MusclePickerScreen extends ConsumerStatefulWidget {
  const MusclePickerScreen({required this.initialSelection, super.key});

  final Set<String> initialSelection;

  @override
  ConsumerState<MusclePickerScreen> createState() => _MusclePickerScreenState();
}

final class _MusclePickerScreenState extends ConsumerState<MusclePickerScreen> {
  late final Set<String> _selected = Set<String>.of(widget.initialSelection);
  late _BodyView _view =
      Anatomy3dSelector.isSupported ? _BodyView.model3d : _BodyView.map2d;

  final Interactive3dController _controller = Interactive3dController();
  double _zoom = 1.0;

  static const double _minZoom = 0.4;
  static const double _maxZoom = 4.0;

  Set<AnatomyRegion> get _selectedRegions => <AnatomyRegion>{
        for (final String id in _selected)
          if (id.startsWith('region:'))
            if (AnatomyRegion.tryParse(id.substring(7)) case final AnatomyRegion region)
              region,
      };

  void _toggleRegion(AnatomyRegion region) => setState(() {
        final String id = regionGroupId(region);
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
      });

  void _replaceRegions(Set<AnatomyRegion> regions) => setState(() {
        _selected.removeWhere((String id) => id.startsWith('region:'));
        _selected.addAll(regions.map(regionGroupId));
      });

  void _toggleGroup(String id) => setState(() {
        _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
      });

  Future<void> _applyZoom(double next) async {
    final double clamped = next.clamp(_minZoom, _maxZoom);
    setState(() => _zoom = clamped);
    try {
      await _controller.setCameraZoomLevel(clamped);
    } on StateError {
      // The 3D view is not attached (2D mode); nothing to zoom.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final bool showing3d =
        _view == _BodyView.model3d && Anatomy3dSelector.isSupported;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Target muscles'),
        actions: <Widget>[
          IconButton(
            tooltip: 'About this model',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showModelCredits(context),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            child: const Text('Done'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            if (Anatomy3dSelector.isSupported)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FibonacciSpace.comfortable,
                  vertical: FibonacciSpace.compact,
                ),
                child: _ViewToggle(
                  view: _view,
                  onChanged: (_BodyView view) => setState(() => _view = view),
                ),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: FibonacciSpace.comfortable,
                ),
                decoration: BoxDecoration(
                  color: palette.surfaceRaised,
                  borderRadius: FibonacciRadius.card,
                ),
                clipBehavior: Clip.antiAlias,
                child: showing3d
                    ? Stack(
                        children: <Widget>[
                          Positioned.fill(
                            child: Anatomy3dSelector(
                              controller: _controller,
                              selectedRegions: _selectedRegions,
                              onRegionsChanged: _replaceRegions,
                            ),
                          ),
                          Positioned(
                            right: FibonacciSpace.compact,
                            bottom: FibonacciSpace.compact,
                            child: _ZoomControls(
                              onZoomIn: () => _applyZoom(_zoom * 1.35),
                              onZoomOut: () => _applyZoom(_zoom / 1.35),
                              onReset: () => _applyZoom(1.0),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(FibonacciSpace.compact),
                        child: AnatomyMuscleSelector(
                          selectedRegions: _selectedRegions,
                          onToggle: _toggleRegion,
                        ),
                      ),
              ),
            ),
            _SelectionPanel(
              selectedRegions: _selectedRegions,
              selectedIds: _selected,
              onRemoveRegion: _toggleRegion,
              onToggleGroup: _toggleGroup,
              onAddCustom: (String name) =>
                  ref.read(muscleCatalogProvider.notifier).addCustom(name),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showModelCredits(BuildContext context) => showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Anatomy model'),
        content: const Text(
          'The 3D muscle model is derived from BodyParts3D, '
          '© The Database Center for Life Science, licensed under '
          'CC Attribution-ShareAlike 2.1 Japan.\n\n'
          'The adapted model bundled with this app is shared under the '
          'same licence.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );

final class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: FibonacciRadius.chip,
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: 'Zoom in',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add_rounded),
          ),
          IconButton(
            tooltip: 'Reset zoom',
            onPressed: onReset,
            icon: const Icon(Icons.center_focus_strong_rounded),
          ),
          IconButton(
            tooltip: 'Zoom out',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove_rounded),
          ),
        ],
      ),
    );
  }
}

final class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final _BodyView view;
  final ValueChanged<_BodyView> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return SegmentedButton<_BodyView>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: palette.crimson,
        selectedForegroundColor: palette.onCrimson,
      ),
      segments: const <ButtonSegment<_BodyView>>[
        ButtonSegment<_BodyView>(
          value: _BodyView.model3d,
          label: Text('3D'),
          icon: Icon(Icons.view_in_ar_rounded),
        ),
        ButtonSegment<_BodyView>(
          value: _BodyView.map2d,
          label: Text('2D'),
          icon: Icon(Icons.accessibility_new_rounded),
        ),
      ],
      selected: <_BodyView>{view},
      onSelectionChanged: (Set<_BodyView> selection) =>
          onChanged(selection.first),
    );
  }
}

final class _SelectionPanel extends ConsumerWidget {
  const _SelectionPanel({
    required this.selectedRegions,
    required this.selectedIds,
    required this.onRemoveRegion,
    required this.onToggleGroup,
    required this.onAddCustom,
  });

  final Set<AnatomyRegion> selectedRegions;
  final Set<String> selectedIds;
  final ValueChanged<AnatomyRegion> onRemoveRegion;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<String> onAddCustom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<MuscleGroup> catalog =
        ref.watch(muscleCatalogProvider).value ?? const <MuscleGroup>[];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: FibonacciSpace.expansive * 2),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          FibonacciSpace.comfortable,
          FibonacciSpace.compact,
          FibonacciSpace.comfortable,
          FibonacciSpace.comfortable,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              selectedRegions.isEmpty
                  ? 'Tap a muscle on the body to select it.'
                  : '${selectedRegions.length} selected',
              style: text.labelMedium,
            ),
            if (selectedRegions.isNotEmpty) ...<Widget>[
              const SizedBox(height: FibonacciSpace.compact),
              Wrap(
                spacing: FibonacciSpace.compact,
                runSpacing: FibonacciSpace.compact,
                children: <Widget>[
                  for (final AnatomyRegion region in selectedRegions)
                    InputChip(
                      label: Text(region.label),
                      onDeleted: () => onRemoveRegion(region),
                    ),
                ],
              ),
            ],
            const SizedBox(height: FibonacciSpace.regular),
            Text('Other muscles', style: text.labelMedium),
            const SizedBox(height: FibonacciSpace.compact),
            Wrap(
              spacing: FibonacciSpace.compact,
              runSpacing: FibonacciSpace.compact,
              children: <Widget>[
                for (final MuscleGroup group
                    in catalog.where((MuscleGroup g) => g.isUserDefined))
                  FilterChip(
                    label: Text(group.displayName),
                    selected: selectedIds.contains(group.id),
                    showCheckmark: false,
                    onSelected: (_) => onToggleGroup(group.id),
                  ),
                _AddCustomMuscleChip(onSubmitted: onAddCustom),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _AddCustomMuscleChip extends StatelessWidget {
  const _AddCustomMuscleChip({required this.onSubmitted});

  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: const Icon(Icons.add_rounded, size: FibonacciSize.iconCompact),
        label: const Text('Custom'),
        onPressed: () => _promptForName(context),
      );

  Future<void> _promptForName(BuildContext context) async {
    final TextEditingController controller = TextEditingController();
    final String? entered = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Custom muscle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Muscle name'),
          onSubmitted: (String value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (entered != null && entered.trim().isNotEmpty) onSubmitted(entered);
  }
}
