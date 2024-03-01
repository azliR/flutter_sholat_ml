import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:dartx/dartx_io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/components/preprocess_dataset_list_body.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/modules/preprocess/views/preprocess_shortcuts.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/accelerometer_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/bottom_panel_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/dataset_prop_tile_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/preprocess_toolbar_widget.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:flutter_sholat_ml/utils/ui/menus.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:video_player/video_player.dart';

@RoutePage()
class PreprocessScreen extends ConsumerStatefulWidget {
  const PreprocessScreen({required this.path, super.key});

  final String path;

  @override
  ConsumerState<PreprocessScreen> createState() => _PreprocessScreenState();
}

class _PreprocessScreenState extends ConsumerState<PreprocessScreen>
    with SingleTickerProviderStateMixin {
  late final PreprocessNotifier _notifier;

  late final VideoPlayerController _videoPlayerController;
  late final AnimationController _animationController;

  late final MultiSplitViewController _mainSplitController;
  late final MultiSplitViewController _videoChartSplitController;
  late final MultiSplitViewController _dataItemSplitController;

  var _isTrackballControlled = false;

  final _scrollController = ScrollController();
  final _trackballBehavior = TrackballBehavior(
    enable: true,
    shouldAlwaysShow: true,
    tooltipDisplayMode: TrackballDisplayMode.none,
    markerSettings: const TrackballMarkerSettings(
      markerVisibility: TrackballVisibilityMode.visible,
    ),
    activationMode: ActivationMode.doubleTap,
  );
  final _zoomPanBehavior = ZoomPanBehavior(
    enablePanning: true,
    enablePinching: true,
    enableMouseWheelZooming: true,
    enableSelectionZooming: true,
  );
  final _primaryXAxis = const NumericAxis(
    initialVisibleMaximum: 200,
    majorGridLines: MajorGridLines(width: 0),
    axisLine: AxisLine(width: 0.4),
    decimalPlaces: 0,
  );

  final _xDataItems = <num>[];
  final _yDataItems = <num>[];
  final _zDataItems = <num>[];

  Timer? _playVideoDebouncer;
  Timer? _showTrackballDebouncer;
  Timer? _trackballControlDebouncer;
  Timer? _moveHighlightDebouncer;
  double? _lastZoomFactor;
  double? _lastZoomPosition;

  Future<void> _videoListener() async {
    if (!mounted) return;

    _notifier.setIsPlaying(
      isPlaying: _videoPlayerController.value.isPlaying,
    );

    if (!_videoPlayerController.value.isPlaying) return;

    final state = ref.read(preprocessProvider);
    final dataItems = state.dataItems;
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

    if (state.isFollowHighlightedMode) {
      _scrollToDataItemTile(index);
    }
  }

  void _scrollChart(double position) {
    if (_lastZoomFactor == null || _lastZoomPosition == null) return;

    _lastZoomPosition = position;

    _zoomPanBehavior.zoomToSingleAxis(
      _primaryXAxis,
      _lastZoomPosition!,
      _lastZoomFactor!,
    );
  }

  void _scrollChartAndShowTrackball(int index, int dataItemsLength) {
    if (_lastZoomFactor == null || _lastZoomPosition == null) return;

    final maxVisible = dataItemsLength * _lastZoomFactor!;
    final minIndex = dataItemsLength * _lastZoomPosition!;
    final maxIndex = minIndex + maxVisible;

    // final multiplier = ((index - minIndex) / maxVisible).floor();
    // _lastZoomPosition = _lastZoomPosition! + (_lastZoomFactor! * multiplier);

    // _lastZoomPosition =
    //     ((index + 1) / dataItemsLength) - (maxVisible / dataItemsLength);

    // final multiplier = ((maxIndex - index) / maxVisible).floor();
    // _lastZoomPosition = _lastZoomPosition! - (_lastZoomFactor! * multiplier);

    // _lastZoomPosition = (index - 1) / dataItemsLength;

    _isTrackballControlled = true;
    if (index >= maxIndex || index <= minIndex) {
      _lastZoomPosition = (index / dataItemsLength) - (_lastZoomFactor! / 3);

      _zoomPanBehavior.zoomToSingleAxis(
        _primaryXAxis,
        _lastZoomPosition!,
        _lastZoomFactor!,
      );
    } else {
      _showTrackballAt(index);
      return;
    }

    _showTrackballDebouncer?.cancel();
    _showTrackballDebouncer =
        Timer(const Duration(milliseconds: 300), () async {
      _showTrackballAt(index);
      _showTrackballDebouncer?.cancel();
    });
  }

  void _showTrackballAt(int index) {
    _trackballBehavior.showByIndex(index);

    _trackballControlDebouncer?.cancel();
    _trackballControlDebouncer = Timer(const Duration(seconds: 1), () async {
      _isTrackballControlled = false;
      _trackballControlDebouncer?.cancel();
    });
  }

  void _scrollToDataItemTile(int index) {
    final currentPosition = _scrollController.position;
    final maxTopOffset = currentPosition.extentBefore;
    final maxBottomOffset = maxTopOffset + currentPosition.extentInside;
    final currentOffset = index * 32.0;

    if (currentOffset >= maxBottomOffset || currentOffset <= maxTopOffset) {
      _scrollController.animateTo(
        index * 32,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showExitDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save changes'),
          content: const Text(
            "All unsaved changes will be lost if you don't save them",
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Don't save"),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSaveDialog();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCompressDialog() {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Symbols.movie_rounded),
          title: const Text('Compress dataset'),
          content: const Text(
            'Current video in this dataset is not compressed. Compressing it will reduce the size of the dataset.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _notifier.compressVideo();
              },
              child: const Text('Compress'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSaveDialog() {
    final data = MediaQuery.of(context);
    final isUploaded = ref.read(preprocessProvider).datasetProp!.isUploaded;

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
              leading: const Icon(Symbols.sd_card_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                _notifier.saveDataset(diskOnly: true);
              },
            ),
            const Divider(height: 8, indent: 16, endIndent: 16),
            ListTile(
              title: Text(
                isUploaded ? 'Sync to the cloud' : 'Upload to the cloud',
              ),
              subtitle: Text(
                isUploaded
                    ? 'Dataset will be updated with the cloud'
                    : 'Dataset will be uploaded',
              ),
              leading: isUploaded
                  ? const Icon(Symbols.sync_rounded)
                  : const Icon(Symbols.cloud_upload_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                _notifier.saveDataset();
              },
            ),
            if (!isUploaded) ...[
              const Divider(height: 8, indent: 16, endIndent: 16),
              ListTile(
                title: const Text('Upload without video'),
                subtitle: const Text(
                  'Dataset will be backed up without the video and will still counted as in local until you upload the video',
                ),
                leading: const Icon(Symbols.upload_file_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                onTap: () {
                  Navigator.pop(context);
                  _notifier.saveDataset(withVideo: false);
                },
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(height: data.padding.bottom),
          ],
        );
      },
    );
  }

  Future<void> _showSpeedMenu(BuildContext context) async {
    final position = determineMenuPosition(context);

    final result = await showMenu<double>(
      context: context,
      position: position,
      initialValue: _videoPlayerController.value.playbackSpeed,
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
      await _videoPlayerController.setPlaybackSpeed(result);
      _notifier.setVideoPlaybackSpeed(result);
    }
  }

  Future<void> _generateDataSources(List<DataItem> dataItems) async {
    final (x, y, z) =
        await compute<List<DataItem>, (List<num>, List<num>, List<num>)>(
      (dataItems) {
        final x = <num>[];
        final y = <num>[];
        final z = <num>[];

        for (final dataItem in dataItems) {
          x.add(dataItem.x);
          y.add(dataItem.y);
          z.add(dataItem.z);
        }
        return (x, y, z);
      },
      dataItems,
    );
    setState(() {
      _xDataItems.addAll(x);
      _yDataItems.addAll(y);
      _zDataItems.addAll(z);
    });
  }

  List<Area> _resetViews(List<Area> areas) {
    return areas
        .map(
          (area) => Area(
            minimalSize: area.minimalSize,
            minimalWeight: area.minimalWeight,
            weight: 0.5,
          ),
        )
        .toList();
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

    _animationController =
        AnimationController(vsync: this, duration: 2.seconds);

    final mainWeights = LocalStorageService.getPreprocessSplitView1Weights();
    _mainSplitController = MultiSplitViewController(
      areas: [
        Area(minimalWeight: 0.3, weight: mainWeights.elementAtOrNull(0)),
        Area(minimalWeight: 0.3, weight: mainWeights.elementAtOrNull(1)),
      ],
    );

    final videoChartWeights =
        LocalStorageService.getPreprocessSplitView2Weights();
    _videoChartSplitController = MultiSplitViewController(
      areas: [
        Area(minimalWeight: 0.3, weight: videoChartWeights.elementAtOrNull(0)),
        Area(minimalWeight: 0.3, weight: videoChartWeights.elementAtOrNull(1)),
      ],
    );

    final dataItemWeights =
        LocalStorageService.getPreprocessSplitView3Weights();
    _dataItemSplitController = MultiSplitViewController(
      areas: [
        Area(
          minimalWeight: 0.2,
          weight: dataItemWeights.elementAtOrDefault(0, 2),
        ),
        Area(
          minimalSize: 100,
          weight: dataItemWeights.elementAtOrDefault(1, 1),
        ),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await _notifier.initialise(path);
      await _videoPlayerController.initialize();
      _videoPlayerController.addListener(_videoListener);

      final state = ref.read(preprocessProvider);

      await _generateDataSources(state.dataItems);

      final isCompressed = state.datasetProp?.isCompressed ?? false;

      if (!isCompressed) {
        await _showCompressDialog();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _playVideoDebouncer?.cancel();
    _showTrackballDebouncer?.cancel();
    _trackballControlDebouncer?.cancel();
    _moveHighlightDebouncer?.cancel();

    _videoPlayerController.dispose();
    _mainSplitController.dispose();
    _videoChartSplitController.dispose();
    _dataItemSplitController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final deviceWidth = data.size.width;
    final colorScheme = Theme.of(context).colorScheme;

    final shouldVertical = deviceWidth < 720;

    final dataItemsLength = ref.read(preprocessProvider).dataItems.length;

    ref
      ..listen(preprocessProvider.select((value) => value.presentationState),
          (previous, state) {
        switch (state) {
          case PreprocessInitial():
            break;
          case GetDatasetPropFailureState():
            showErrorSnackbar(context, 'Failed getting dataset info');
          case ReadDatasetsFailureState():
            showErrorSnackbar(context, 'Failed reading datasets');
          case AnalyseDatasetLoadingState():
            break;
          case AnalyseDatasetSuccessState():
            break;
          case AnalyseDatasetFailureState():
            showErrorSnackbar(context, 'Failed analysing dataset');
          case CompressVideoLoadingState():
            context.loaderOverlay.show();
          case CompressVideoSuccessState():
            context.loaderOverlay.hide();
            showSnackbar(context, 'Video compressed successfully!');
          case CompressVideoFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, 'Failed compressing video');
          case SaveDatasetLoadingState():
            context.loaderOverlay.show();
          case SaveDatasetAutoSavingState():
            break;
          case SaveDatasetSuccessState():
            if (state.isAutosave) break;
            context.loaderOverlay.hide();
            showSnackbar(context, 'Dataset saved successfully!');
          case SaveDatasetFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, 'Failed saving dataset');
        }
      })
      ..listen(
        preprocessProvider.select((value) => value.currentHighlightedIndex),
        (previous, index) {
          if (index < 0 || index >= dataItemsLength) return;

          _scrollChartAndShowTrackball(index, dataItemsLength);

          if (_videoPlayerController.value.isPlaying) return;

          _playVideoDebouncer?.cancel();
          _playVideoDebouncer = Timer(
              Duration(milliseconds: _isTrackballControlled ? 300 : 0), () {
            final dataItems = ref.read(preprocessProvider).dataItems;

            final videoValue = _videoPlayerController.value;
            final isInitialized = videoValue.isInitialized;
            final isPlaying = videoValue.isPlaying;

            if (isInitialized && !isPlaying) {
              _videoPlayerController.seekTo(
                dataItems[index].timestamp!,
              );
            }

            if (ref.read(preprocessProvider).isFollowHighlightedMode) {
              _scrollToDataItemTile(index);
            }
            _playVideoDebouncer?.cancel();
          });
        },
      )
      ..listen(
        preprocessProvider
            .select((value) => (value.isEdited, value.isAutosave)),
        (previous, next) {
          final isEdited = next.$1;
          final isAutosave = next.$2;
          if (isEdited && isAutosave) {
            _notifier.saveDataset(diskOnly: true, isAutoSaving: true);
          }
        },
      )
      ..listen(
        preprocessProvider.select((value) => value.dataItems),
        (previous, dataItems) {
          _notifier.analyseDataset();
        },
      )
      ..listen(
          preprocessProvider.select(
            (value) =>
                value.presentationState == const SaveDatasetAutoSavingState() ||
                value.presentationState == const AnalyseDatasetLoadingState(),
          ), (previous, rotate) {
        if (rotate) {
          _animationController
            ..repeat()
            ..forward();
        } else {
          _animationController.reset();
        }
      });

    return PreprocessShortcuts(
      scrollController: _scrollController,
      videoPlayerController: _videoPlayerController,
      onLeftKeyPressed: (isControlPressed) {
        final maxVisible = dataItemsLength * _lastZoomFactor!;
        final minIndex = dataItemsLength * _lastZoomPosition!;

        final percentage = isControlPressed ? 0.5 : 0.2;

        _scrollChart((minIndex - (maxVisible * percentage)) / dataItemsLength);
      },
      onRightKeyPressed: (isControlPressed) {
        final maxVisible = dataItemsLength * _lastZoomFactor!;
        final minIndex = dataItemsLength * _lastZoomPosition!;

        final percentage = isControlPressed ? 0.5 : 0.2;

        _scrollChart((minIndex + (maxVisible * percentage)) / dataItemsLength);
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          final isAutosaving = ref.read(preprocessProvider).presentationState ==
              const SaveDatasetAutoSavingState();
          if (isAutosaving) {
            showSnackbar(context, 'Wait until autosaving is finished');
            return;
          }

          final isSelectMode =
              ref.read(preprocessProvider).selectedDataItemIndexes.isNotEmpty;

          final isEdited = ref.read(preprocessProvider).isEdited;
          if (isEdited || isSelectMode) {
            await _showExitDialog();
            return;
          }

          Navigator.pop(context);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Consumer(
              builder: (context, ref, child) {
                final datasetProp = ref.watch(
                  preprocessProvider.select((state) => state.datasetProp),
                );
                return AppBar(
                  title: _buildAppBarTitle(datasetProp),
                  scrolledUnderElevation: 0,
                  actions: _buildAppBarActions(datasetProp),
                );
              },
            ),
          ),
          body: MultiSplitView(
            controller: _mainSplitController,
            axis: shouldVertical ? Axis.vertical : Axis.horizontal,
            dividerBuilder: _buildSplitDivider,
            onWeightChange: () {
              final weights = _mainSplitController.areas
                  .map((area) => area.weight ?? 1)
                  .toList();
              LocalStorageService.setPreprocessSplitView1Weights(weights);
            },
            children: [
              MultiSplitView(
                controller: _videoChartSplitController,
                axis: Axis.vertical,
                dividerBuilder: _buildSplitDivider,
                onWeightChange: () {
                  final weights = _videoChartSplitController.areas
                      .map((area) => area.weight ?? 1)
                      .toList();
                  LocalStorageService.setPreprocessSplitView2Weights(weights);
                },
                children: [
                  Row(
                    children: [
                      _buildVideoPlayer(),
                      _buildDatasetInfo(),
                    ],
                  ),
                  AccelerometerChart(
                    x: _xDataItems,
                    y: _yDataItems,
                    z: _zDataItems,
                    primaryXAxis: _primaryXAxis,
                    zoomPanBehavior: _zoomPanBehavior,
                    trackballBehavior: _trackballBehavior,
                    onTrackballChanged: (trackballArgs) {
                      if (_videoPlayerController.value.isPlaying) return;

                      if (_isTrackballControlled) return;

                      _moveHighlightDebouncer?.cancel();
                      _moveHighlightDebouncer =
                          Timer(const Duration(milliseconds: 300), () {
                        final index =
                            trackballArgs.chartPointInfo.dataPointIndex ?? 0;
                        _notifier.setCurrentHighlightedIndex(index);
                      });
                    },
                    onActualRangeChanged: (args) {
                      final visibleMax = args.visibleMax as num;
                      final visibleMin = args.visibleMin as num;
                      final actualMax = args.actualMax as num;
                      final actualVisible = visibleMax - visibleMin;

                      _lastZoomFactor = actualVisible / actualMax;
                      _lastZoomPosition = visibleMin / actualMax;
                    },
                  ),
                ],
              ),
              Consumer(
                builder: (context, ref, child) {
                  final showBottomPanel = ref.watch(
                    preprocessProvider.select((value) => value.showBottomPanel),
                  );

                  return MultiSplitView(
                    controller: _dataItemSplitController,
                    axis: Axis.vertical,
                    dividerBuilder: _buildSplitDivider,
                    onWeightChange: () {
                      final weights = _dataItemSplitController.areas
                          .map((area) => area.weight ?? 1)
                          .toList();
                      LocalStorageService.setPreprocessSplitView3Weights(
                        weights,
                      );
                    },
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PreprocessToolbar(
                            videoPlayerController: _videoPlayerController,
                            onFollowHighlighted: () {
                              final state = ref.read(preprocessProvider);
                              _scrollToDataItemTile(
                                state.currentHighlightedIndex,
                              );
                            },
                          ),
                          Divider(
                            height: 0,
                            color: colorScheme.outline,
                          ),
                          _buildDataItemHeader(),
                          Divider(
                            height: 0,
                            color: colorScheme.outline,
                          ),
                          Expanded(
                            child: PreprocessDatasetList(
                              scrollController: _scrollController,
                              onDataItemPressed: (index) async {
                                final state = ref.read(preprocessProvider);

                                if (state.isJumpSelectMode) {
                                  await _notifier.jumpSelect(index);
                                } else if (state
                                    .selectedDataItemIndexes.isNotEmpty) {
                                  _notifier.setSelectedDataset(index);
                                }
                                _notifier.setCurrentHighlightedIndex(index);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (showBottomPanel)
                        Consumer(
                          builder: (context, ref, child) {
                            final problems = ref.watch(
                              preprocessProvider.select(
                                (value) => value.problems,
                              ),
                            );
                            return BottomPanel(
                              problems: problems,
                              onProblemPressed: (problem) {
                                _notifier.clearSelectedDataItems();
                                switch (problem) {
                                  case MissingLabelProblem():
                                  case DeprecatedLabelProblem():
                                  case DeprecatedLabelCategoryProblem():
                                  case WrongMovementSequenceProblem():
                                    _scrollController
                                        .jumpTo(problem.startIndex * 32);
                                    _notifier.setCurrentHighlightedIndex(
                                      problem.startIndex,
                                    );
                                }
                              },
                              onClosePressed: () =>
                                  _notifier.setShowBottomPanel(enable: false),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitDivider(
    Axis axis,
    int index,
    bool resizable,
    bool dragging,
    bool highlighted,
    MultiSplitViewThemeData themeData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: axis == Axis.vertical ? 4 : 0,
          vertical: axis == Axis.horizontal ? 4 : 0,
        ),
        color: highlighted ? colorScheme.outline : Colors.transparent,
        child: axis == Axis.vertical
            ? VerticalDivider(color: colorScheme.outline)
            : Divider(color: colorScheme.outline),
      ),
    );
  }

  Widget _buildAppBarTitle(DatasetProp? datasetProp) {
    final data = MediaQuery.of(context);
    final width = data.size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, child) {
            final isEdited = ref.watch(
              preprocessProvider.select((value) => value.isEdited),
            );
            final isAutosaving = ref.watch(
              preprocessProvider.select(
                (value) =>
                    value.presentationState ==
                    const SaveDatasetAutoSavingState(),
              ),
            );
            final isAnalysing = ref.watch(
              preprocessProvider.select(
                (value) =>
                    value.presentationState ==
                    const AnalyseDatasetLoadingState(),
              ),
            );
            return Row(
              children: [
                Flexible(
                  child: Text(
                    'Preprocess${isEdited ? '*' : ''}',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ),
                if (datasetProp != null) ...[
                  if (width >= 480)
                    const SizedBox(width: 16)
                  else
                    const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        () {
                          if (isAutosaving || isAnalysing) {
                            return Symbols.sync_rounded;
                          }
                          return datasetProp.isSyncedWithCloud
                              ? Symbols.cloud_done_rounded
                              : Symbols.sync_saved_locally;
                        }(),
                        size: 20,
                        fill: () {
                          if (isAutosaving || isAnalysing) {
                            return 0.0;
                          }
                          return datasetProp.isSyncedWithCloud ? 1.0 : 0.0;
                        }(),
                        color: () {
                          if (isAutosaving || isAnalysing) {
                            return colorScheme.onBackground;
                          }
                          return datasetProp.isSyncedWithCloud
                              ? colorScheme.primary
                              : colorScheme.onBackground;
                        }(),
                      )
                          .animate(
                            autoPlay: false,
                            controller: _animationController,
                          )
                          .rotate(
                            begin: 1,
                            end: 0,
                          ),
                      if (width >= 480) ...[
                        const SizedBox(width: 8),
                        Text(
                          () {
                            if (isAnalysing) {
                              return 'Analysing...';
                            }
                            if (isAutosaving) {
                              return 'Saving...';
                            }
                            return datasetProp.isSyncedWithCloud
                                ? 'Saved in cloud'
                                : 'Saved in local';
                          }(),
                          style: textTheme.bodySmall?.copyWith(
                            color: () {
                              if (isAutosaving) {
                                return colorScheme.onBackground;
                              }
                              return datasetProp.isSyncedWithCloud
                                  ? colorScheme.primary
                                  : colorScheme.onBackground;
                            }(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        if (datasetProp != null) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: datasetProp.hasEvaluated ? colorScheme.secondary : null,
              border: datasetProp.hasEvaluated
                  ? null
                  : Border.all(
                      strokeAlign: BorderSide.strokeAlignOutside,
                      color: colorScheme.outline,
                    ),
            ),
            child: Text(
              datasetProp.hasEvaluated ? 'Evaluated' : 'Not evaluated',
              style: textTheme.bodySmall?.copyWith(
                color: datasetProp.hasEvaluated
                    ? colorScheme.onSecondary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildAppBarActions(DatasetProp? datasetProp) {
    final data = MediaQuery.of(context);
    final width = data.size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return [
      if (datasetProp != null) ...[
        if (width >= 600)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: colorScheme.secondaryContainer,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      'AutoSave',
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 40,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Consumer(
                          builder: (context, ref, child) {
                            final isAutosave = ref.watch(
                              preprocessProvider
                                  .select((value) => value.isAutosave),
                            );
                            return Switch(
                              value: isAutosave,
                              onChanged: (value) {
                                _notifier.setIsAutosave(isAutosave: value);
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
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
            ),
            onPressed: _showSaveDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  datasetProp.isUploaded ? 'Update' : 'Save',
                ),
                const SizedBox(width: 8),
                const Icon(Symbols.arrow_drop_down_rounded),
              ],
            ),
          ),
        ),
        _buildMenu(datasetProp),
        const SizedBox(width: 12),
      ],
    ];
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
                          content:
                              _videoPlayerController.value.duration.toString(),
                          icon: Symbols.timer_rounded,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Divider(height: 0),
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
                                final playbackSpeed = ref.watch(
                                  preprocessProvider.select(
                                    (value) => value.videoPlaybackSpeed,
                                  ),
                                );
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
    final isInitialised = _videoPlayerController.value.isInitialized;

    return AspectRatio(
      aspectRatio:
          isInitialised ? _videoPlayerController.value.aspectRatio : 2 / 3,
      child: isInitialised
          ? VideoPlayer(_videoPlayerController)
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildDataItemHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTextStyle(
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
    );
  }

  Widget _buildMenu(DatasetProp datasetProp) {
    final data = MediaQuery.of(context);
    final width = data.size.width;

    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          iconSize: 20,
          tooltip: 'Menu',
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: child!,
        );
      },
      menuChildren: [
        SubmenuButton(
          menuChildren: [
            if (width < 600)
              Consumer(
                builder: (context, ref, child) {
                  final isAutosave = ref.watch(
                    preprocessProvider.select((value) => value.isAutosave),
                  );

                  return MenuItemButton(
                    leadingIcon: isAutosave
                        ? const Icon(Symbols.check_box_rounded, fill: 1)
                        : const Icon(Symbols.check_box_outline_blank_rounded),
                    onPressed: () => _notifier.setIsAutosave(
                      isAutosave: !isAutosave,
                    ),
                    child: const Text('AutoSave'),
                  );
                },
              ),
            MenuItemButton(
              leadingIcon: datasetProp.hasEvaluated
                  ? const Icon(Symbols.check_box_rounded, fill: 1)
                  : const Icon(Symbols.check_box_outline_blank_rounded),
              onPressed: () => _notifier.setEvaluated(
                hasEvaluated: !datasetProp.hasEvaluated,
              ),
              child: const Text('Has evaluated'),
            ),
          ],
          child: const Text('File'),
        ),
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Symbols.rule_rounded),
              onPressed: () => _notifier.analyseDataset(),
              child: const Text('Analyse dataset'),
            ),
            MenuItemButton(
              leadingIcon: const Icon(Symbols.movie_rounded),
              onPressed: datasetProp.isCompressed ? null : _showCompressDialog,
              child: Text(
                datasetProp.isCompressed
                    ? 'Video compressed'
                    : 'Compress video',
              ),
            ),
          ],
          child: const Text('Dataset'),
        ),
        SubmenuButton(
          menuChildren: [
            Consumer(
              builder: (context, ref, child) {
                final isShowBottomPanel = ref.watch(
                  preprocessProvider.select((value) => value.showBottomPanel),
                );
                return MenuItemButton(
                  leadingIcon: isShowBottomPanel
                      ? const Icon(Symbols.check_box_rounded, fill: 1)
                      : const Icon(Symbols.check_box_outline_blank_rounded),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.backquote,
                    control: true,
                  ),
                  onPressed: () =>
                      _notifier.setShowBottomPanel(enable: !isShowBottomPanel),
                  child: const Text('Problems'),
                );
              },
            ),
            MenuItemButton(
              leadingIcon: const Icon(Symbols.reset_wrench_rounded),
              onPressed: () {
                _mainSplitController.areas =
                    _resetViews(_mainSplitController.areas);
                _videoChartSplitController.areas =
                    _resetViews(_videoChartSplitController.areas);
                _dataItemSplitController.areas =
                    _resetViews(_dataItemSplitController.areas);
              },
              child: const Text('Reset view'),
            ),
          ],
          child: const Text('View'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
