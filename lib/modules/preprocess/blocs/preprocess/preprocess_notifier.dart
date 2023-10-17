import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/modules/preprocess/repositories/preprocess_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:uuid/uuid.dart';

part 'preprocess_state.dart';

final preprocessProvider =
    StateNotifierProvider.autoDispose<PreprocessNotifier, PreprocessState>(
  (ref) => PreprocessNotifier(),
);

class PreprocessNotifier extends StateNotifier<PreprocessState> {
  PreprocessNotifier()
      : _preprocessRepository = PreprocessRepository(),
        super(PreprocessState.initial());

  final PreprocessRepository _preprocessRepository;

  Future<void> initialise(String path) async {
    state = state.copyWith(path: path);
    await readDatasets();
  }

  void onIsPlayingChanged({required bool isPlaying}) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  void onCurrentHighlightedIndexChanged(int index) {
    state = state.copyWith(currentHighlightedIndex: index);
  }

  void onSelectedDatasetChanged(int index) {
    final datasets = state.datasets;
    final selectedDatasets = state.selectedDatasets;
    final dataset = datasets[index];
    if (selectedDatasets.contains(dataset)) {
      state = state.copyWith(
        lastSelectedIndex: () => index,
        selectedDatasets: [...selectedDatasets]..remove(dataset),
      );
    } else {
      state = state.copyWith(
        lastSelectedIndex: () => index,
        selectedDatasets: [...selectedDatasets, dataset],
      );
    }
  }

  void clearSelectedDatasets() {
    state = state.copyWith(selectedDatasets: [], isJumpSelectMode: false);
  }

  void onJumpSelectModeChanged({required bool enable}) {
    state = state.copyWith(isJumpSelectMode: enable);
  }

  void onFollowHighlightedModeChanged({required bool enable}) {
    state = state.copyWith(isFollowHighlightedMode: enable);
  }

  Future<void> jumpSelect(
    int endIndex, {
    required Future<bool> Function() onShowWarning,
  }) async {
    final lastSelectedIndex = state.lastSelectedIndex;
    if (lastSelectedIndex == null) return;

    final selectedDatasets = state.datasets.sublist(
      min(lastSelectedIndex, endIndex),
      max(lastSelectedIndex, endIndex + 1),
    );

    final showWarning = selectedDatasets.any((dataset) => dataset.isLabeled);
    if (showWarning) {
      final result = await onShowWarning();
      if (!result) return;
    }

    state = state.copyWith(
      selectedDatasets:
          {...state.selectedDatasets, ...selectedDatasets}.toList(),
      lastSelectedIndex: () => endIndex,
      isJumpSelectMode: false,
    );
  }

  String onTaggedDatasets(
    String labelCategory,
    String label,
  ) {
    final movementSetId = const Uuid().v1();
    state = state.copyWith(
      datasets: state.datasets.map((dataset) {
        if (state.selectedDatasets.contains(dataset)) {
          return dataset.copyWith(
            movementSetId: movementSetId,
            labelCategory: labelCategory,
            label: label,
          );
        }
        return dataset;
      }).toList(),
    );
    clearSelectedDatasets();
    return movementSetId;
  }

  Future<bool> readDatasets() async {
    final (datasetPropFailure, datasetProp) =
        await _preprocessRepository.readDatasetProp(state.path);
    if (datasetPropFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetPropFailure),
      );
      return false;
    }

    final (datasetsFailure, datasets) =
        await _preprocessRepository.readDatasets(state.path);
    if (datasetsFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetsFailure),
      );
      return false;
    }

    state = state.copyWith(
      datasets: datasets,
      datasetProp: datasetProp,
    );
    return true;
  }

  Future<void> onSaveDataset() async {
    state = state.copyWith(presentationState: const SaveDatasetLoadingState());

    final (failure, newPath, datasetProp) =
        await _preprocessRepository.saveDataset(
      state.path,
      state.datasets,
      isUpdating: state.datasetProp!.isSubmitted,
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
      presentationState: const SaveDatasetSuccessState(),
    );
  }
}
