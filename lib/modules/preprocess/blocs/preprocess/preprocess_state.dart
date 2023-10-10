part of 'preprocess_notifier.dart';

@immutable
class PreprocessState extends Equatable {
  const PreprocessState({
    required this.path,
    required this.datasetInfo,
    required this.lastSelectedIndex,
    required this.currentHighlightedIndex,
    required this.isJumpSelectMode,
    required this.isFollowHighlightedMode,
    required this.isPlaying,
    required this.datasets,
    required this.selectedDatasets,
    required this.presentationState,
  });

  factory PreprocessState.initial() => const PreprocessState(
        path: '',
        datasetInfo: null,
        lastSelectedIndex: 0,
        currentHighlightedIndex: 0,
        isJumpSelectMode: false,
        isFollowHighlightedMode: false,
        isPlaying: false,
        datasets: [],
        selectedDatasets: [],
        presentationState: PreprocessInitial(),
      );

  final String path;
  final DatasetInfo? datasetInfo;
  final int currentHighlightedIndex;
  final int? lastSelectedIndex;
  final bool isJumpSelectMode;
  final bool isFollowHighlightedMode;
  final bool isPlaying;
  final List<Dataset> datasets;
  final List<Dataset> selectedDatasets;
  final PreprocessPresentationState presentationState;

  PreprocessState copyWith({
    String? path,
    DatasetInfo? datasetInfo,
    int? currentHighlightedIndex,
    ValueGetter<int?>? lastSelectedIndex,
    bool? isJumpSelectMode,
    bool? isFollowHighlightedMode,
    bool? isPlaying,
    List<Dataset>? datasets,
    List<Dataset>? selectedDatasets,
    List<Dataset>? taggedDatasets,
    PreprocessPresentationState? presentationState,
  }) {
    return PreprocessState(
      path: path ?? this.path,
      datasetInfo: datasetInfo ?? this.datasetInfo,
      currentHighlightedIndex:
          currentHighlightedIndex ?? this.currentHighlightedIndex,
      lastSelectedIndex: lastSelectedIndex?.call() ?? this.lastSelectedIndex,
      isJumpSelectMode: isJumpSelectMode ?? this.isJumpSelectMode,
      isFollowHighlightedMode:
          isFollowHighlightedMode ?? this.isFollowHighlightedMode,
      isPlaying: isPlaying ?? this.isPlaying,
      datasets: datasets ?? this.datasets,
      selectedDatasets: selectedDatasets ?? this.selectedDatasets,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        path,
        datasetInfo,
        lastSelectedIndex,
        currentHighlightedIndex,
        isJumpSelectMode,
        isFollowHighlightedMode,
        isPlaying,
        datasets,
        selectedDatasets,
        presentationState,
      ];
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
