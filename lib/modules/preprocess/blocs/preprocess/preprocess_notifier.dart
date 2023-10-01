import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/dataset_info/dataset_info.dart';
import 'package:flutter_sholat_ml/modules/preprocess/repositories/preprocess_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

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

  void onCurrentSelectedIndexChanged({required int index}) {
    state = state.copyWith(currentSelectedIndex: index);
  }

  void onSelectedDatasetChanged(Dataset dataset) {
    final selectedDatasets = state.selectedDatasets;
    if (selectedDatasets.contains(dataset)) {
      state = state.copyWith(
        selectedDatasets: [...selectedDatasets]..remove(dataset),
      );
    } else {
      state = state.copyWith(
        selectedDatasets: [...selectedDatasets, dataset],
      );
    }
  }

  void clearSelectedDatasets() {
    state = state.copyWith(selectedDatasets: []);
  }

  void onTaggedDatasets(
    String labelCategory,
    String label,
  ) {
    state = state.copyWith(
      datasets: state.datasets.map((dataset) {
        if (state.selectedDatasets.contains(dataset)) {
          return dataset.copyWith(
            labelCategory: labelCategory,
            label: label,
          );
        }
        return dataset;
      }).toList(),
    );
    clearSelectedDatasets();
  }

  Future<bool> readDatasets() async {
    final (datasetsFailure, datasets) =
        await _preprocessRepository.readDatasets(state.path);
    if (datasetsFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetsFailure),
      );
      return false;
    }

    final (datasetInfoFailure, datasetInfo) =
        await _preprocessRepository.readDatasetInfo(state.path);
    if (datasetInfoFailure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailureState(datasetInfoFailure),
      );
      return false;
    }

    state = state.copyWith(
      datasets: datasets,
      datasetInfo: datasetInfo,
    );
    return true;
  }

  Future<void> onSaveDataset() async {
    state = state.copyWith(presentationState: const SaveDatasetLoadingState());

    final (failure, newPath, datasetInfo) =
        await _preprocessRepository.saveDataset(
      state.path,
      state.datasets,
      isUpdating: state.datasetInfo != null,
    );

    if (failure != null) {
      state = state.copyWith(
        presentationState: SaveDatasetFailureState(failure),
      );
      return;
    }

    state = state.copyWith(
      path: newPath,
      datasetInfo: datasetInfo,
      presentationState: const SaveDatasetSuccessState(),
    );
  }
}
