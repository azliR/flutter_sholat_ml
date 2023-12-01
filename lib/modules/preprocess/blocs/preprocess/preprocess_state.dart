part of 'preprocess_notifier.dart';

@immutable
class PreprocessState extends Equatable {
  const PreprocessState({
    required this.path,
    required this.datasetProp,
    required this.lastSelectedIndex,
    required this.currentHighlightedIndex,
    required this.videoPlaybackSpeed,
    required this.isJumpSelectMode,
    required this.isFollowHighlightedMode,
    required this.isPlaying,
    required this.isEdited,
    required this.isAutosave,
    required this.dataItems,
    required this.selectedDataItemIndexes,
    required this.presentationState,
  });

  factory PreprocessState.initial() => const PreprocessState(
        path: '',
        videoPlaybackSpeed: 1,
        datasetProp: null,
        lastSelectedIndex: 0,
        currentHighlightedIndex: 0,
        isJumpSelectMode: false,
        isFollowHighlightedMode: false,
        isPlaying: false,
        isEdited: false,
        isAutosave: false,
        dataItems: [],
        selectedDataItemIndexes: {},
        presentationState: PreprocessInitial(),
      );

  final String path;
  final DatasetProp? datasetProp;
  final int currentHighlightedIndex;
  final int? lastSelectedIndex;
  final double videoPlaybackSpeed;
  final bool isJumpSelectMode;
  final bool isFollowHighlightedMode;
  final bool isPlaying;
  final bool isEdited;
  final bool isAutosave;
  final List<DataItem> dataItems;
  final Set<int> selectedDataItemIndexes;
  final PreprocessPresentationState presentationState;

  PreprocessState copyWith({
    String? path,
    DatasetProp? datasetProp,
    int? currentHighlightedIndex,
    ValueGetter<int?>? lastSelectedIndex,
    double? videoPlaybackSpeed,
    bool? isJumpSelectMode,
    bool? isFollowHighlightedMode,
    bool? isPlaying,
    bool? isEdited,
    bool? isAutosave,
    List<DataItem>? dataItems,
    Set<int>? selectedDataItemIndexes,
    PreprocessPresentationState? presentationState,
  }) {
    return PreprocessState(
      path: path ?? this.path,
      datasetProp: datasetProp ?? this.datasetProp,
      currentHighlightedIndex:
          currentHighlightedIndex ?? this.currentHighlightedIndex,
      lastSelectedIndex: lastSelectedIndex != null
          ? lastSelectedIndex()
          : this.lastSelectedIndex,
      videoPlaybackSpeed: videoPlaybackSpeed ?? this.videoPlaybackSpeed,
      isJumpSelectMode: isJumpSelectMode ?? this.isJumpSelectMode,
      isFollowHighlightedMode:
          isFollowHighlightedMode ?? this.isFollowHighlightedMode,
      isPlaying: isPlaying ?? this.isPlaying,
      isEdited: isEdited ?? this.isEdited,
      isAutosave: isAutosave ?? this.isAutosave,
      dataItems: dataItems ?? this.dataItems,
      selectedDataItemIndexes:
          selectedDataItemIndexes ?? this.selectedDataItemIndexes,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        path,
        videoPlaybackSpeed,
        datasetProp,
        lastSelectedIndex,
        currentHighlightedIndex,
        isJumpSelectMode,
        isFollowHighlightedMode,
        isPlaying,
        isEdited,
        isAutosave,
        dataItems,
        selectedDataItemIndexes,
        presentationState,
      ];
}

sealed class PreprocessPresentationState {
  const PreprocessPresentationState();
}

final class PreprocessInitial extends PreprocessPresentationState {
  const PreprocessInitial();
}

final class GetDatasetPropFailureState extends PreprocessPresentationState {
  const GetDatasetPropFailureState(this.failure);

  final Failure failure;
}

final class ReadDatasetsFailureState extends PreprocessPresentationState {
  const ReadDatasetsFailureState(this.failure);

  final Failure failure;
}

final class CompressVideoLoadingState extends PreprocessPresentationState {
  const CompressVideoLoadingState();
}

final class CompressVideoSuccessState extends PreprocessPresentationState {
  const CompressVideoSuccessState();
}

final class CompressVideoFailureState extends PreprocessPresentationState {
  const CompressVideoFailureState(this.failure);

  final Failure failure;
}

final class SaveDatasetLoadingState extends PreprocessPresentationState {
  const SaveDatasetLoadingState();
}

final class SaveDatasetAutoSavingState extends PreprocessPresentationState {
  const SaveDatasetAutoSavingState();
}

final class SaveDatasetSuccessState extends PreprocessPresentationState {
  const SaveDatasetSuccessState();
}

final class SaveDatasetFailureState extends PreprocessPresentationState {
  const SaveDatasetFailureState(this.failure);

  final Failure failure;
}
