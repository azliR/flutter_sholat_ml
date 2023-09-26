part of 'preprocess_notifier.dart';

@immutable
class PreprocessState {
  const PreprocessState({
    required this.preprocess,
    required this.datasets,
    required this.presentationState,
  });

  factory PreprocessState.initial() => const PreprocessState(
        preprocess: null,
        datasets: [],
        presentationState: PreprocessInitial(),
      );

  final Preprocess? preprocess;
  final List<Dataset> datasets;
  final PreprocessPresentationState presentationState;

  PreprocessState copyWith({
    Preprocess? preprocess,
    List<Dataset>? datasets,
    PreprocessPresentationState? presentationState,
  }) {
    return PreprocessState(
      preprocess: preprocess ?? this.preprocess,
      datasets: datasets ?? this.datasets,
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
