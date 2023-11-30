import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/data_item_tile_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:video_player/video_player.dart';

class PreprocessDatasetList extends ConsumerStatefulWidget {
  const PreprocessDatasetList({
    required this.scrollController,
    required this.videoPlayerController,
    required this.trackballBehavior,
    required this.onDataItemPressed,
    super.key,
  });

  final ScrollController scrollController;
  final VideoPlayerController videoPlayerController;
  final TrackballBehavior trackballBehavior;
  final void Function(int index) onDataItemPressed;

  @override
  ConsumerState<PreprocessDatasetList> createState() =>
      _PreprocessDatasetListState();
}

class _PreprocessDatasetListState extends ConsumerState<PreprocessDatasetList> {
  late final PreprocessNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dataItems =
        ref.watch(preprocessProvider.select((state) => state.dataItems));
    // final (_, indexes, groupedDataItems) =
    //     dataItems.fold((0, <int>[], <DataItem>[]), (previousValue, element) {
    //   final index = previousValue.$1;
    //   final indexes = previousValue.$2;
    //   final dataItems = previousValue.$3;
    //   if (element.isLabeled &&
    //       dataItems
    //           .any((value) => value.movementSetId == element.movementSetId)) {
    //     return (index + 1, indexes, dataItems);
    //   }
    //   return (index + 1, indexes..add(index), dataItems..add(element));
    // });

    return Focus(
      autofocus: true,
      onKey: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (event.isKeyPressed(LogicalKeyboardKey.space)) {
            final isPlaying = ref.read(preprocessProvider).isPlaying;
            if (isPlaying) {
              widget.videoPlayerController.pause();
            } else {
              widget.videoPlayerController.play();
            }
            _notifier.setIsPlaying(isPlaying: !isPlaying);
          }
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
            final isSelectMode =
                ref.read(preprocessProvider).selectedDataItemIndexes.isNotEmpty;
            if (isSelectMode) {
              _notifier.clearSelectedDataItems();
            } else {
              Navigator.pop(context);
            }
          }
        } else if (event.logicalKey == LogicalKeyboardKey.keyZ) {
          if (event.isKeyPressed(LogicalKeyboardKey.keyZ)) {
            final currentPlaybackSpeed =
                ref.read(preprocessProvider).videoPlaybackSpeed;
            final updatedPlaybackSpeed = max(currentPlaybackSpeed - 0.1, 0.1);
            _notifier.setVideoPlaybackSpeed(updatedPlaybackSpeed);
            widget.videoPlayerController.setPlaybackSpeed(updatedPlaybackSpeed);
          }
        } else if (event.logicalKey == LogicalKeyboardKey.keyX) {
          if (event.isKeyPressed(LogicalKeyboardKey.keyX)) {
            final currentPlaybackSpeed =
                ref.read(preprocessProvider).videoPlaybackSpeed;
            final updatedPlaybackSpeed =
                min<double>(currentPlaybackSpeed + 0.1, 5);
            _notifier.setVideoPlaybackSpeed(updatedPlaybackSpeed);
            widget.videoPlayerController.setPlaybackSpeed(updatedPlaybackSpeed);
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
            final selectedDataItemIndexes =
                ref.read(preprocessProvider).selectedDataItemIndexes;
            final currentHighlightedIndex =
                ref.read(preprocessProvider).currentHighlightedIndex;
            final updatedHighlightedIndex = max(currentHighlightedIndex - 1, 0);

            if (event.isShiftPressed) {
              if (selectedDataItemIndexes.isEmpty) {
                _notifier.setSelectedDataset(currentHighlightedIndex);
              }
              if (selectedDataItemIndexes.contains(updatedHighlightedIndex)) {
                _notifier.setSelectedDataset(currentHighlightedIndex);
              } else {
                _notifier.setSelectedDataset(updatedHighlightedIndex);
              }
            }
            _notifier.setCurrentHighlightedIndex(updatedHighlightedIndex);

            final currentPosition = widget.scrollController.position;
            final maxTopOffset = currentPosition.extentBefore;
            final currentOffset = updatedHighlightedIndex * 32.0;
            if (currentOffset <= maxTopOffset) {
              widget.scrollController.jumpTo(currentOffset);
            }
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
            final dataItemsLength = dataItems.length;
            final selectedDataItemIndexes =
                ref.read(preprocessProvider).selectedDataItemIndexes;
            final currentHighlightedIndex =
                ref.read(preprocessProvider).currentHighlightedIndex;
            final updatedHighlightedIndex =
                min(currentHighlightedIndex + 1, dataItemsLength);

            if (event.isShiftPressed) {
              if (selectedDataItemIndexes.isEmpty) {
                _notifier.setSelectedDataset(currentHighlightedIndex);
              }
              if (selectedDataItemIndexes.contains(updatedHighlightedIndex)) {
                _notifier.setSelectedDataset(currentHighlightedIndex);
              } else {
                _notifier.setSelectedDataset(updatedHighlightedIndex);
              }
            }
            _notifier.setCurrentHighlightedIndex(updatedHighlightedIndex);

            final currentPosition = widget.scrollController.position;
            final maxTopOffset = currentPosition.extentBefore;
            final maxBottomOffset = maxTopOffset + currentPosition.extentInside;
            final currentOffset = updatedHighlightedIndex * 32.0;
            if (currentOffset >= maxBottomOffset) {
              widget.scrollController.jumpTo(
                currentOffset - maxBottomOffset + maxTopOffset + 32.0,
              );
            }
          }
        }
        _notifier.setJumpSelectMode(enable: event.isShiftPressed);
        return KeyEventResult.handled;
      },
      child: Scrollbar(
        child: ListView.builder(
          controller: widget.scrollController,
          cacheExtent: 32,
          itemExtent: 32,
          itemCount: dataItems.length,
          itemBuilder: (context, index) {
            return Consumer(
              builder: (context, ref, child) {
                final currentHighlightedIndex = ref.watch(
                  preprocessProvider
                      .select((value) => value.currentHighlightedIndex),
                );
                final selectedDataItemIndexes = ref.watch(
                  preprocessProvider
                      .select((state) => state.selectedDataItemIndexes),
                );

                final dataItem = dataItems[index];
                final selected = selectedDataItemIndexes.contains(index);

                return DataItemTile(
                  index: index,
                  dataItem: dataItem,
                  highlighted: index == currentHighlightedIndex,
                  selected: selected,
                  onTap: () => widget.onDataItemPressed(index),
                  onLongPress: () async {
                    _notifier
                      ..setSelectedDataset(index)
                      ..setCurrentHighlightedIndex(index);
                    widget.trackballBehavior.showByIndex(index);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
