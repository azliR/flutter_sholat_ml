import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/data_item/data_item_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/video_player/video_player_provider.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:video_player/video_player.dart';

class PreprocessShortcuts extends ConsumerStatefulWidget {
  const PreprocessShortcuts({
    required this.scrollController,
    required this.videoPlayerController,
    required this.onRightKeyPressed,
    required this.onLeftKeyPressed,
    required this.child,
    super.key,
  });

  final ScrollController scrollController;
  final VideoPlayerController? videoPlayerController;
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool isControlPressed) onRightKeyPressed;
  // ignore: avoid_positional_boolean_parameters
  final void Function(bool isControlPressed) onLeftKeyPressed;
  final Widget child;

  @override
  ConsumerState<PreprocessShortcuts> createState() =>
      _PreprocessShortcutsState();
}

class _PreprocessShortcutsState extends ConsumerState<PreprocessShortcuts> {
  late final PreprocessNotifier _notifier;

  Map<ShortcutActivator, VoidCallback> get _bindings =>
      <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): _playVideo,
        const SingleActivator(LogicalKeyboardKey.escape): _clearSelection,
        const SingleActivator(LogicalKeyboardKey.keyX): _increasePlaybackSpeed,
        const SingleActivator(LogicalKeyboardKey.keyZ): _decreasePlaybackSpeed,
        const SingleActivator(LogicalKeyboardKey.arrowUp): _moveHighlightUp,
        const SingleActivator(LogicalKeyboardKey.arrowDown): _moveHighlightDown,
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            widget.onRightKeyPressed(false),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            widget.onLeftKeyPressed(false),
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): () =>
            _moveHighlightUp(isControlPressed: true),
        const SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
            () => _moveHighlightDown(isControlPressed: true),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
            () => widget.onRightKeyPressed(true),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
            () => widget.onLeftKeyPressed(true),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
            _moveHighlightUp(isShiftPressed: true),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
            _moveHighlightDown(isShiftPressed: true),
        const SingleActivator(
          LogicalKeyboardKey.arrowUp,
          control: true,
          shift: true,
        ): () => _moveHighlightUp(isControlPressed: true, isShiftPressed: true),
        const SingleActivator(
          LogicalKeyboardKey.arrowDown,
          control: true,
          shift: true,
        ): () =>
            _moveHighlightDown(isControlPressed: true, isShiftPressed: true),
        const SingleActivator(LogicalKeyboardKey.backquote, control: true):
            _showBottomPanel,
      };

  void _playVideo() {
    if (widget.videoPlayerController == null) {
      showSnackbar(context, 'Video is not ready');
      return;
    }

    final videoValue = widget.videoPlayerController!.value;
    final isInitialized = videoValue.isInitialized;
    final isPlaying = videoValue.isPlaying;

    if (!isInitialized) {
      showSnackbar(context, 'Video is not ready');
      return;
    }

    if (isPlaying) {
      widget.videoPlayerController!.pause();
    } else {
      widget.videoPlayerController!.play();
    }
    _notifier.setIsPlaying(isPlaying: !isPlaying);
  }

  void _clearSelection() {
    final isSelectMode =
        ref.read(preprocessProvider).selectedDataItemIndexes.isNotEmpty;
    if (isSelectMode) {
      _notifier.clearSelectedDataItems();
    }
  }

  void _increasePlaybackSpeed() {
    if (widget.videoPlayerController == null) {
      showSnackbar(context, 'Video is not ready');
      return;
    }

    final currentPlaybackSpeed = ref.read(videoPlaybackSpeedProvider);
    final updatedPlaybackSpeed = min<double>(currentPlaybackSpeed + 0.1, 5);
    ref
        .read(videoPlaybackSpeedProvider.notifier)
        .setSpeed(updatedPlaybackSpeed);
    widget.videoPlayerController!.setPlaybackSpeed(updatedPlaybackSpeed);
  }

  void _decreasePlaybackSpeed() {
    if (widget.videoPlayerController == null) {
      showSnackbar(context, 'Video is not ready');
      return;
    }

    final currentPlaybackSpeed = ref.read(videoPlaybackSpeedProvider);
    final updatedPlaybackSpeed = max<double>(currentPlaybackSpeed - 0.1, 0.1);
    ref
        .read(videoPlaybackSpeedProvider.notifier)
        .setSpeed(updatedPlaybackSpeed);
    widget.videoPlayerController!.setPlaybackSpeed(updatedPlaybackSpeed);
  }

  void _moveHighlightUp({
    bool isControlPressed = false,
    bool isShiftPressed = false,
  }) {
    final selectedDataItemIndexes =
        ref.read(preprocessProvider).selectedDataItemIndexes;
    final currentHighlightedIndex =
        ref.read(preprocessProvider).currentHighlightedIndex;
    final updatedHighlightedIndex = max(
      currentHighlightedIndex - (isControlPressed ? 10 : 1),
      0,
    );

    if (isShiftPressed) {
      if (!selectedDataItemIndexes.contains(currentHighlightedIndex)) {
        _notifier.setSelectedDataset(currentHighlightedIndex);
      }
      if (isControlPressed) {
        final startIndex =
            min(currentHighlightedIndex, updatedHighlightedIndex);
        final endIndex = max(currentHighlightedIndex, updatedHighlightedIndex);
        final updatedDataItemIndexes = List.generate(
          endIndex - startIndex + 1,
          (index) => startIndex + index,
        );

        if (selectedDataItemIndexes.containsAll(updatedDataItemIndexes)) {
          _notifier.jumpRemove(
            currentHighlightedIndex,
            updatedHighlightedIndex + 1,
          );
        } else {
          _notifier.jumpSelect(
            updatedHighlightedIndex,
            currentHighlightedIndex,
          );
        }
      } else {
        if (selectedDataItemIndexes.contains(updatedHighlightedIndex)) {
          _notifier.setSelectedDataset(currentHighlightedIndex);
        } else {
          _notifier.setSelectedDataset(updatedHighlightedIndex);
        }
      }
    }
    _notifier.setCurrentHighlightedIndex(updatedHighlightedIndex);

    final currentPosition = widget.scrollController.position;
    final maxTopOffset = currentPosition.extentBefore;

    const dataItemTileHeight = 32;
    const sectionTileHeight = 48;

    final sections = ref.read(generateDataItemSectionProvider).requireValue;
    final sectionIndex = sections.lastIndexWhere(
      (section) => section.startIndex <= updatedHighlightedIndex,
    );

    final currentOffset = sections
        .take(sectionIndex + 1)
        .indexed
        .fold<double>(0, (previousValue, element) {
      final (foldIndex, section) = element;

      if (foldIndex == sectionIndex) {
        if (!section.expanded) {
          ref
              .read(generateDataItemSectionProvider.notifier)
              .toggleSectionAt(sectionIndex);
        }
        ref
            .read(selectedSectionIndexProvider.notifier)
            .setSectionIndex(sectionIndex);

        return previousValue +
            sectionTileHeight +
            ((updatedHighlightedIndex - section.startIndex) *
                dataItemTileHeight);
      } else if (section.expanded) {
        return previousValue +
            sectionTileHeight +
            (section.dataItems.length * dataItemTileHeight);
      }
      return previousValue + sectionTileHeight;
    });

    if (currentOffset <= maxTopOffset) {
      widget.scrollController.jumpTo(currentOffset);
    }
  }

  void _moveHighlightDown({
    bool isControlPressed = false,
    bool isShiftPressed = false,
  }) {
    final dataItemsLength = ref.read(preprocessProvider).dataItems.length;
    final selectedDataItemIndexes =
        ref.read(preprocessProvider).selectedDataItemIndexes;
    final currentHighlightedIndex =
        ref.read(preprocessProvider).currentHighlightedIndex;
    final updatedHighlightedIndex = min(
      currentHighlightedIndex + (isControlPressed ? 10 : 1),
      dataItemsLength - 1,
    );

    if (isShiftPressed) {
      if (!selectedDataItemIndexes.contains(currentHighlightedIndex)) {
        _notifier.setSelectedDataset(currentHighlightedIndex);
      }
      if (isControlPressed) {
        final startIndex =
            min(currentHighlightedIndex, updatedHighlightedIndex);
        final endIndex = max(currentHighlightedIndex, updatedHighlightedIndex);
        final updatedDataItemIndexes = List.generate(
          endIndex - startIndex + 1,
          (index) => startIndex + index,
        );

        if (selectedDataItemIndexes.containsAll(updatedDataItemIndexes)) {
          _notifier.jumpRemove(
            currentHighlightedIndex,
            updatedHighlightedIndex + 1,
          );
        } else {
          _notifier.jumpSelect(
            currentHighlightedIndex,
            updatedHighlightedIndex,
          );
        }
      } else {
        if (selectedDataItemIndexes.contains(updatedHighlightedIndex)) {
          _notifier.setSelectedDataset(currentHighlightedIndex);
        } else {
          _notifier.setSelectedDataset(updatedHighlightedIndex);
        }
      }
    }
    _notifier.setCurrentHighlightedIndex(updatedHighlightedIndex);

    final currentPosition = widget.scrollController.position;
    final maxTopOffset = currentPosition.extentBefore;
    final maxBottomOffset = maxTopOffset + currentPosition.extentInside;
    const dataItemTileHeight = 32;
    const sectionTileHeight = 48;

    final sections = ref.read(generateDataItemSectionProvider).requireValue;
    final sectionIndex = sections.lastIndexWhere(
      (section) => section.startIndex <= updatedHighlightedIndex,
    );

    final currentOffset = sections
        .take(sectionIndex + 1)
        .indexed
        .fold<double>(0, (previousValue, element) {
      final (foldIndex, section) = element;

      if (foldIndex == sectionIndex) {
        if (!section.expanded) {
          ref
              .read(generateDataItemSectionProvider.notifier)
              .toggleSectionAt(sectionIndex);
        }
        ref
            .read(selectedSectionIndexProvider.notifier)
            .setSectionIndex(sectionIndex);

        return previousValue +
            sectionTileHeight +
            ((updatedHighlightedIndex - section.startIndex) *
                dataItemTileHeight);
      } else if (section.expanded) {
        return previousValue +
            sectionTileHeight +
            (section.dataItems.length * dataItemTileHeight);
      }
      return previousValue + sectionTileHeight;
    });

    if (currentOffset >= maxBottomOffset) {
      widget.scrollController.jumpTo(
        currentOffset - maxBottomOffset + maxTopOffset + 32.0,
      );
    }
  }

  void _showBottomPanel() {
    final isShowBottomPanel = ref.read(preprocessProvider).showBottomPanel;
    _notifier.setShowBottomPanel(enable: !isShowBottomPanel);
  }

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: _bindings,
      child: Focus(
        autofocus: true,
        onKey: (node, event) {
          _notifier.setJumpSelectMode(enable: event.isShiftPressed);
          return KeyEventResult.ignored;
        },
        child: widget.child,
      ),
    );
  }
}
