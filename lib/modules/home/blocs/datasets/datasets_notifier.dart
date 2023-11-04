import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  StreamSubscription<TaskSnapshot>? _downloadSubscription;

  Query<Dataset> get reviewedDatasetsQuery =>
      _homeRepository.reviewedDatasetsQuery;

  (Failure?, List<Dataset>?) getRangeLocalDatasets(
    int start,
    int end,
  ) {
    final (failure, datasets) =
        _homeRepository.getRangeLocalDatasets(start, end);
    if (failure != null) {
      return (failure, null);
    }
    return (null, datasets);
  }

  Future<Dataset?> loadDatasetFromDisk({
    required Dataset dataset,
    required bool isReviewedDataset,
  }) async {
    final (failure, updatedDataset) = await _homeRepository.loadDatasetFromDisk(
      dataset: dataset,
      isReviewedDataset: isReviewedDataset,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: LoadDatasetsFailureState(failure),
      );
      return null;
    }

    state = state.copyWith(
      needReviewDatasets: !isReviewedDataset
          ? ([...state.needReviewDatasets]..addOrUpdate(updatedDataset!))
          : null,
      reviewedDatasets: isReviewedDataset
          ? ([...state.reviewedDatasets]..addOrUpdate(updatedDataset!))
          : null,
    );
    return updatedDataset;
  }

  Future<void> downloadDataset(
    Dataset dataset, {
    bool forceDownload = false,
  }) async {
    state = state.copyWith(
      presentationState: const DownloadDatasetProgressState(0),
    );
    final (failure, streamGroup) = await _homeRepository.downloadDataset(
      dataset,
      forceDownload: forceDownload,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: DownloadDatasetFailureState(failure),
      );
      return;
    }
    if (streamGroup == null) {
      state = state.copyWith(
        presentationState: const DownloadDatasetSuccessState(),
      );
      return;
    }

    _downloadSubscription = streamGroup.listen((event) {
      switch (event.state) {
        case TaskState.success:
          state = state.copyWith(
            presentationState: const DownloadDatasetSuccessState(),
          );
        case TaskState.canceled:
        case TaskState.error:
          state = state.copyWith(
            presentationState: const DownloadDatasetFailureState(),
          );
        case TaskState.paused:
          break;
        case TaskState.running:
          final double progress;
          if (event.totalBytes > 0 && event.bytesTransferred > 0) {
            progress = event.bytesTransferred /
                (event.metadata?.size ?? event.totalBytes);
          } else {
            progress = 0;
          }

          state = state.copyWith(
            presentationState: DownloadDatasetProgressState(progress),
          );
      }
    })
      ..onError((e, stackTrace) {
        state = state.copyWith(
          presentationState: const DownloadDatasetFailureState(),
        );
      });
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
            dirName: dataset.property.id,
            thumbnailPath: thumbnailPath,
            error: null,
          )
        : DatasetThumbnail(
            dirName: dataset.property.id,
            thumbnailPath: null,
            error: failure.message,
          );

    final datasets =
        isReviewedDatasets ? state.reviewedDatasets : state.needReviewDatasets;
    final updatedDatasets = datasets.map((oldDataset) {
      if (dataset.property.id == oldDataset.property.id) {
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

    final (failure, _) =
        await _preprocessRepository.deleteDatasetFromCloud(dataset.property.id);
    if (failure != null) {
      state = state.copyWith(
        presentationState: DeleteDatasetFailureState(failure),
      );
      return false;
    }
    if (dataset.path != null) await deleteDataset(dataset.path!);
    return true;
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }
}
