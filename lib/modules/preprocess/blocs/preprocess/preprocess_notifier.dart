import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/preprocess/preprocess.dart';
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
    final preprocessSuccess = await getPreprocessPath(path);
    if (!preprocessSuccess) return;
    await readDatasets(state.preprocess!.csvPath);
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

  Future<bool> getPreprocessPath(String path) async {
    final (failure, paths) = await _preprocessRepository.getPreprocess(path);
    if (failure != null) {
      state = state.copyWith(
        presentationState: GetPreprocessFailure(failure),
      );
      return false;
    }

    state = state.copyWith(preprocess: paths);
    return true;
  }

  Future<bool> readDatasets(String path) async {
    final (failure, datasets) = await _preprocessRepository.readDatasets(path);
    if (failure != null) {
      state = state.copyWith(
        presentationState: ReadDatasetsFailure(failure),
      );
      return false;
    }

    state = state.copyWith(datasets: datasets);
    return true;
  }
}
