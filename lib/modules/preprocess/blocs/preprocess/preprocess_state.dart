part of 'preprocess_notifier.dart';

@immutable
class PreprocessState {
  const PreprocessState({
    required this.path,
    required this.datasetInfo,
    required this.currentSelectedIndex,
    required this.isPlaying,
    required this.datasets,
    required this.selectedDatasets,
    required this.presentationState,
  });

  factory PreprocessState.initial() => const PreprocessState(
        path: '',
        datasetInfo: null,
        currentSelectedIndex: 0,
        isPlaying: false,
        datasets: [],
        selectedDatasets: [],
        presentationState: PreprocessInitial(),
      );

  final String path;
  final DatasetInfo? datasetInfo;
  final int currentSelectedIndex;
  final bool isPlaying;
  final List<Dataset> datasets;
  final List<Dataset> selectedDatasets;
  final PreprocessPresentationState presentationState;

  PreprocessState copyWith({
    String? path,
    DatasetInfo? datasetInfo,
    int? currentSelectedIndex,
    bool? isPlaying,
    List<Dataset>? datasets,
    List<Dataset>? selectedDatasets,
    List<Dataset>? taggedDatasets,
    PreprocessPresentationState? presentationState,
  }) {
    return PreprocessState(
      path: path ?? this.path,
      datasetInfo: datasetInfo ?? this.datasetInfo,
      currentSelectedIndex: currentSelectedIndex ?? this.currentSelectedIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      datasets: datasets ?? this.datasets,
      selectedDatasets: selectedDatasets ?? this.selectedDatasets,
      presentationState: presentationState ?? this.presentationState,
    );
  }
}

sealed class PreprocessPresentationState {
  const PreprocessPresentationState();
}

final class PreprocessInitial extends PreprocessPresentationState {
  const PreprocessInitial();
}

final class GetDatasetInfoFailureState extends PreprocessPresentationState {
  const GetDatasetInfoFailureState(this.failure);

  final Failure failure;
}

final class ReadDatasetsFailureState extends PreprocessPresentationState {
  const ReadDatasetsFailureState(this.failure);

  final Failure failure;
}

final class SaveDatasetLoadingState extends PreprocessPresentationState {
  const SaveDatasetLoadingState();
}

final class SaveDatasetSuccessState extends PreprocessPresentationState {
  const SaveDatasetSuccessState();
}

final class SaveDatasetFailureState extends PreprocessPresentationState {
  const SaveDatasetFailureState(this.failure);

  final Failure failure;
}
