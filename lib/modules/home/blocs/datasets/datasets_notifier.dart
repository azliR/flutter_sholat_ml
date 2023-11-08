import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartx/dartx_io.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
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
  StreamSubscription<double>? _exportSubscription;

  final needReviewRefreshKey = GlobalKey<RefreshIndicatorState>();
  final reviewedRefreshKey = GlobalKey<RefreshIndicatorState>();

  Query<Dataset> get reviewedDatasetsQuery =>
      _homeRepository.reviewedDatasetsQuery;

  (Failure?, List<Dataset>?) getLocalDatasets(
    int start,
    int end,
  ) {
    final (failure, datasets) = _homeRepository.getLocalDatasets(start, end);
    if (failure != null) {
      return (failure, null);
    }
    return (null, datasets);
  }

  Future<Dataset?> loadDatasetFromDisk({
    required Dataset dataset,
    required bool isReviewedDataset,
    required bool createDirIfNotExist,
  }) async {
    final (failure, updatedDataset) = await _homeRepository.loadDatasetFromDisk(
      dataset: dataset,
      isReviewedDataset: isReviewedDataset,
      createDirIfNotExist: createDirIfNotExist,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: LoadDatasetsFailureState(failure),
      );
      return null;
    }

    if (updatedDataset == null) {
      state = state.copyWith(
        needReviewDatasets: !isReviewedDataset
            ? (state.needReviewDatasets
              ..dropLastWhile(
                (oldDataset) => oldDataset.property.id == dataset.property.id,
              ))
            : null,
        reviewedDatasets: isReviewedDataset
            ? (state.reviewedDatasets
              ..dropLastWhile(
                (oldDataset) => oldDataset.property.id == dataset.property.id,
              ))
            : null,
      );
      return null;
    }

    final datasets =
        isReviewedDataset ? state.reviewedDatasets : state.needReviewDatasets;
    final updatedDatasets = datasets.map((oldDataset) {
      if (dataset.property.id == oldDataset.property.id) {
        return dataset;
      }
      return oldDataset;
    }).toList();

    state = state.copyWith(
      needReviewDatasets: !isReviewedDataset
          ? (updatedDatasets..addOrUpdate(updatedDataset))
          : null,
      reviewedDatasets: isReviewedDataset
          ? (updatedDatasets..addOrUpdate(updatedDataset))
          : null,
    );
    return updatedDataset;
  }

  Future<void> refreshDatasetDownloadStatus(String path) async {
    final (failure, downloaded) =
        await _homeRepository.getDatasetDownloadStatus(path: path);
    if (failure != null) {
      state = state.copyWith(
        presentationState: LoadDatasetsFailureState(failure),
      );
      return;
    }
    final isReviewed = path.contains(Directories.reviewedDirPath);
    final datasets =
        isReviewed ? state.reviewedDatasets : state.needReviewDatasets;
    final updatedDatasets = datasets.map((dataset) {
      if (dataset.path == path) {
        return dataset.copyWith(downloaded: downloaded);
      }
      return dataset;
    }).toList();

    state = state.copyWith(
      needReviewDatasets: !isReviewed ? updatedDatasets : null,
      reviewedDatasets: isReviewed ? updatedDatasets : null,
    );
  }

  Future<void> downloadDataset(
    Dataset dataset, {
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
          state = state.copyWith(
            presentationState: DownloadDatasetSuccessState(dataset),
          );
        }
      },
      cancelOnError: true,
      onDone: () {
        log('donw');
        _downloadSubscription?.cancel();
      },
      onError: (e, stackTrace) {
        state = state.copyWith(
          presentationState: const DownloadDatasetFailureState(),
        );
      },
    );
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

  Future<void> deleteSelectedDatasets({
    required bool isReviewedDatasets,
  }) async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());
    final selectedDatasets = state.selectedDatasets;
    final (failure, _) = await _homeRepository
        .deleteDatasets(selectedDatasets.map((e) => e.path!).toList());

    if (failure != null) {
      state = state.copyWith(
        presentationState: DeleteDatasetFailureState(failure),
      );
      return;
    }
    final datasets =
        isReviewedDatasets ? state.reviewedDatasets : state.needReviewDatasets;
    final updatedDatasets = datasets
        .where((dataset) => !selectedDatasets.contains(dataset))
        .toList();
    state = state.copyWith(
      selectedDatasets: [],
      needReviewDatasets: !isReviewedDatasets ? updatedDatasets : null,
      reviewedDatasets: isReviewedDatasets ? updatedDatasets : null,
      presentationState: DeleteDatasetSuccessState(
        state.selectedDatasets.map((e) => e.path!).toList(),
      ),
    );
  }

  Future<bool> deleteDataset(
    String path, {
    required bool isReviewedDatasets,
  }) async {
    state =
        state.copyWith(presentationState: const DeleteDatasetLoadingState());

    final (failure, _) = await _homeRepository.deleteDatasets([path]);
    if (failure != null) {
      state = state.copyWith(
        isLoading: false,
        presentationState: DeleteDatasetFailureState(failure),
      );
      return false;
    }
    final datasets =
        isReviewedDatasets ? state.reviewedDatasets : state.needReviewDatasets;
    final updatedDatasets =
        datasets.where((dataset) => dataset.path != path).toList();
    state = state.copyWith(
      needReviewDatasets: !isReviewedDatasets ? updatedDatasets : null,
      reviewedDatasets: isReviewedDatasets ? updatedDatasets : null,
      presentationState: DeleteDatasetSuccessState([path]),
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
    if (dataset.path != null) {
      await deleteDataset(
        dataset.path!,
        isReviewedDatasets: true,
      );
    }
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
      (event) {
        state = state.copyWith(
          presentationState: ExportDatasetProgressState(event),
        );
      },
      cancelOnError: true,
      onDone: () async {
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
      onError: (e, stackTrace) {
        state = state.copyWith(
          presentationState: const ExportDatasetFailureState(),
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

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }
}
