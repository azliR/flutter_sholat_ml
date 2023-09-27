import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/accelerometer_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/dataset_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

@RoutePage()
class PreprocessPage extends ConsumerStatefulWidget {
  const PreprocessPage({required this.path, super.key});

  final String path;

  @override
  ConsumerState<PreprocessPage> createState() => _PreprocessPageState();
}

class _PreprocessPageState extends ConsumerState<PreprocessPage> {
  late final PreprocessNotifier _notifier;

  late final VideoPlayerController _videoPlayerController;

  final _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier)..initialise(widget.path);
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_videoListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(preprocessProvider, (previous, next) async {
      if (previous?.preprocess != next.preprocess) {
        _videoPlayerController = VideoPlayerController.file(
          File(next.preprocess!.videoPath),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await _videoPlayerController.initialize();
        _videoPlayerController.addListener(_videoListener);
        if (!mounted) return;
        setState(() {});
      }
    });

    final preprocess =
        ref.watch(preprocessProvider.select((state) => state.preprocess));
    final datasets =
        ref.watch(preprocessProvider.select((state) => state.datasets));
    final selectedDatasets =
        ref.watch(preprocessProvider.select((state) => state.selectedDatasets));
    final isPlaying =
        ref.watch(preprocessProvider.select((state) => state.isPlaying));

    return WillPopScope(
      onWillPop: () async {
        if (selectedDatasets.isNotEmpty) {
          _notifier.clearSelectedDatasets();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: () {
            if (preprocess == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Flex(
              direction:
                  MediaQuery.of(context).orientation == Orientation.portrait
                      ? Axis.vertical
                      : Axis.horizontal,
              children: [
                Expanded(
                  child: AccelerometerChart(
                    datasets: datasets,
                    onTrackballChanged: (trackballArgs) {
                      final index =
                          trackballArgs.chartPointInfo.dataPointIndex ?? 0;

                      _timer?.cancel();
                      _timer = Timer(const Duration(milliseconds: 500), () {
                        _videoPlayerController
                            .seekTo(datasets[index].timestamp!);
                      });
                    },
                  ),
                ),
                Divider(
                  height: 0,
                  color: colorScheme.outline,
                ),
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController),
                  ),
                ),
                Divider(
                  height: 0,
                  color: colorScheme.outline,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (selectedDatasets.isNotEmpty)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Symbols.flag_rounded),
                        onPressed: () {},
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          _videoPlayerController.pause();
                        } else {
                          _videoPlayerController.play();
                        }
                      },
                      icon: isPlaying
                          ? const Icon(Symbols.pause, weight: 300)
                          : const Icon(Symbols.play_arrow, weight: 300),
                    ),
                  ],
                ),
                Divider(
                  height: 0,
                  color: colorScheme.outline,
                ),
                Expanded(
                  flex: 2,
                  child: Scrollbar(
                    child: ListView.separated(
                      controller: _scrollController,
                      cacheExtent: 32,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemCount: datasets.length,
                      itemBuilder: (context, index) {
                        final dataset = datasets[index];
                        return Consumer(
                          builder: (context, ref, child) {
                            final currentSelectedIndex = ref.watch(
                              preprocessProvider.select(
                                (value) => value.currentSelectedIndex,
                              ),
                            );

                            return DatasetTileWidget(
                              index: index,
                              dataset: dataset,
                              highlighted: index == currentSelectedIndex,
                              selected: selectedDatasets.contains(dataset),
                              onTap: () {
                                if (selectedDatasets.isEmpty) {
                                  _onDatasetTilePressed(dataset);
                                } else {
                                  _notifier.onSelectedDatasetChanged(dataset);
                                }
                              },
                              onLongPress: () =>
                                  _notifier.onSelectedDatasetChanged(dataset),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }(),
        ),
      ),
    );
  }

  void _onDatasetTilePressed(Dataset dataset) {
    _videoPlayerController.seekTo(dataset.timestamp!);
  }

  void _videoListener() {
    if (!mounted) return;
    final datasetsLength = ref.read(preprocessProvider).datasets.length;
    final videoLength = _videoPlayerController.value.duration.inMilliseconds;
    final currentPosition =
        _videoPlayerController.value.position.inMilliseconds;
    final index = (currentPosition / videoLength) * datasetsLength;

    _scrollController.animateTo(
      index * 32,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );

    _notifier
      ..onCurrentSelectedIndexChanged(index: index.round())
      ..onIsPlayingChanged(
        isPlaying: _videoPlayerController.value.isPlaying,
      );
  }
}
