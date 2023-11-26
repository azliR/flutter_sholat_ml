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
    state = state.copyWith(path: path);
    await readDataItems();
  }

  Future<bool> readDataItems() async {
    final (datasetPropFailure, datasetProp) =
        await _preprocessRepository.readDatasetProp(state.path);
    if (datasetPropFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetPropFailure),
      );
      return false;
    }

    final (datasetsFailure, datasets) =
        await _preprocessRepository.readDataItems(state.path);
    if (datasetsFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetsFailure),
      );
      return false;
    }

    state = state.copyWith(
      dataItems: datasets,
      datasetProp: datasetProp,
    );
    return true;
  }

  void setIsPlaying({required bool isPlaying}) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  void setCurrentHighlightedIndex(int index) {
    state = state.copyWith(currentHighlightedIndex: index);
  }

  void setVideoPlaybackSpeed(double playbackSpeed) {
    state = state.copyWith(videoPlaybackSpeed: playbackSpeed);
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
    state = state.copyWith(isFollowHighlightedMode: enable);
  }

  Future<void> jumpSelect(int endIndex) async {
    final startJumpIndex = state.selectedDataItemIndexes.isEmpty
        ? state.currentHighlightedIndex
        : state.lastSelectedIndex;
    if (startJumpIndex == null) return;

    // final selectedDataItems = state.dataItems.sublist(
    //   min(startJumpIndex, endIndex),
    //   max(startJumpIndex, endIndex + 1),
    // );

    final selectedDataItemIndexes = List.generate(
      (max(startJumpIndex, endIndex + 1) - min(startJumpIndex, endIndex) + 1)
          .toInt(),
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
      isSyncedWithCloud: false,
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

    _preprocessRepository.saveDatasetToLocal(updatedDatasetProp!);

    state = state.copyWith(
      datasetProp: updatedDatasetProp,
      presentationState: const CompressVideoSuccessState(),
    );
  }

  Future<void> saveDataset({bool diskOnly = false}) async {
    state = state.copyWith(presentationState: const SaveDatasetLoadingState());

    final (failure, newPath, datasetProp) =
        await _preprocessRepository.saveDataset(
      path: state.path,
      dataItems: state.dataItems,
      datasetProp: state.datasetProp!,
      diskOnly: diskOnly,
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
      presentationState: const SaveDatasetSuccessState(),
    );
  }
}
