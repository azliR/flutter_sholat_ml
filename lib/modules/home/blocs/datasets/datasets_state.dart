part of 'datasets_notifier.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.isLoading,
    required this.needReviewDatasets,
    required this.reviewedDatasets,
    required this.selectedDatasets,
    required this.presentationState,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: false,
        needReviewDatasets: [],
        reviewedDatasets: [],
        selectedDatasets: [],
        presentationState: DatasetsInitial(),
      );

  final bool isLoading;
  final List<Dataset> needReviewDatasets;
  final List<Dataset> reviewedDatasets;
  final List<Dataset> selectedDatasets;
  final DatasetsPresentationState presentationState;

  HomeState copyWith({
    bool? isLoading,
    List<Dataset>? needReviewDatasets,
    List<Dataset>? reviewedDatasets,
    List<Dataset>? selectedDatasets,
    DatasetsPresentationState? presentationState,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      needReviewDatasets: needReviewDatasets ?? this.needReviewDatasets,
      reviewedDatasets: reviewedDatasets ?? this.reviewedDatasets,
      selectedDatasets: selectedDatasets ?? this.selectedDatasets,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        needReviewDatasets,
        reviewedDatasets,
        selectedDatasets,
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
  const DownloadDatasetProgressState(this.progress);

  final double progress;
}

final class DownloadDatasetSuccessState extends DatasetsPresentationState {
  const DownloadDatasetSuccessState();
}

final class DownloadDatasetFailureState extends DatasetsPresentationState {
  const DownloadDatasetFailureState([this.failure]);

  final Failure? failure;
}

final class DeleteDatasetLoadingState extends DatasetsPresentationState {
  const DeleteDatasetLoadingState();
}

final class DeleteDatasetSuccessState extends DatasetsPresentationState {
  const DeleteDatasetSuccessState();
}

final class DeleteDatasetFailureState extends DatasetsPresentationState {
  const DeleteDatasetFailureState(this.failure);

  final Failure? failure;
}
