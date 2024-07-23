import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/enums/sholat_noise_movement.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/dataset/dataset_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

part 'preprocess_state.dart';

final preprocessProvider =
    NotifierProvider.autoDispose<PreprocessNotifier, PreprocessState>(
  PreprocessNotifier.new,
);

class PreprocessNotifier extends AutoDisposeNotifier<PreprocessState> {
  PreprocessNotifier() : _preprocessRepository = PreprocessRepository();

  final PreprocessRepository _preprocessRepository;

  StreamSubscription<TaskSnapshot>? _downloadSubscription;

  @override
  PreprocessState build() {
    ref.onDispose(() {
      _downloadSubscription?.cancel();
    });

    return PreprocessState.initial();
  }

  Future<void> initialise(String path) async {
    final isAutoSave = _preprocessRepository.getAutoSave();
    final isFollowHighlighted = _preprocessRepository.getFollowHighlighted();
    final isShowBottomPanel = _preprocessRepository.getShowBottomPanel();

    state = state.copyWith(
      path: path,
      isAutosave: isAutoSave,
      isFollowHighlightedMode: isFollowHighlighted,
      showBottomPanel: isShowBottomPanel,
    );
    await readDataItems();
  }

  void setDatasetProp(DatasetProp datasetProp) {
    state = state.copyWith(datasetProp: datasetProp);
  }

  void setShowBottomPanel({required bool enable}) {
    _preprocessRepository.setShowBottomPanel(isShowBottomPanel: enable);
    state = state.copyWith(showBottomPanel: enable);
  }

  Future<void> readDataItems() async {
    final (datasetPropFailure, datasetProp) =
        await _preprocessRepository.readDatasetProp(state.path);
    if (datasetPropFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetPropFailure),
      );
      return;
    }
    state = state.copyWith(
      datasetProp: datasetProp,
    );

    final (datasetsFailure, datasets) =
        await _preprocessRepository.readDataItems(
      path: state.path,
      csvUrl: datasetProp?.csvUrl,
    );
    if (datasetsFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetsFailure),
      );
      return;
    }

    state = state.copyWith(
      dataItems: datasets,
    );
  }

  Future<void> downloadDataset() async {
    state = state.copyWith(
      presentationState: const DownloadVideoProgressState(),
    );

    final (failure, stream) =
        await _preprocessRepository.downloadVideoDataset(state.datasetProp!);
    if (failure != null) {
      state = state.copyWith(
        presentationState: DownloadVideoFailureState(failure),
      );
      return;
    }

    double? lastCsvProgress;
    double? lastVideoProgress;

    await _downloadSubscription?.cancel();
    _downloadSubscription = stream!.listen(
      (taskSnapshot) {
        final fileName = taskSnapshot.ref.name;
        if (fileName == Paths.datasetCsv && lastCsvProgress == null) {
          lastCsvProgress = 0;
        } else if (fileName == Paths.datasetVideo &&
            lastVideoProgress == null) {
          lastVideoProgress = 0;
        }

        switch (taskSnapshot.state) {
          case TaskState.success:
            if (fileName == Paths.datasetCsv) {
              lastCsvProgress = 1;
            } else if (fileName == Paths.datasetVideo) {
              lastVideoProgress = 1;
            }
          case TaskState.canceled:
            break;
          case TaskState.error:
            state = state.copyWith(
              presentationState: const DownloadVideoFailureState(),
            );
          case TaskState.paused:
            break;
          case TaskState.running:
            final double progress;
            if (taskSnapshot.totalBytes > 0 &&
                taskSnapshot.bytesTransferred > 0) {
              progress = taskSnapshot.bytesTransferred /
                  (taskSnapshot.metadata?.size ?? taskSnapshot.totalBytes);
            } else {
              progress = 0;
            }

            if (fileName == Paths.datasetCsv) {
              lastCsvProgress = progress;
            } else if (fileName == Paths.datasetVideo) {
              lastVideoProgress = progress;
            }
        }

        state = state.copyWith(
          presentationState: DownloadVideoProgressState(
            csvProgress: lastCsvProgress,
            videoProgress: lastVideoProgress,
          ),
        );

        final isTrueWhenBoth =
            (lastCsvProgress != null && lastVideoProgress != null) &&
                (lastCsvProgress == 1 && lastVideoProgress == 1);
        final isTrueWhenCsv = lastCsvProgress != null && lastCsvProgress == 1;
        final isTrueWhenVideo =
            lastVideoProgress != null && lastVideoProgress == 1;

        if (isTrueWhenBoth || isTrueWhenCsv || isTrueWhenVideo) {
          _downloadSubscription?.cancel();
          state = state.copyWith(
            presentationState: const DownloadVideoSuccessState(),
          );
        }
      },
      cancelOnError: true,
      onDone: () {
        _downloadSubscription?.cancel();
      },
      onError: (e, stackTrace) {
        if (e is FirebaseException) {
          if (e.code == 'canceled') {
            return;
          }
        }
        state = state.copyWith(
          presentationState: const DownloadVideoFailureState(),
        );
      },
    );
  }

  Future<void> cancelDownloadVideo() async {
    final (failure, _) =
        await _preprocessRepository.cancelDownloadVideoDataset(state.path);
    if (failure != null) {
      state = state.copyWith(
        presentationState: CancelDownloadVideoFailureState(failure),
      );
      return;
    }

    state = state.copyWith(
      presentationState: const CancelDownloadVideoSuccessState(),
    );
  }

  void setIsAutosave({required bool isAutosave}) {
    _preprocessRepository.setAutoSave(enable: isAutosave);
    state = state.copyWith(isAutosave: isAutosave);
  }

  void setIsPlaying({required bool isPlaying}) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  void setCurrentHighlightedIndex(int index) {
    if (index < 0 || index >= state.dataItems.length) return;

    state = state.copyWith(currentHighlightedIndex: index);
  }

  void setSelectedDataset(int index) {
    print('pressing $index');
    final enablePredictedPreview = ref.read(enablePredictedPreviewProvider);
    if (enablePredictedPreview) return;

    final selectedDataItemIndexes = state.selectedDataItemIndexes;
    if (selectedDataItemIndexes.contains(index)) {
      state = state.copyWith(
        lastSelectedIndex: () => index,
        selectedDataItemIndexes: {...selectedDataItemIndexes}..remove(index),
      );
    } else {
      state = state.copyWith(
        lastSelectedIndex: () => index,
        selectedDataItemIndexes: {...selectedDataItemIndexes, index},
      );
    }
  }

  void clearSelectedDataItems() {
    state =
        state.copyWith(selectedDataItemIndexes: {}, isJumpSelectMode: false);
  }

  void setJumpSelectMode({required bool enable}) {
    state = state.copyWith(isJumpSelectMode: enable);
  }

  void setFollowHighlightedMode({required bool enable}) {
    _preprocessRepository.setFollowHighlighted(enable: enable);
    state = state.copyWith(isFollowHighlightedMode: enable);
  }

  Future<void> jumpSelect(int endIndex, [int? startIndex]) async {
    final startJumpIndex = startIndex ??
        (state.lastSelectedIndex == null ||
                state.selectedDataItemIndexes.isEmpty
            ? state.currentHighlightedIndex
            : state.lastSelectedIndex);
    if (startJumpIndex == null) return;

    final selectedDataItemIndexes = List.generate(
      1 +
          max<int>(startJumpIndex, endIndex) -
          min<int>(startJumpIndex, endIndex),
      (index) => min(startJumpIndex, endIndex) + index,
    );

    state = state.copyWith(
      selectedDataItemIndexes: {
        ...state.selectedDataItemIndexes,
        ...selectedDataItemIndexes,
      },
      lastSelectedIndex: () => endIndex,
      isJumpSelectMode: false,
    );
  }

  Future<void> jumpRemove(int startIndex, int endIndex) async {
    final startJumpIndex = startIndex;

    final selectedDataItemIndexes = List.generate(
      1 +
          max<int>(startJumpIndex, endIndex) -
          min<int>(startJumpIndex, endIndex),
      (index) => min(startJumpIndex, endIndex) + index,
    );

    state = state.copyWith(
      selectedDataItemIndexes: state.selectedDataItemIndexes
        ..removeAll(selectedDataItemIndexes),
      lastSelectedIndex: () => null,
      isJumpSelectMode: false,
    );
  }

  String setDataItemLabels(
    SholatMovementCategory labelCategory,
    SholatMovement label, {
    String? movementCategorySetId,
    String? movementSetId,
  }) {
    movementCategorySetId ??= const Uuid().v4();
    movementSetId ??= const Uuid().v4();

    final updatedDataItems = [...state.dataItems];
    for (final index in state.selectedDataItemIndexes) {
      updatedDataItems[index] = updatedDataItems[index].copyWith(
        movementSetId: () => movementSetId,
        labelCategory: () => labelCategory,
        label: () => label,
      );
    }

    state = state.copyWith(
      dataItems: updatedDataItems,
      isEdited: true,
    );
    clearSelectedDataItems();
    return movementSetId;
  }

  // void setBatchDataItemLabels({
  //   required Map<SholatMovementCategory, SholatMovement> labels,
  // }) async {
  //   final updatedDataItems = [...state.dataItems];
  //   for (final (index, entry) in labels.entries.indexed) {
  //     updatedDataItems[index] = updatedDataItems[index].copyWith(
  //       movementSetId: () => const Uuid().v4(),
  //       labelCategory: () => entry.key,
  //       label: () => entry.value,
  //     );
  //   }

  //   state = state.copyWith(
  //     dataItems: updatedDataItems,
  //     isEdited: true,
  //   );
  // }

  void setDataItemNoises(
    SholatNoiseMovement? noiseMovement,
  ) {
    final updatedDataItems = [...state.dataItems];
    for (final index in state.selectedDataItemIndexes) {
      updatedDataItems[index] = updatedDataItems[index].copyWith(
        noiseMovement: () => noiseMovement,
      );
    }

    state = state.copyWith(
      dataItems: updatedDataItems,
      isEdited: true,
    );
    clearSelectedDataItems();
  }

  void removeDataItemLabels({bool includeSameMovementIds = false}) {
    if (includeSameMovementIds) {
      final movementIds = state.selectedDataItemIndexes
          .map((index) => state.dataItems[index].movementSetId)
          .toSet()
          .toList();
      final updatedDataItems = state.dataItems.map((dataset) {
        if (movementIds.contains(dataset.movementSetId)) {
          return dataset.copyWith(
            movementSetId: () => null,
            labelCategory: () => null,
            label: () => null,
          );
        }
        return dataset;
      }).toList();
      state = state.copyWith(
        dataItems: updatedDataItems,
        isEdited: true,
      );
    } else {
      final updatedDataItems = [...state.dataItems];
      for (final index in state.selectedDataItemIndexes) {
        updatedDataItems[index] = updatedDataItems[index].copyWith(
          movementSetId: () => null,
          labelCategory: () => null,
          label: () => null,
        );
      }
      state = state.copyWith(
        dataItems: updatedDataItems,
        isEdited: true,
      );
    }
    clearSelectedDataItems();
  }

  void setEvaluated({required bool hasEvaluated}) {
    state = state.copyWith(
      datasetProp: state.datasetProp!.copyWith(
        hasEvaluated: hasEvaluated,
      ),
      isEdited: true,
    );
  }

  Future<void> compressVideo({bool diskOnly = false}) async {
    state =
        state.copyWith(presentationState: const CompressVideoLoadingState());

    const datasetVideoName = Paths.datasetVideo;
    final (compressFailure, _) = await _preprocessRepository.compressVideo(
      path: join(state.path, datasetVideoName),
    );
    if (compressFailure != null) {
      state = state.copyWith(
        presentationState: CompressVideoFailureState(compressFailure),
      );
      return;
    }

    final datasetProp = state.datasetProp!.copyWith(
      isCompressed: true,
    );

    final (writePropFailure, updatedDatasetProp) =
        await _preprocessRepository.writeDatasetProp(
      datasetPath: state.path,
      datasetProp: datasetProp,
    );
    if (writePropFailure != null) {
      state = state.copyWith(
        presentationState: CompressVideoFailureState(writePropFailure),
      );
      return;
    }

    state = state.copyWith(
      datasetProp: updatedDatasetProp,
      presentationState: const CompressVideoSuccessState(),
    );
  }

  Future<void> saveDataset({
    bool diskOnly = false,
    bool withVideo = true,
    bool isAutoSaving = false,
  }) async {
    state = state.copyWith(
      presentationState: isAutoSaving
          ? const SaveDatasetAutoSavingState()
          : const SaveDatasetLoadingState(),
    );

    final (failure, newPath, datasetProp) =
        await _preprocessRepository.saveDataset(
      path: state.path,
      dataItems: state.dataItems,
      datasetProp: state.datasetProp!,
      diskOnly: diskOnly,
      withVideo: withVideo,
    );

    if (failure != null) {
      state = state.copyWith(
        presentationState: SaveDatasetFailureState(failure),
      );
      return;
    }

    state = state.copyWith(
      path: newPath,
      datasetProp: datasetProp,
      isEdited: false,
      presentationState: SaveDatasetSuccessState(isAutosave: isAutoSaving),
    );
  }
}
