import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:dartx/dartx_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/components/preprocess_dataset_list_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/accelerometer_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/dataset_prop_tile_widget.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/preprocess_toolbar_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/menus.dart';
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
                    ? 'Dataset will be updated'
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
      await _notifier.initialise(path);
      await _videoPlayerController.initialize();

      _videoPlayerController.addListener(_videoListener);

      final isCompressed = ref.read(
        preprocessProvider
            .select((value) => value.datasetProp?.isCompressed ?? false),
      );

      if (!isCompressed) {
        await _showCompressDialog();
      }

      if (!mounted) return;

      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _videoPlayerController
      ..removeListener(_videoListener)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final width = data.size.width;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final shouldVertical = data.size.width < 720;

    ref.listen(preprocessProvider.select((value) => value.presentationState),
        (previous, next) {
      switch (next) {
        case PreprocessInitial():
          break;
        case GetDatasetPropFailureState():
          showErrorSnackbar(context, 'Failed getting dataset info');
        case ReadDatasetsFailureState():
          showErrorSnackbar(context, 'Failed reading datasets');
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
        case SaveDatasetSuccessState():
          context.loaderOverlay.hide();
          showSnackbar(context, 'Dataset saved successfully!');
        case SaveDatasetFailureState():
          context.loaderOverlay.hide();
          showErrorSnackbar(context, 'Failed saving dataset');
      }
    });
    final datasetProp =
        ref.watch(preprocessProvider.select((state) => state.datasetProp));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final isSelectMode =
            ref.read(preprocessProvider).selectedDataItemIndexes.isNotEmpty;

        if (isSelectMode) {
          _notifier.clearSelectedDataItems();
          return;
        }

        final isEdited = ref.read(preprocessProvider).isEdited;
        if (isEdited) {
          await _showExitDialog();
          return;
        }

        Navigator.pop(context);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Preprocess',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                ),
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
                    color:
                        datasetProp.hasEvaluated ? colorScheme.secondary : null,
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
          ),
          scrolledUnderElevation: 0,
          actions: [
            if (datasetProp != null) ...[
              if (width >= 800)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilledButton.tonalIcon(
                    onPressed:
                        datasetProp.isCompressed ? null : _showCompressDialog,
                    icon: const Icon(Symbols.movie_rounded),
                    label: Text(
                      datasetProp.isCompressed
                          ? 'Video compressed'
                          : 'Compress video',
                    ),
                  ),
                ),
              if (width >= 600)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilledButton.tonalIcon(
                    onPressed: () => _notifier.setEvaluated(
                      hasEvaluated: !datasetProp.hasEvaluated,
                    ),
                    icon: datasetProp.hasEvaluated
                        ? const Icon(Symbols.cancel_rounded)
                        : const Icon(Symbols.check_circle_rounded),
                    label: Text(
                      datasetProp.hasEvaluated
                          ? 'Mark as not evaluated'
                          : 'Mark as evaluated',
                    ),
                  ),
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
              if (width < 800) _buildMenu(datasetProp),
              const SizedBox(width: 12),
            ],
          ],
        ),
        body: Flex(
          direction: shouldVertical ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        AspectRatio(
                          aspectRatio: _videoPlayerController.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
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
                                        content:
                                            datasetProp.deviceLocation.name,
                                        icon: Symbols.watch_rounded,
                                      ),
                                      DatasetPropTile(
                                        label: 'Dataset prop version',
                                        content: datasetProp.datasetPropVersion
                                            .nameWithIsLatest(
                                          latestText: ' (latest)',
                                        ),
                                        icon: Symbols.manufacturing_rounded,
                                      ),
                                      DatasetPropTile(
                                        label: 'Dataset version',
                                        content: datasetProp.datasetVersion
                                            .nameWithIsLatest(
                                          latestText: ' (latest)',
                                        ),
                                        icon: Symbols.dataset_rounded,
                                      ),
                                      const Divider(),
                                      DatasetPropTile(
                                        label: 'Duration',
                                        content: _videoPlayerController
                                            .value.duration
                                            .toString(),
                                        icon: Symbols.timer_rounded,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Divider(height: 0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      return IconButton(
                                        tooltip: 'Speed',
                                        visualDensity: VisualDensity.compact,
                                        style: IconButton.styleFrom(
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
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
                                                    (value) => value
                                                        .videoPlaybackSpeed,
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
                                        onPressed: () =>
                                            _showSpeedMenu(context),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 0,
                    color: colorScheme.outline,
                  ),
                  Expanded(
                    child: AccelerometerChart(
                      dataItems: ref.read(preprocessProvider).dataItems,
                      primaryXAxis: _primaryXAxis,
                      zoomPanBehavior: _zoomPanBehavior,
                      trackballBehavior: _trackballBehavior,
                      onTrackballChanged: (trackballArgs) {
                        if (_videoPlayerController.value.isPlaying) return;

                        final index =
                            trackballArgs.chartPointInfo.dataPointIndex ?? 0;
                        final dataItems =
                            ref.read(preprocessProvider).dataItems;

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
            if (shouldVertical)
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
        if (width < 600)
          MenuItemButton(
            leadingIcon: datasetProp.hasEvaluated
                ? const Icon(Symbols.cancel_rounded)
                : const Icon(Symbols.check_circle_rounded),
            onPressed: () =>
                _notifier.setEvaluated(hasEvaluated: !datasetProp.hasEvaluated),
            child: Text(
              datasetProp.hasEvaluated
                  ? 'Mark as not evaluated'
                  : 'Mark as evaluated',
            ),
          ),
        if (width < 800)
          MenuItemButton(
            leadingIcon: const Icon(Symbols.movie_rounded),
            onPressed: datasetProp.isCompressed ? null : _showCompressDialog,
            child: Text(
              datasetProp.isCompressed ? 'Video compressed' : 'Compress video',
            ),
          ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
