part of 'datasets_notifier.dart';

class DatasetsState extends Equatable {
  const DatasetsState({
    required this.isLoading,
    required this.needReviewDatasets,
    required this.reviewedDatasets,
    required this.selectedDatasetIndexes,
    required this.needReviewPagingController,
    required this.reviewedPagingController,
    required this.needReviewRefreshKey,
    required this.reviewedRefreshKey,
    required this.presentationState,
  });

  factory DatasetsState.initial() => DatasetsState(
        isLoading: false,
        needReviewDatasets: const [],
        reviewedDatasets: const [],
        selectedDatasetIndexes: const [],
        needReviewPagingController: PagingController<int, Dataset>(
          firstPageKey: 0,
        ),
        reviewedPagingController: PagingController<int, Dataset>(
          firstPageKey: 0,
        ),
        needReviewRefreshKey: GlobalKey<RefreshIndicatorState>(),
        reviewedRefreshKey: GlobalKey<RefreshIndicatorState>(),
        presentationState: const DatasetsInitial(),
      );

  final bool isLoading;
  final List<Dataset> needReviewDatasets;
  final List<Dataset> reviewedDatasets;
  final List<int> selectedDatasetIndexes;
  final PagingController<int, Dataset> needReviewPagingController;
  final PagingController<int, Dataset> reviewedPagingController;
  final GlobalKey<RefreshIndicatorState> needReviewRefreshKey;
  final GlobalKey<RefreshIndicatorState> reviewedRefreshKey;
  final DatasetsPresentationState presentationState;

  DatasetsState copyWith({
    bool? isLoading,
    List<Dataset>? needReviewDatasets,
    List<Dataset>? reviewedDatasets,
    List<int>? selectedDatasetIndexes,
    DatasetsPresentationState? presentationState,
  }) {
    return DatasetsState(
      isLoading: isLoading ?? this.isLoading,
      needReviewDatasets: needReviewDatasets ?? this.needReviewDatasets,
      reviewedDatasets: reviewedDatasets ?? this.reviewedDatasets,
      selectedDatasetIndexes:
          selectedDatasetIndexes ?? this.selectedDatasetIndexes,
      needReviewPagingController: needReviewPagingController,
      reviewedPagingController: reviewedPagingController,
      needReviewRefreshKey: needReviewRefreshKey,
      reviewedRefreshKey: reviewedRefreshKey,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        needReviewDatasets,
        reviewedDatasets,
        selectedDatasetIndexes,
        needReviewPagingController,
        reviewedPagingController,
        needReviewRefreshKey,
        reviewedRefreshKey,
        presentationState,
      ];
}

@immutable
sealed class DatasetsPresentationState {
  const DatasetsPresentationState();
}

final class DatasetsInitial extends DatasetsPresentationState {
  const DatasetsInitial();
}

final class LoadDatasetsFailureState extends DatasetsPresentationState {
  const LoadDatasetsFailureState(this.failure);

  final Failure? failure;
}

final class DownloadDatasetProgressState extends DatasetsPresentationState {
  const DownloadDatasetProgressState({this.csvProgress, this.videoProgress});

  final double? csvProgress;
  final double? videoProgress;
}

final class DownloadDatasetSuccessState extends DatasetsPresentationState {
  const DownloadDatasetSuccessState({
    required this.index,
  });

  final int index;
}

final class DownloadDatasetFailureState extends DatasetsPresentationState {
  const DownloadDatasetFailureState([this.failure]);

  final Failure? failure;
}

final class DeleteDatasetLoadingState extends DatasetsPresentationState {
  const DeleteDatasetLoadingState();
}

final class DeleteDatasetFromDiskSuccessState
    extends DatasetsPresentationState {
  const DeleteDatasetFromDiskSuccessState({
    required this.deletedIndexes,
    required this.isReviewedDataset,
  });

  final List<int> deletedIndexes;
  final bool isReviewedDataset;
}

final class DeleteDatasetFromCloudSuccessState
    extends DatasetsPresentationState {
  const DeleteDatasetFromCloudSuccessState();
}

final class DeleteDatasetFailureState extends DatasetsPresentationState {
  const DeleteDatasetFailureState(this.failure);

  final Failure? failure;
}

final class ExportDatasetProgressState extends DatasetsPresentationState {
  const ExportDatasetProgressState(this.progress);

  final double progress;
}

final class ExportDatasetSuccessState extends DatasetsPresentationState {
  const ExportDatasetSuccessState();
}

final class ExportDatasetFailureState extends DatasetsPresentationState {
  const ExportDatasetFailureState([this.failure]);

  final Failure? failure;
}

final class ImportDatasetProgressState extends DatasetsPresentationState {
  const ImportDatasetProgressState();
}

final class ImportDatasetSuccessState extends DatasetsPresentationState {
  const ImportDatasetSuccessState();
}

final class ImportDatasetFailureState extends DatasetsPresentationState {
  const ImportDatasetFailureState(this.failure);

  final Failure failure;
}
