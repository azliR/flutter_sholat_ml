import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/accelerometer_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/preprocess_dataset_list_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/preprocess_toolbar_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:video_player/video_player.dart';

@RoutePage()
class PreprocessScreen extends ConsumerStatefulWidget {
  const PreprocessScreen({required this.path, super.key});

  final String path;

  @override
  ConsumerState<PreprocessScreen> createState() => _PreprocessScreenState();
}

class _PreprocessScreenState extends ConsumerState<PreprocessScreen> {
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

  Timer? _timer;

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

    _notifier.onCurrentHighlightedIndexChanged(index: index);
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
    _notifier = ref.read(preprocessProvider.notifier);

    final path = widget.path;
    const datasetVideoName = Paths.datasetVideo;

    _videoPlayerController = VideoPlayerController.file(
      File('$path/$datasetVideoName'),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      unawaited(_notifier.initialise(path));

      await _videoPlayerController.initialize();

      _videoPlayerController.addListener(_videoListener);

      if (!mounted) return;
      setState(() {});
    });
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

    ref.listen(preprocessProvider.select((value) => value.presentationState),
        (previous, next) {
      switch (next) {
        case GetDatasetInfoFailureState():
          showErrorSnackbar(context, 'Failed getting dataset info');
        case ReadDatasetsFailureState():
          showErrorSnackbar(context, 'Failed reading datasets');
        case SaveDatasetLoadingState():
          context.loaderOverlay.show();
        case SaveDatasetSuccessState():
          context.loaderOverlay.hide();
          showSnackbar(context, 'Dataset saved');
        case SaveDatasetFailureState():
          context.loaderOverlay.hide();
          showErrorSnackbar(context, 'Failed saving dataset');
        case PreprocessInitial():
          break;
      }
    });
    final datasetInfo =
        ref.watch(preprocessProvider.select((state) => state.datasetInfo));
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Preprocess'),
              Row(
                children: [
                  const Icon(
                    Symbols.watch_rounded,
                    size: 16,
                    weight: 600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    datasets.firstOrNull?.deviceLocation.name ?? '',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          scrolledUnderElevation: 0,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton.tonalIcon(
                onPressed: () => _notifier.onSaveDataset(),
                icon: datasetInfo == null
                    ? const Icon(Symbols.backup_rounded)
                    : const Icon(Symbols.sync_rounded),
                label: Text(datasetInfo == null ? 'Save' : 'Update'),
              ),
            ),
          ],
        ),
        body: () {
          return Flex(
            direction: isPortrait ? Axis.vertical : Axis.horizontal,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      flex: 3,
                      child: AspectRatio(
                        aspectRatio: _videoPlayerController.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController),
                      ),
                    ),
                    Divider(
                      height: 0,
                      color: colorScheme.outline,
                    ),
                    Expanded(
                      flex: 2,
                      child: AccelerometerChart(
                        datasets: datasets,
                        trackballBehavior: _trackballBehavior,
                        onTrackballChanged: (trackballArgs) {
                          if (_videoPlayerController.value.isPlaying) return;

                          final index =
                              trackballArgs.chartPointInfo.dataPointIndex ?? 0;

                          _timer?.cancel();
                          _timer = Timer(const Duration(milliseconds: 300), () {
                            _videoPlayerController
                                .seekTo(datasets[index].timestamp!);
                            _scrollToDatasetTile(index);
                            _notifier.onCurrentHighlightedIndexChanged(
                                index: index,);
                          });
                        },
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
                child: PreprocessToolbar(
                  videoPlayerController: _videoPlayerController,
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
                      child: PreprocessDatasetList(
                        scrollController: _scrollController,
                        trackballBehavior: _trackballBehavior,
                        datasets: datasets,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }(),
      ),
    );
  }
}
