import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/accelerometer_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/dataset_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
  final _trackballBehavior = TrackballBehavior(
    enable: true,
    shouldAlwaysShow: true,
    tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
    markerSettings: const TrackballMarkerSettings(
      markerVisibility: TrackballVisibilityMode.visible,
    ),
  );

  var _showWarning = true;

  Timer? _timer;

  void _onDatasetTilePressed(int index, Dataset dataset) {
    _videoPlayerController.seekTo(dataset.timestamp!);
    _notifier.onCurrentSelectedIndexChanged(index: index);
    _trackballBehavior.showByIndex(index);
  }

  void _videoListener() {
    if (!mounted) return;

    _notifier.onIsPlayingChanged(
      isPlaying: _videoPlayerController.value.isPlaying,
    );

    if (!_videoPlayerController.value.isPlaying) return;

    final datasets = ref.read(preprocessProvider).datasets;
    final currentPosition =
        _videoPlayerController.value.position.inMilliseconds;
    var index = 0;
    for (var i = 0; i < datasets.length; i++) {
      final dataset = datasets[i];
      if ((dataset.timestamp?.inMilliseconds ?? 0) > currentPosition) {
        index = i - 1;
        break;
      }
    }

    _notifier.onCurrentSelectedIndexChanged(index: index);
    _scrollToDatasetTile(index);
    _trackballBehavior.showByIndex(index);
  }

  void _scrollToDatasetTile(int index) {
    _scrollController.animateTo(
      index * 32,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

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
    final textTheme = Theme.of(context).textTheme;

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    ref.listen(preprocessProvider, (previous, next) async {
      if (previous?.preprocess != next.preprocess) {
        _videoPlayerController = VideoPlayerController.file(
          File(next.preprocess!.videoPath),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await _videoPlayerController.initialize();
        await _videoPlayerController.setPlaybackSpeed(0.5);
        _videoPlayerController.addListener(_videoListener);
        if (!mounted) return;
        setState(() {});
      }
    });

    final preprocess =
        ref.watch(preprocessProvider.select((state) => state.preprocess));
    final datasets =
        ref.watch(preprocessProvider.select((state) => state.datasets));

    return WillPopScope(
      onWillPop: () async {
        final isSelectMode =
            ref.read(preprocessProvider).selectedDatasets.isNotEmpty;

        if (isSelectMode) {
          _notifier.clearSelectedDatasets();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Preprocess'),
          scrolledUnderElevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton.tonal(
                onPressed: () {},
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: () {
            if (preprocess == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Flex(
              direction: isPortrait ? Axis.vertical : Axis.horizontal,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        flex: 2,
                        child: AccelerometerChart(
                          datasets: datasets,
                          trackballBehavior: _trackballBehavior,
                          onTrackballChanged: (trackballArgs) {
                            if (_videoPlayerController.value.isPlaying) return;

                            final index =
                                trackballArgs.chartPointInfo.dataPointIndex ??
                                    0;

                            _timer?.cancel();
                            _timer =
                                Timer(const Duration(milliseconds: 300), () {
                              _videoPlayerController
                                  .seekTo(datasets[index].timestamp!);
                              _scrollToDatasetTile(index);
                              _notifier.onCurrentSelectedIndexChanged(
                                index: index,
                              );
                            });
                          },
                        ),
                      ),
                      Divider(
                        height: 0,
                        color: colorScheme.outline,
                      ),
                      Expanded(
                        flex: 3,
                        child: AspectRatio(
                          aspectRatio: _videoPlayerController.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPortrait)
                  Divider(
                    height: 0,
                    color: colorScheme.outline,
                  )
                else
                  VerticalDivider(
                    width: 0,
                    color: colorScheme.outline,
                  ),
                SafeArea(
                  bottom: !isPortrait,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final selectedDatasets = ref.watch(
                        preprocessProvider
                            .select((state) => state.selectedDatasets),
                      );

                      return Flex(
                        direction: isPortrait ? Axis.horizontal : Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (selectedDatasets.isNotEmpty)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(
                                Symbols.new_label_rounded,
                                weight: 300,
                              ),
                              onPressed: _showTagDialog,
                            ),
                          Consumer(
                            builder: (context, ref, child) {
                              final isPlaying = ref.watch(preprocessProvider
                                  .select((state) => state.isPlaying));

                              return IconButton(
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                                    : const Icon(Symbols.play_arrow,
                                        weight: 300),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (isPortrait)
                  Divider(
                    height: 0,
                    color: colorScheme.outline,
                  )
                else
                  VerticalDivider(
                    width: 1,
                    color: colorScheme.outline,
                  ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DefaultTextStyle(
                        style: textTheme.bodyMedium!.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Center(child: Text('i')),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Center(
                                child: Text('timestamp'),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Center(child: Text('x')),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Center(child: Text('y')),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Center(child: Text('z')),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Icon(
                                  Symbols.ecg_heart_rounded,
                                  size: 16,
                                  weight: 600,
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Center(child: Text('')),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 0,
                        color: colorScheme.outline,
                      ),
                      Expanded(
                        child: Scrollbar(
                          child: ListView.separated(
                            controller: _scrollController,
                            cacheExtent: 32,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 0),
                            itemCount: datasets.length,
                            itemBuilder: (context, index) {
                              final dataset = datasets[index];
                              return Consumer(
                                builder: (context, ref, child) {
                                  final selectedDatasets = ref.watch(
                                    preprocessProvider.select(
                                      (state) => state.selectedDatasets,
                                    ),
                                  );
                                  final currentSelectedIndex = ref.watch(
                                    preprocessProvider.select(
                                      (value) => value.currentSelectedIndex,
                                    ),
                                  );
                                  final selected =
                                      selectedDatasets.contains(dataset);

                                  return DatasetTileWidget(
                                    index: index,
                                    dataset: dataset,
                                    highlighted: index == currentSelectedIndex,
                                    selected: selected,
                                    onTap: () async {
                                      if (selectedDatasets.isEmpty) {
                                        _onDatasetTilePressed(index, dataset);
                                      } else {
                                        if (dataset.isLabeled &&
                                            !selected &&
                                            _showWarning) {
                                          final result =
                                              await _showWarningDialog();
                                          if (result == null || !result) return;
                                        }
                                        _notifier
                                            .onSelectedDatasetChanged(dataset);
                                      }
                                    },
                                    onLongPress: () async {
                                      if (dataset.isLabeled && _showWarning) {
                                        final result =
                                            await _showWarningDialog();
                                        if (result == null || !result) return;
                                      }
                                      _notifier
                                          .onSelectedDatasetChanged(dataset);
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }(),
        ),
      ),
    );
  }

  Future<bool?> _showWarningDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        final dontShowAgainProvider =
            StateProvider.autoDispose<bool>((ref) => false);

        return Consumer(
          builder: (context, ref, child) {
            final dontShowAgain = ref.watch(dontShowAgainProvider);
            return AlertDialog(
              title: const Text('Warning'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This dataset has been tagged. Are you sure you want to change the tag?',
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (value) {
                          ref
                              .read(dontShowAgainProvider.notifier)
                              .update((state) => value!);
                        },
                      ),
                      const Text("Don't show this again"),
                    ],
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    _showWarning = !dontShowAgain;
                  },
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                    _showWarning = !dontShowAgain;
                  },
                  child: const Text('Change tag'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTagDialog() {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final categoryProvider =
            StateProvider.autoDispose<SholatMovementCategory?>((ref) => null);
        final controller = TextEditingController();
        final mediaQuery = MediaQuery.of(context);
        final size = mediaQuery.size;

        return Consumer(
          builder: (context, ref, child) {
            final selectedCategory = ref.watch(categoryProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu(
                      width: size.width - 24,
                      label: const Text('Category'),
                      onSelected: (value) {
                        if (value != selectedCategory) {
                          ref.read(categoryProvider.notifier).update(
                                (state) => value,
                              );
                          controller.clear();
                        }
                      },
                      dropdownMenuEntries: SholatMovementCategory.values.map(
                        (e) {
                          return DropdownMenuEntry(
                            label: e.name,
                            value: e,
                          );
                        },
                      ).toList(),
                    ),
                    if (selectedCategory != null &&
                        selectedCategory != SholatMovementCategory.lainnya) ...[
                      const SizedBox(height: 12),
                      DropdownMenu(
                        width: size.width - 24,
                        controller: controller,
                        label: const Text('Movement'),
                        dropdownMenuEntries: () {
                          switch (selectedCategory) {
                            case SholatMovementCategory.takbir:
                              return Takbir.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e,
                                );
                              }).toList();
                            case SholatMovementCategory.berdiri:
                              return Berdiri.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e,
                                );
                              }).toList();
                            case SholatMovementCategory.ruku:
                              return Ruku.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e,
                                );
                              }).toList();
                            case SholatMovementCategory.iktidal:
                              return Iktidal.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e,
                                );
                              }).toList();
                            case SholatMovementCategory.qunut:
                              return Qunut.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e,
                                );
                              }).toList();
                            case SholatMovementCategory.sujud:
                              return Sujud.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e,
                                );
                              }).toList();
                            case SholatMovementCategory.duduk:
                              return Duduk.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e,
                                );
                              }).toList();
                            case SholatMovementCategory.lainnya:
                              return <DropdownMenuEntry<void>>[];
                          }
                        }(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        runAlignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _notifier.onTaggedDatasets(
                                selectedCategory!.code,
                                controller.text,
                              );
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
