import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartx/dartx_io.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_thumbnail.dart';
import 'package:flutter_sholat_ml/modules/home/repositories/home_repository.dart';
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

  Query<Dataset> get reviewedDatasetsQuery =>
      _homeRepository.reviewedDatasetsQuery;

  Future<void> loadDatasetsFromDisk({bool isReviewedDatasets = false}) async {
    state = state.copyWith(isLoading: true);

    final (failure, datasets) = await _homeRepository.loadDatasetsFromDisk(
      isReviewedDatasets
          ? Directories.reviewedDirPath
          : Directories.needReviewDirPath,
    );
    if (failure != null) {
      state = state.copyWith(
        isLoading: false,
        presentationState: LoadDatasetsFailureState(failure),
      );
      return;
    }

    if (isReviewedDatasets) {
      state = state.copyWith(
        reviewedDatasets: datasets?.map((newDataset) {
          return newDataset.copyWith(
            thumbnail: state.reviewedDatasets.firstOrNullWhere((oldDataset) {
              return oldDataset.path == newDataset.path;
            })?.thumbnail,
          );
        }).toList(),
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        needReviewDatasets: datasets?.map((newDataset) {
          return newDataset.copyWith(
            thumbnail: state.needReviewDatasets.firstOrNullWhere((oldDataset) {
              return oldDataset.path == newDataset.path;
            })?.thumbnail,
          );
        }).toList(),
        isLoading: false,
      );
    }
  }

  Future<String?> loadDatasetFromDisk(Dataset dataset) async {
    final (failure, datasetPath) = await _homeRepository.loadDatasetFromDisk(
      dataset: dataset,
      isReviewedDataset: true,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: LoadDatasetsFailureState(failure),
      );
      return null;
    }

    state = state.copyWith(
      reviewedDatasets: [...state.reviewedDatasets]..addOrUpdate(dataset),
    );
    return datasetPath;
  }

  Future<void> getThumbnail({
    required Dataset dataset,
    required bool isReviewedDatasets,
  }) async {
    if (dataset.path == null) return;

    final (failure, thumbnailPath) = await _homeRepository
        .getDatasetThumbnail(dataset.path!, dataset: dataset);

    final thumbnail = failure == null
        ? DatasetThumbnail(
            dirName: dataset.property.dirName,
            thumbnailPath: thumbnailPath,
            error: null,
          )
        : DatasetThumbnail(
            dirName: dataset.property.dirName,
            thumbnailPath: null,
            error: failure.message,
          );

    final datasets =
        isReviewedDatasets ? state.reviewedDatasets : state.needReviewDatasets;
    final updatedDatasets = datasets.map((oldDataset) {
      if (dataset.property.dirName == oldDataset.property.dirName) {
        return dataset.copyWith(
          thumbnail: thumbnail,
        );
      }
      return oldDataset;
    }).toList();

    state = state.copyWith(
      needReviewDatasets: !isReviewedDatasets ? updatedDatasets : null,
      reviewedDatasets: isReviewedDatasets ? updatedDatasets : null,
    );
  }

  void onSelectedDataset(Dataset dataset) {
    final selectedDatasets = state.selectedDatasets;
    if (selectedDatasets.contains(dataset)) {
      state = state.copyWith(
        selectedDatasets: [...selectedDatasets]..remove(dataset),
      );
      return;
    }
    state = state.copyWith(
      selectedDatasets: [...selectedDatasets, dataset],
    );
  }

  void onSelectAllDatasets() {
    state = state.copyWith(selectedDatasets: state.needReviewDatasets);
  }

  void clearSelections() {
    state = state.copyWith(selectedDatasets: []);
  }

  Future<void> deleteSelectedDatasets() async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());
    for (final dataset in state.selectedDatasets) {
      final (failure, _) = await _homeRepository.deleteDataset(dataset.path!);
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

  Future<bool> deleteDatasetFromCloud(Dataset dataset) async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());

    final (failure, _) = await _preprocessRepository
        .deleteDatasetFromCloud(dataset.property.dirName);
    if (failure != null) {
      state = state.copyWith(
        presentationState: DeleteDatasetFailureState(failure),
      );
      return false;
    }
    if (dataset.path != null) await deleteDataset(dataset.path!);
    return true;
  }
}
