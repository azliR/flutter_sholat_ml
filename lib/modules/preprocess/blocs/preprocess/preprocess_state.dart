part of 'preprocess_notifier.dart';

@immutable
class PreprocessState {
  const PreprocessState({
    required this.preprocess,
    required this.currentSelectedIndex,
    required this.isPlaying,
    required this.datasets,
    required this.selectedDatasets,
    required this.presentationState,
  });

  factory PreprocessState.initial() => const PreprocessState(
        preprocess: null,
        currentSelectedIndex: 0,
        isPlaying: false,
        datasets: [],
        selectedDatasets: [],
        presentationState: PreprocessInitial(),
      );

  final Preprocess? preprocess;
  final int currentSelectedIndex;
  final bool isPlaying;
  final List<Dataset> datasets;
  final List<Dataset> selectedDatasets;
  final PreprocessPresentationState presentationState;

  PreprocessState copyWith({
    Preprocess? preprocess,
    int? currentSelectedIndex,
    bool? isPlaying,
    List<Dataset>? datasets,
    List<Dataset>? selectedDatasets,
    List<Dataset>? taggedDatasets,
    PreprocessPresentationState? presentationState,
  }) {
    return PreprocessState(
      preprocess: preprocess ?? this.preprocess,
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

final class GetPreprocessFailure extends PreprocessPresentationState {
  const GetPreprocessFailure(this.failure);

  final Failure failure;
}

final class ReadDatasetsFailure extends PreprocessPresentationState {
  const ReadDatasetsFailure(this.failure);

  final Failure failure;
}
