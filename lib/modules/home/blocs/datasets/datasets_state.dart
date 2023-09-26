part of 'datasets_notifier.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.isLoading,
    required this.datasetPaths,
    required this.selectedDatasetPaths,
    required this.presentationState,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: false,
        datasetPaths: [],
        selectedDatasetPaths: [],
        presentationState: DatasetsInitial(),
      );

  final bool isLoading;
  final List<String> datasetPaths;
  final List<String> selectedDatasetPaths;
  final DatasetsPresentationState presentationState;

  HomeState copyWith({
    bool? isLoading,
    List<String>? datasetPaths,
    List<String>? selectedDatasetPaths,
    DatasetsPresentationState? presentationState,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      datasetPaths: datasetPaths ?? this.datasetPaths,
      selectedDatasetPaths: selectedDatasetPaths ?? this.selectedDatasetPaths,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        datasetPaths,
        selectedDatasetPaths,
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
