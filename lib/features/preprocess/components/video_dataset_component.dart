import 'package:dartx/dartx_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/video_player/video_player_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/widgets/dataset_prop_tile_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/menus.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

class VideoDataset extends ConsumerStatefulWidget {
  const VideoDataset({
    required this.videoPlayerController,
    required this.isVerticalLayout,
    super.key,
  });

  final VideoPlayerController videoPlayerController;
  final bool isVerticalLayout;

  @override
  ConsumerState<VideoDataset> createState() => _VideoDatasetState();
}

class _VideoDatasetState extends ConsumerState<VideoDataset> {
  // late final PreprocessNotifier _notifier;

  Future<void> _showSpeedMenu(BuildContext context) async {
    final position = determineMenuPosition(context);

    final result = await showMenu<double>(
      context: context,
      position: position,
      initialValue: widget.videoPlayerController.value.playbackSpeed,
      items: [
        const PopupMenuItem(
          height: 40,
          value: 0.1,
          child: Text('0.1'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 0.25,
          child: Text('0.25'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 0.5,
          child: Text('0.5'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 0.75,
          child: Text('0.75'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 1,
          child: Text('Normal'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 1.25,
          child: Text('1.25'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 1.5,
          child: Text('1.5'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 1.75,
          child: Text('1.75'),
        ),
        const PopupMenuItem(
          height: 40,
          value: 2,
          child: Text('2'),
        ),
      ],
    );
    if (result != null) {
      await widget.videoPlayerController.setPlaybackSpeed(result);
      ref.read(videoPlaybackSpeedProvider.notifier).setSpeed(result);
    }
  }

  @override
  void initState() {
    // _notifier = ref.read(preprocessProvider.notifier);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      margin: widget.isVerticalLayout
          ? const EdgeInsets.only(top: 2)
          : const EdgeInsets.fromLTRB(8, 4, 4, 4),
      color: ElevationOverlay.applySurfaceTint(
        colorScheme.surface,
        colorScheme.surfaceTint,
        1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildVideoPlayer(),
            _buildDatasetInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatasetInfo() {
    final textTheme = Theme.of(context).textTheme;

    return Consumer(
      builder: (context, ref, child) {
        final datasetProp =
            ref.watch(preprocessProvider.select((state) => state.datasetProp));

        return Expanded(
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (datasetProp != null) ...[
                        DatasetPropTile(
                          label: 'Dataset ID',
                          content: datasetProp.id,
                          icon: Symbols.key_rounded,
                        ),
                        DatasetPropTile(
                          label: 'Device Location',
                          content: datasetProp.deviceLocation.name,
                          icon: Symbols.watch_rounded,
                        ),
                        DatasetPropTile(
                          label: 'Dataset prop version',
                          content:
                              datasetProp.datasetPropVersion.nameWithIsLatest(
                            latestText: ' (latest)',
                          ),
                          icon: Symbols.manufacturing_rounded,
                        ),
                        DatasetPropTile(
                          label: 'Dataset version',
                          content: datasetProp.datasetVersion.nameWithIsLatest(
                            latestText: ' (latest)',
                          ),
                          icon: Symbols.dataset_rounded,
                        ),
                        const Divider(),
                        DatasetPropTile(
                          label: 'Duration',
                          content: widget.videoPlayerController.value.duration
                              .toString(),
                          icon: Symbols.timer_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 0),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        tooltip: 'Speed\n'
                            'z (decrease)\n'
                            'x (increase)',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Row(
                          children: [
                            const Icon(
                              Symbols.speed_rounded,
                              weight: 300,
                            ),
                            const SizedBox(width: 2),
                            Consumer(
                              builder: (context, ref, child) {
                                final playbackSpeed =
                                    ref.watch(videoPlaybackSpeedProvider);
                                return Text(
                                  playbackSpeed
                                      .toStringAsFixed(2)
                                      .removeSuffix('0'),
                                  style: textTheme.bodyMedium,
                                );
                              },
                            ),
                          ],
                        ),
                        onPressed: () => _showSpeedMenu(context),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer() {
    final isInitialised = widget.videoPlayerController.value.isInitialized;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: AspectRatio(
          aspectRatio: isInitialised
              ? widget.videoPlayerController.value.aspectRatio
              : 2 / 3,
          child: isInitialised
              ? VideoPlayer(widget.videoPlayerController)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
