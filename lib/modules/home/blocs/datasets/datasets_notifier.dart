import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset_thumbnail/dataset_thumbnail.dart';
import 'package:flutter_sholat_ml/modules/home/repositories/home_repository.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/dataset_prop/dataset_prop.dart';
import 'package:flutter_sholat_ml/modules/preprocess/repositories/preprocess_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

part 'datasets_state.dart';

final datasetsProvider =
    StateNotifierProvider.autoDispose<DatasetsNotifier, HomeState>(
  (ref) => DatasetsNotifier(),
);

class DatasetsNotifier extends StateNotifier<HomeState> {
  DatasetsNotifier()
      : _homeRepository = HomeRepository(),
        _preprocessRepository = PreprocessRepository(),
        super(HomeState.initial());

  final HomeRepository _homeRepository;
  final PreprocessRepository _preprocessRepository;

  Future<void> loadDatasetsFromDisk(String dir) async {
    if (![Directories.needReviewDir, Directories.reviewedDir].contains(dir)) {
      return;
    }

    state = state.copyWith(isLoading: true);

    final (failure, savedPaths) =
        await _homeRepository.loadDatasetsFromDisk(dir);
    if (failure != null) {
      state = state.copyWith(
        isLoading: false,
        presentationState: LoadDatasetsFailureState(failure),
      );
      return;
    }

    if (dir == Directories.needReviewDir) {
      state = state.copyWith(
        needReviewDatasetPaths: savedPaths,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        reviewedDatasetPaths: savedPaths,
        isLoading: false,
      );
    }
  }

  Future<void> getDatasetPropAndThumbnail(String path) async {
    final (_, datasetProp) = await _homeRepository.getDatasetProp(path);

    final (thumbnailFailure, thumbnailPath) =
        await _homeRepository.getDatasetThumbnail(path);

    if (thumbnailFailure == null) {
      state = state.copyWith(
        datasetProps:
            datasetProp != null ? [...state.datasetProps, datasetProp] : null,
        datasetThumbnails: [
          ...state.datasetThumbnails,
          DatasetThumbnail(
            dirName: path.split('/').last,
            thumbnailPath: thumbnailPath,
            error: null,
          ),
        ],
      );
    } else {
      state = state.copyWith(
        datasetProps:
            datasetProp != null ? [...state.datasetProps, datasetProp] : null,
        datasetThumbnails: [
          ...state.datasetThumbnails,
          DatasetThumbnail(
            dirName: path.split('/').last,
            thumbnailPath: null,
            error: thumbnailFailure.message,
          ),
        ],
      );
    }
  }

  void onSelectedDataset(String path) {
    final selectedPaths = state.selectedDatasetPaths;
    if (selectedPaths.contains(path)) {
      state = state.copyWith(
        selectedDatasetPaths: [...selectedPaths]..remove(path),
      );
      return;
    }
    state = state.copyWith(
      selectedDatasetPaths: [...selectedPaths, path],
    );
  }

  void onSelectAllDatasets() {
    state = state.copyWith(selectedDatasetPaths: state.needReviewDatasetPaths);
  }

  void clearSelections() {
    state = state.copyWith(selectedDatasetPaths: []);
  }

  Future<void> deleteSelectedDatasets() async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());
    for (final path in state.selectedDatasetPaths) {
      final (failure, _) = await _homeRepository.deleteDataset(path);
      if (failure != null) {
        state = state.copyWith(
          presentationState: DeleteDatasetFailureState(failure),
        );
        return;
      }
    }
    state =
        state.copyWith(presentationState: const DeleteDatasetSuccessState());
    clearSelections();
  }

  Future<bool> deleteDataset(String path) async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());

    final (failure, _) = await _homeRepository.deleteDataset(path);
    if (failure != null) {
      state = state.copyWith(
        isLoading: false,
        presentationState: DeleteDatasetFailureState(failure),
      );
      return false;
    }
    state = state.copyWith(
      presentationState: const DeleteDatasetSuccessState(),
    );
    return true;
  }

  Future<bool> deleteDatasetFromCloud(String path) async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());

    final (failure, _) = await _preprocessRepository
        .deleteDatasetFromCloud(path.split('/').last);
    if (failure != null) {
      state = state.copyWith(
        presentationState: DeleteDatasetFailureState(failure),
      );
      return false;
    }
    await deleteDataset(path);
    return true;
  }
}
