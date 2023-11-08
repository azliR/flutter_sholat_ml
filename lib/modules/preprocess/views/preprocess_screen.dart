import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/components/preprocess_dataset_list_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/accelerometer_chart_widget.dart';
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
  final _zoomPanBehavior = ZoomPanBehavior(
    enablePanning: true,
    enablePinching: true,
    enableDoubleTapZooming: true,
    enableMouseWheelZooming: true,
    zoomMode: ZoomMode.x,
  );
  final _primaryXAxis = NumericAxis(
    visibleMaximum: 400,
  );

  Timer? _timer;

  void _videoListener() {
    if (!mounted) return;

    _notifier.setIsPlaying(
      isPlaying: _videoPlayerController.value.isPlaying,
    );

    if (!_videoPlayerController.value.isPlaying) return;

    final dataItems = ref.read(preprocessProvider).dataItems;
    final currentPosition =
        _videoPlayerController.value.position.inMilliseconds;
    var index = 0;
    for (var i = 0; i < dataItems.length; i++) {
      final dataItem = dataItems[i];
      if ((dataItem.timestamp?.inMilliseconds ?? 0) > currentPosition) {
        index = i - 1;
        break;
      }
    }

    _notifier.setCurrentHighlightedIndex(index);
    _trackballBehavior.showByIndex(index);
    if (ref.read(preprocessProvider).isFollowHighlightedMode) {
      _scrollToDataItemTile(index);
    }
  }

  void _scrollToDataItemTile(int index) {
    _scrollController.animateTo(
      index * 32,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _showSaveDialog() {
    final data = MediaQuery.of(context);

    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Save locally'),
              subtitle: const Text(
                'Dataset will be saved in the disk only',
              ),
              leading: const Icon(Symbols.save_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                _notifier.saveDataset(diskOnly: true);
              },
            ),
            ListTile(
              title: const Text('Upload to the cloud'),
              subtitle: const Text('Dataset will be uploaded'),
              leading: const Icon(Symbols.cloud_upload_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                _notifier.saveDataset();
              },
            ),
            const SizedBox(height: 8),
            SizedBox(height: data.padding.bottom),
          ],
        );
      },
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
        case GetDatasetPropFailureState():
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
    final datasetProp =
        ref.watch(preprocessProvider.select((state) => state.datasetProp));
    final dataItems =
        ref.watch(preprocessProvider.select((state) => state.dataItems));

    return WillPopScope(
      onWillPop: () async {
        final isSelectMode =
            ref.read(preprocessProvider).selectedDataItems.isNotEmpty;

        if (isSelectMode) {
          _notifier.clearSelectedDataItems();
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
                    dataItems.firstOrNull?.deviceLocation.name ?? '',
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
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: (datasetProp?.isSubmitted ?? false)
                      ? const EdgeInsets.fromLTRB(16, 8, 24, 8)
                      : null,
                ),
                onPressed: () {
                  if (datasetProp?.isSubmitted ?? false) {
                    _notifier.saveDataset();
                  } else {
                    _showSaveDialog();
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (datasetProp?.isSubmitted ?? false) ...[
                      const Icon(Symbols.sync_rounded),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      (datasetProp?.isSubmitted ?? false) ? 'Update' : 'Save',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Flex(
          direction: isPortrait ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
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
                    child: AccelerometerChart(
                      dataItems: dataItems,
                      primaryXAxis: _primaryXAxis,
                      zoomPanBehavior: _zoomPanBehavior,
                      trackballBehavior: _trackballBehavior,
                      onTrackballChanged: (trackballArgs) {
                        if (_videoPlayerController.value.isPlaying) return;

                        final index =
                            trackballArgs.chartPointInfo.dataPointIndex ?? 0;

                        _timer?.cancel();
                        _timer = Timer(const Duration(milliseconds: 300), () {
                          _videoPlayerController
                              .seekTo(dataItems[index].timestamp!);
                          _notifier.setCurrentHighlightedIndex(index);
                          if (ref
                              .read(preprocessProvider)
                              .isFollowHighlightedMode) {
                            _scrollToDataItemTile(index);
                          }
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
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PreprocessToolbar(
                    videoPlayerController: _videoPlayerController,
                    onFollowHighlighted: () {
                      _scrollToDataItemTile(
                        ref.read(preprocessProvider).currentHighlightedIndex,
                      );
                    },
                  ),
                  Divider(
                    height: 0,
                    color: colorScheme.outline,
                  ),
                  DefaultTextStyle(
                    style: textTheme.bodyMedium!.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Center(child: Text('i')),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text('timestamp'),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(child: Text('x')),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(child: Text('y')),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(child: Text('z')),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text('noise'),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(),
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
                      dataItems: dataItems,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
