part of 'preprocess_notifier.dart';

@immutable
class PreprocessState extends Equatable {
  const PreprocessState({
    required this.path,
    required this.datasetProp,
    required this.lastSelectedIndex,
    required this.currentHighlightedIndex,
    required this.isJumpSelectMode,
    required this.isFollowHighlightedMode,
    required this.isPlaying,
    required this.isEdited,
    required this.isAutosave,
    required this.showBottomPanel,
    required this.dataItems,
    required this.selectedDataItemIndexes,
    required this.presentationState,
  });

  factory PreprocessState.initial() => const PreprocessState(
        path: '',
        datasetProp: null,
        lastSelectedIndex: null,
        currentHighlightedIndex: 0,
        isJumpSelectMode: false,
        isFollowHighlightedMode: false,
        isPlaying: false,
        isEdited: false,
        isAutosave: false,
        showBottomPanel: true,
        dataItems: [],
        selectedDataItemIndexes: {},
        presentationState: PreprocessInitial(),
      );

  final String path;
  final DatasetProp? datasetProp;
  final int currentHighlightedIndex;
  final int? lastSelectedIndex;
  final bool isJumpSelectMode;
  final bool isFollowHighlightedMode;
  final bool isPlaying;
  final bool isEdited;
  final bool isAutosave;
  final bool showBottomPanel;
  final List<DataItem> dataItems;
  final Set<int> selectedDataItemIndexes;
  final PreprocessPresentationState presentationState;

  PreprocessState copyWith({
    String? path,
    DatasetProp? datasetProp,
    int? currentHighlightedIndex,
    ValueGetter<int?>? lastSelectedIndex,
    bool? isJumpSelectMode,
    bool? isFollowHighlightedMode,
    bool? isPlaying,
    bool? isEdited,
    bool? isAutosave,
    bool? showBottomPanel,
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
      isJumpSelectMode: isJumpSelectMode ?? this.isJumpSelectMode,
      isFollowHighlightedMode:
          isFollowHighlightedMode ?? this.isFollowHighlightedMode,
      isPlaying: isPlaying ?? this.isPlaying,
      isEdited: isEdited ?? this.isEdited,
      isAutosave: isAutosave ?? this.isAutosave,
      showBottomPanel: showBottomPanel ?? this.showBottomPanel,
      dataItems: dataItems ?? this.dataItems,
      selectedDataItemIndexes:
          selectedDataItemIndexes ?? this.selectedDataItemIndexes,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        path,
        datasetProp,
        lastSelectedIndex,
        currentHighlightedIndex,
        isJumpSelectMode,
        isFollowHighlightedMode,
        isPlaying,
        isEdited,
        isAutosave,
        showBottomPanel,
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

final class DownloadVideoProgressState extends PreprocessPresentationState {
  const DownloadVideoProgressState({this.csvProgress, this.videoProgress});

  final double? csvProgress;
  final double? videoProgress;
}

final class DownloadVideoSuccessState extends PreprocessPresentationState {
  const DownloadVideoSuccessState();
}

final class DownloadVideoFailureState extends PreprocessPresentationState {
  const DownloadVideoFailureState([this.failure]);

  final Failure? failure;
}

final class CancelDownloadVideoSuccessState
    extends PreprocessPresentationState {
  const CancelDownloadVideoSuccessState();
}

final class CancelDownloadVideoFailureState
    extends PreprocessPresentationState {
  const CancelDownloadVideoFailureState([this.failure]);

  final Failure? failure;
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
  const SaveDatasetSuccessState({required this.isAutosave});

  final bool isAutosave;
}

final class SaveDatasetFailureState extends PreprocessPresentationState {
  const SaveDatasetFailureState(this.failure);

  final Failure failure;
}
