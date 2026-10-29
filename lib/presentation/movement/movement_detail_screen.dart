import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../application/movement_library_controller.dart';
import '../../application/providers.dart';
import '../../core/design/app_palette.dart';
import '../../core/design/fibonacci_scale.dart';
import '../../domain/entities/exercise_video.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/muscle_group.dart';
import 'movement_composer_sheet.dart';

final class MovementDetailScreen extends ConsumerWidget {
  const MovementDetailScreen({required this.movementId, super.key});

  final String movementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Movement? movement = ref.watch(movementByIdProvider(movementId));
    if (movement == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    final TextTheme text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(movement.name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit movement',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showMovementComposer(context, existing: movement),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addVideo(ref),
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('Add video'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          FibonacciSpace.comfortable,
          FibonacciSpace.compact,
          FibonacciSpace.comfortable,
          FibonacciSpace.colossal,
        ),
        children: <Widget>[
          if (movement.hasSummary)
            Text(movement.summary!, style: text.titleMedium),
          if (movement.hasDescription) ...<Widget>[
            const SizedBox(height: FibonacciSpace.compact),
            Text(movement.description!, style: text.bodyMedium),
          ],
          if (movement.muscleGroups.isNotEmpty) ...<Widget>[
            const SizedBox(height: FibonacciSpace.compact),
            Wrap(
              spacing: FibonacciSpace.snug,
              runSpacing: FibonacciSpace.snug,
              children: <Widget>[
                for (final MuscleGroup group in movement.muscleGroups)
                  Chip(label: Text(group.displayName)),
              ],
            ),
          ],
          const SizedBox(height: FibonacciSpace.comfortable),
          Text('Form videos', style: text.headlineMedium),
          const SizedBox(height: FibonacciSpace.tight),
          Text(
            'Film the movement from any angle, then write the cue you want '
            'to remember under each clip. These are shared everywhere you '
            'use this movement.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: FibonacciSpace.regular),
          if (movement.videos.isEmpty)
            const _EmptyVideoHint()
          else
            for (final ExerciseVideo video in movement.videos)
              Padding(
                key: ValueKey<String>(video.id),
                padding: const EdgeInsets.only(bottom: FibonacciSpace.regular),
                child: _VideoSection(video: video),
              ),
        ],
      ),
    );
  }

  Future<void> _addVideo(WidgetRef ref) async {
    final XFile? picked =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    await ref
        .read(movementLibraryProvider.notifier)
        .attachVideo(movementId, picked.path);
  }
}

final class _EmptyVideoHint extends StatelessWidget {
  const _EmptyVideoHint();

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    return Card(
      child: Padding(
        padding: FibonacciSpace.screenPadding,
        child: Column(
          children: <Widget>[
            Icon(
              Icons.video_library_outlined,
              size: FibonacciSize.iconProminent,
              color: palette.inkMuted,
            ),
            const SizedBox(height: FibonacciSpace.regular),
            Text(
              'No videos yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: FibonacciSpace.snug),
            Text(
              'Add as many clips as you like — front angle, side angle, '
              'a common mistake to avoid.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

final class _VideoSection extends ConsumerStatefulWidget {
  const _VideoSection({required this.video});

  final ExerciseVideo video;

  @override
  ConsumerState<_VideoSection> createState() => _VideoSectionState();
}

final class _VideoSectionState extends ConsumerState<_VideoSection> {
  VideoPlayerController? _player;
  late final TextEditingController _note =
      TextEditingController(text: widget.video.note ?? '');
  Timer? _debounce;
  bool _fileMissing = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final String path =
        ref.read(videoStoreProvider).resolvePath(widget.video.localUri);
    final File file = File(path);
    if (!await file.exists()) {
      if (mounted) setState(() => _fileMissing = true);
      return;
    }

    final VideoPlayerController player = VideoPlayerController.file(file);
    try {
      await player.initialize();
      await player.setLooping(true);
    } on Object {
      await player.dispose();
      if (mounted) setState(() => _fileMissing = true);
      return;
    }
    if (!mounted) {
      await player.dispose();
      return;
    }
    setState(() => _player = player);
  }

  @override
  void dispose() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      _saveNote();
    }
    _player?.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onNoteChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _saveNote);
  }

  void _saveNote() => ref
      .read(movementLibraryProvider.notifier)
      .updateVideoNote(widget.video.id, _note.text);

  void _togglePlayback() {
    final VideoPlayerController? player = _player;
    if (player == null) return;
    setState(() => player.value.isPlaying ? player.pause() : player.play());
  }

  Future<void> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Remove this video?'),
        content: const Text('The clip and its note will be deleted.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(movementLibraryProvider.notifier)
        .detachVideo(widget.video);
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _VideoSurface(
            player: _player,
            fileMissing: _fileMissing,
            onToggle: _togglePlayback,
          ),
          Padding(
            padding: FibonacciSpace.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.video.resolvedLabel,
                        style: text.titleMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove video',
                      onPressed: _confirmDelete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: palette.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FibonacciSpace.snug),
                TextField(
                  controller: _note,
                  onChanged: _onNoteChanged,
                  minLines: 2,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Write a cue for this clip — e.g. '
                        '"Keep elbows tucked, don\'t flare them like this."',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _VideoSurface extends StatelessWidget {
  const _VideoSurface({
    required this.player,
    required this.fileMissing,
    required this.onToggle,
  });

  final VideoPlayerController? player;
  final bool fileMissing;
  final VoidCallback onToggle;

  static const double _fallbackAspect = 16 / 9;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.palette;

    if (fileMissing) {
      return AspectRatio(
        aspectRatio: _fallbackAspect,
        child: ColoredBox(
          color: palette.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.videocam_off_outlined, color: palette.inkMuted),
              const SizedBox(height: FibonacciSpace.snug),
              Text(
                'Video file is missing',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      );
    }

    final VideoPlayerController? controller = player;
    if (controller == null) {
      return AspectRatio(
        aspectRatio: _fallbackAspect,
        child: ColoredBox(
          color: palette.surface,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final double aspect = controller.value.aspectRatio;

    return AspectRatio(
      aspectRatio: aspect > 0 ? aspect : _fallbackAspect,
      child: GestureDetector(
        onTap: onToggle,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            VideoPlayer(controller),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: controller,
              builder: (BuildContext context, VideoPlayerValue value, _) =>
                  AnimatedOpacity(
                opacity: value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  size: FibonacciSize.avatarRing,
                  color: palette.onCrimson.withValues(alpha: 0.9),
                  shadows: const <Shadow>[
                    Shadow(blurRadius: FibonacciSpace.compact),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: palette.crimson,
                  bufferedColor: palette.crimsonMuted,
                  backgroundColor: palette.hairline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
