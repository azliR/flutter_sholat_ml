import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/features/datasets/repositories/datasets_repository.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';

part 'datasets_state.dart';

final datasetsProvider =
    NotifierProvider.autoDispose<DatasetsNotifier, DatasetsState>(
  DatasetsNotifier.new,
);

class DatasetsNotifier extends AutoDisposeNotifier<DatasetsState> {
  DatasetsNotifier()
      : _homeRepository = DatasetsRepository(),
        _preprocessRepository = PreprocessRepository();

  final DatasetsRepository _homeRepository;
  final PreprocessRepository _preprocessRepository;

  StreamSubscription<TaskSnapshot>? _downloadSubscription;
  StreamSubscription<double>? _exportSubscription;

  @override
  DatasetsState build() {
    ref.onDispose(() {
      _downloadSubscription?.cancel();
      _exportSubscription?.cancel();
    });

    return DatasetsState.initial();
  }

  Future<(Failure?, List<Dataset>?)> getCloudDatasets(
    int start,
    int limit,
  ) async {
    final oldDatasets = state.reviewedDatasets;
    final startAfter = oldDatasets.isEmpty
        ? DateTime.now()
        : oldDatasets[start - 1].property.createdAt;
    final (failure, datasets) =
        await _homeRepository.getCloudDatasets(startAfter, limit);
    if (failure != null) {
      return (failure, null);
    }
    state = state.copyWith(
      reviewedDatasets: [...state.reviewedDatasets, ...datasets!],
    );
    return (null, datasets);
  }

  Future<(Failure?, List<Dataset>?)> getLocalDatasets(
    int start,
    int limit,
  ) async {
    final (failure, datasets) =
        await _homeRepository.getLocalDatasets(start, limit);
    if (failure != null) {
      return (failure, null);
    }
    state = state.copyWith(
      needReviewDatasets: [...state.needReviewDatasets, ...datasets!],
    );
    return (null, datasets);
  }

  void refreshDatasets({required bool isReviewedDataset}) {
    state = state.copyWith(
      needReviewDatasets: isReviewedDataset ? null : const [],
      reviewedDatasets: !isReviewedDataset ? null : const [],
    );
  }

  Future<void> refreshDatasetStatusAt(
    int index, {
    required bool isReviewedDataset,
  }) async {
    final dataset = isReviewedDataset
        ? state.reviewedDatasets[index]
        : state.needReviewDatasets[index];

    final (failure, updatedDataset) =
        await _homeRepository.getDatasetStatus(dataset: dataset);
    if (failure != null) {
      state = state.copyWith(
        presentationState: LoadDatasetsFailureState(failure),
      );
      return;
    }

    final isReviewed = dataset.property.isUploaded;
    final datasets = [
      ...isReviewed ? state.reviewedDatasets : state.needReviewDatasets,
    ];

    if (updatedDataset != null) {
      datasets[index] = updatedDataset;
    } else {
      datasets.removeAt(index);
    }

    state = state.copyWith(
      needReviewDatasets: !isReviewed ? datasets : null,
      reviewedDatasets: isReviewed ? datasets : null,
    );
  }

  Future<void> downloadDatasetAt(
    int index, {
    required Dataset dataset,
    bool forceDownload = false,
  }) async {
    state = state.copyWith(
      presentationState: const DownloadDatasetProgressState(),
    );
    final (failure, stream) = await _homeRepository.downloadDataset(
      dataset,
      forceDownload: forceDownload,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: DownloadDatasetFailureState(failure),
      );
      return;
    }
    var lastCsvProgress = 0.0;
    var lastVideoProgress = 0.0;

    await _downloadSubscription?.cancel();
    _downloadSubscription = stream!.listen(
      (taskSnapshot) {
        final fileName = taskSnapshot.ref.name;
        switch (taskSnapshot.state) {
          case TaskState.success:
            if (fileName == Paths.datasetCsv) {
              lastCsvProgress = 1;
            } else if (fileName == Paths.datasetVideo) {
              lastVideoProgress = 1;
            }
          case TaskState.canceled:
          case TaskState.error:
            state = state.copyWith(
              presentationState: const DownloadDatasetFailureState(),
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
          presentationState: DownloadDatasetProgressState(
            csvProgress: lastCsvProgress,
            videoProgress: lastVideoProgress,
          ),
        );
        if (lastCsvProgress == 1 && lastVideoProgress == 1) {
          _downloadSubscription?.cancel();
          state = state.copyWith(
            presentationState: DownloadDatasetSuccessState(index: index),
          );
        }
      },
      cancelOnError: true,
      onDone: () {
        _downloadSubscription?.cancel();
      },
      onError: (e, stackTrace) {
        state = state.copyWith(
          presentationState: const DownloadDatasetFailureState(),
        );
      },
    );
  }

  // Future<void> getThumbnailAt(
  //   int index, {
  //   required Dataset dataset,
  //   required bool isReviewedDatasets,
  // }) async {
  //   if (dataset.path == null) return;

  //   final (failure, thumbnailPath) =
  //       await _homeRepository.getDatasetThumbnail(dataset: dataset);

  //   final thumbnail = failure == null
  //       ? DatasetThumbnail(
  //           dirName: dataset.property.id,
  //           thumbnailPath: thumbnailPath,
  //           error: null,
  //         )
  //       : DatasetThumbnail(
  //           dirName: dataset.property.id,
  //           thumbnailPath: null,
  //           error: failure.message,
  //         );

  //   final datasets = [
  //     ...(isReviewedDatasets
  //         ? state.reviewedDatasets
  //         : state.needReviewDatasets),
  //   ];

  //   datasets[index] = dataset.copyWith(
  //     thumbnail: thumbnail,
  //   );

  //   state = state.copyWith(
  //     needReviewDatasets: !isReviewedDatasets ? datasets : null,
  //     reviewedDatasets: isReviewedDatasets ? datasets : null,
  //   );
  // }

  void setLastOpenedDatasetId(String id) {
    state = state.copyWith(lastOpenedDatasetId: id);
  }

  void onSelectedDataset(int index) {
    final selectedDatasetIndexes = state.selectedDatasetIndexes;
    if (selectedDatasetIndexes.contains(index)) {
      state = state.copyWith(
        selectedDatasetIndexes: [...selectedDatasetIndexes]..remove(index),
      );
      return;
    }
    state = state.copyWith(
      selectedDatasetIndexes: [...selectedDatasetIndexes, index],
    );
  }

  void onSelectAllDatasets() {
    state = state.copyWith(
      selectedDatasetIndexes:
          List.generate(state.needReviewDatasets.length, (index) => index),
    );
  }

  void clearSelections() {
    state = state.copyWith(selectedDatasetIndexes: []);
  }

  Future<void> deleteSelectedDatasets({
    required bool isReviewedDatasets,
  }) async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());

    final datasets =
        isReviewedDatasets ? state.reviewedDatasets : state.needReviewDatasets;
    final selectedDatasetIndexes = state.selectedDatasetIndexes;
    final selectedDatasets =
        selectedDatasetIndexes.map((i) => datasets[i]).toList();

    final (failure, _) = await _homeRepository
        .deleteDatasets(selectedDatasets.map((e) => e.path!).toList());

    if (failure != null) {
      state = state.copyWith(
        presentationState: DeleteDatasetFailureState(failure),
      );
      return;
    }

    final updatedDatasets = selectedDatasets.fold<List<Dataset>>(
      datasets,
      (previousValue, dataset) => previousValue..remove(dataset),
    );

    state = state.copyWith(
      selectedDatasetIndexes: [],
      needReviewDatasets: !isReviewedDatasets ? updatedDatasets : null,
      reviewedDatasets: isReviewedDatasets ? updatedDatasets : null,
      presentationState: DeleteDatasetFromDiskSuccessState(
        deletedIndexes: selectedDatasetIndexes,
        isReviewedDataset: isReviewedDatasets,
      ),
    );
  }

  Future<bool> deleteDatasetAt(
    int index, {
    required bool isReviewedDatasets,
  }) async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());

    final datasets =
        isReviewedDatasets ? state.reviewedDatasets : state.needReviewDatasets;
    final dataset = datasets[index];

    final (failure, _) = await _homeRepository.deleteDatasets([dataset.path!]);
    if (failure != null) {
      state = state.copyWith(
        presentationState: DeleteDatasetFailureState(failure),
      );
      return false;
    }

    final List<Dataset> updatedDatasets;
    if (isReviewedDatasets) {
      updatedDatasets = [...datasets]..[index] = dataset.copyWith(
          downloaded: false,
        );
    } else {
      updatedDatasets = [...datasets]..removeAt(index);
    }

    state = state.copyWith(
      needReviewDatasets: !isReviewedDatasets ? updatedDatasets : null,
      reviewedDatasets: isReviewedDatasets ? updatedDatasets : null,
      presentationState: DeleteDatasetFromDiskSuccessState(
        deletedIndexes: [index],
        isReviewedDataset: isReviewedDatasets,
      ),
    );
    return true;
  }

  Future<bool> deleteDatasetFromCloud(int index, Dataset dataset) async {
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
    if (dataset.path != null) {
      await deleteDatasetAt(
        index,
        isReviewedDatasets: true,
      );
    }

    state = state.copyWith(
      presentationState: const DeleteDatasetFromCloudSuccessState(),
    );
    return true;
  }

  Future<void> exportAndShareDatasets(List<String> paths) async {
    state = state.copyWith(
      presentationState: const ExportDatasetProgressState(0),
    );

    final (failure, progressStream, archivedPath) =
        await _homeRepository.exportDatasets(paths);
    if (failure != null) {
      state = state.copyWith(
        presentationState: ExportDatasetFailureState(failure),
      );
      return;
    }

    await _exportSubscription?.cancel();
    _exportSubscription = progressStream!.listen(
      (event) async {
        state = state.copyWith(
          presentationState: ExportDatasetProgressState(event),
        );
        if (event != 1) return;

        final (failure, _) =
            await _homeRepository.shareDataset([archivedPath!]);
        if (failure != null) {
          state = state.copyWith(
            presentationState: ExportDatasetFailureState(failure),
          );
          return;
        }
        state = state.copyWith(
          presentationState: const ExportDatasetSuccessState(),
        );
      },
      cancelOnError: true,
      onError: (Object? e, stackTrace) {
        Failure failure;
        if (e is Failure) {
          failure = e;
        } else {
          const message = 'Failed exporting datasets';
          failure = Failure(message, error: e);
        }
        state = state.copyWith(
          presentationState: ExportDatasetFailureState(failure),
        );
      },
    );
  }

  Future<void> importDatasets() async {
    state = state.copyWith(
      presentationState: const ImportDatasetProgressState(),
    );
    final (failure, _) = await _homeRepository.importDatasets();
    if (failure != null) {
      state = state.copyWith(
        presentationState: ImportDatasetFailureState(failure),
      );
      return;
    }
    state = state.copyWith(
      presentationState: const ImportDatasetSuccessState(),
    );
  }
}
