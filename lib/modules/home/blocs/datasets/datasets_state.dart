part of 'datasets_notifier.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.isLoading,
    required this.needReviewDatasetPaths,
    required this.reviewedDatasetPaths,
    required this.selectedDatasetPaths,
    required this.datasetThumbnails,
    required this.datasetInfos,
    required this.presentationState,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: false,
        needReviewDatasetPaths: [],
        reviewedDatasetPaths: [],
        selectedDatasetPaths: [],
        datasetThumbnails: [],
        datasetInfos: [],
        presentationState: DatasetsInitial(),
      );

  final bool isLoading;
  final List<String> needReviewDatasetPaths;
  final List<String> reviewedDatasetPaths;
  final List<String> selectedDatasetPaths;
  final List<DatasetThumbnail> datasetThumbnails;
  final List<DatasetInfo> datasetInfos;
  final DatasetsPresentationState presentationState;

  HomeState copyWith({
    bool? isLoading,
    List<String>? needReviewDatasetPaths,
    List<String>? reviewedDatasetPaths,
    List<String>? selectedDatasetPaths,
    List<DatasetThumbnail>? datasetThumbnails,
    List<DatasetInfo>? datasetInfos,
    DatasetsPresentationState? presentationState,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      needReviewDatasetPaths:
          needReviewDatasetPaths ?? this.needReviewDatasetPaths,
      reviewedDatasetPaths: reviewedDatasetPaths ?? this.reviewedDatasetPaths,
      selectedDatasetPaths: selectedDatasetPaths ?? this.selectedDatasetPaths,
      datasetThumbnails: datasetThumbnails ?? this.datasetThumbnails,
      datasetInfos: datasetInfos ?? this.datasetInfos,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        needReviewDatasetPaths,
        reviewedDatasetPaths,
        selectedDatasetPaths,
        datasetThumbnails,
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
