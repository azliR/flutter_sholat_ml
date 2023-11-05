import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
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

  void setSelectedDataset(int index) {
    final datasets = state.dataItems;
    final selectedDatasets = state.selectedDataItems;
    final dataset = datasets[index];
    if (selectedDatasets.contains(dataset)) {
      state = state.copyWith(
        lastSelectedIndex: () => index,
        selectedDataItems: [...selectedDatasets]..remove(dataset),
      );
    } else {
      state = state.copyWith(
        lastSelectedIndex: () => index,
        selectedDataItems: [...selectedDatasets, dataset],
      );
    }
  }

  void clearSelectedDataItems() {
    state = state.copyWith(selectedDataItems: [], isJumpSelectMode: false);
  }

  void setJumpSelectMode({required bool enable}) {
    state = state.copyWith(isJumpSelectMode: enable);
  }

  void setFollowHighlightedMode({required bool enable}) {
    state = state.copyWith(isFollowHighlightedMode: enable);
  }

  Future<void> jumpSelect(int endIndex) async {
    final startJumpIndex = state.selectedDataItems.isEmpty
        ? state.currentHighlightedIndex
        : state.lastSelectedIndex;
    if (startJumpIndex == null) return;

    final selectedDatasets = state.dataItems.sublist(
      min(startJumpIndex, endIndex),
      max(startJumpIndex, endIndex + 1),
    );

    state = state.copyWith(
      selectedDataItems:
          {...state.selectedDataItems, ...selectedDatasets}.toList(),
      lastSelectedIndex: () => endIndex,
      isJumpSelectMode: false,
    );
  }

  String setDataItemLabels(
    SholatMovementCategory labelCategory,
    SholatMovement label,
  ) {
    final movementSetId = const Uuid().v7();
    state = state.copyWith(
      dataItems: state.dataItems.map((dataset) {
        if (state.selectedDataItems.contains(dataset)) {
          return dataset.copyWith(
            movementSetId: () => movementSetId,
            labelCategory: () => labelCategory,
            label: () => label,
          );
        }
        return dataset;
      }).toList(),
    );
    clearSelectedDataItems();
    return movementSetId;
  }

  void removeDataItemLabels({bool includeSameMovementIds = false}) {
    if (includeSameMovementIds) {
      final movementIds = state.selectedDataItems
          .map((dataItem) => dataItem.movementSetId)
          .toSet()
          .toList();
      state = state.copyWith(
        dataItems: state.dataItems.map((dataset) {
          if (movementIds.contains(dataset.movementSetId)) {
            return dataset.copyWith(
              movementSetId: () => null,
              labelCategory: () => null,
              label: () => null,
            );
          }
          return dataset;
        }).toList(),
      );
    } else {
      state = state.copyWith(
        dataItems: state.dataItems.map((dataset) {
          if (state.selectedDataItems.contains(dataset)) {
            return dataset.copyWith(
              movementSetId: () => null,
              labelCategory: () => null,
              label: () => null,
            );
          }
          return dataset;
        }).toList(),
      );
    }
    clearSelectedDataItems();
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
      presentationState: const SaveDatasetSuccessState(),
    );
  }
}
