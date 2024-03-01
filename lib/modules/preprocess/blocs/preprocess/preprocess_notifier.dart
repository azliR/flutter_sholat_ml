import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/enums/sholat_noise_movement.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/modules/preprocess/repositories/preprocess_repository.dart';
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

  @override
  PreprocessState build() {
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
    await analyseDataset();
  }

  Future<void> analyseDataset() async {
    state = state.copyWith(
      presentationState: const AnalyseDatasetLoadingState(),
    );

    final (failure, problems) =
        await _preprocessRepository.analyseDataset(state.dataItems);
    if (failure != null) {
      state = state.copyWith(
        presentationState: AnalyseDatasetFailureState(failure),
      );
      return;
    }

    state = state.copyWith(
      problems: problems,
      presentationState: const AnalyseDatasetSuccessState(),
    );
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

    final (datasetsFailure, datasets) =
        await _preprocessRepository.readDataItems(state.path);
    if (datasetsFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetsFailure),
      );
      return;
    }

    state = state.copyWith(
      dataItems: datasets,
      datasetProp: datasetProp,
    );
  }

  void setIsAutosave({required bool isAutosave}) {
    _preprocessRepository.setAutoSave(enable: isAutosave);
    state = state.copyWith(isAutosave: isAutosave);
  }

  void setIsPlaying({required bool isPlaying}) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  void setVideoPlaybackSpeed(double playbackSpeed) {
    state = state.copyWith(videoPlaybackSpeed: playbackSpeed);
  }

  void setCurrentHighlightedIndex(int index) {
    if (index < 0 || index >= state.dataItems.length) return;

    state = state.copyWith(currentHighlightedIndex: index);
  }

  void setSelectedDataset(int index) {
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
