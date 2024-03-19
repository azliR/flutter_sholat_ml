part of 'ml_model_notifier.dart';

@immutable
class MlModelState extends Equatable {
  const MlModelState({
    required this.isInitialised,
    required this.showBottomPanel,
    required this.model,
    required this.predictState,
    required this.recordState,
    required this.logs,
    required this.lastAccelData,
    required this.predictedCategory,
    required this.predictedCategories,
    required this.presentationState,
  });

  factory MlModelState.initial({
    required bool showBottomPanel,
    required MlModel model,
  }) =>
      MlModelState(
        isInitialised: false,
        showBottomPanel: showBottomPanel,
        model: model,
        predictState: PredictState.ready,
        recordState: RecordState.ready,
        logs: const [],
        lastAccelData: null,
        predictedCategory: null,
        predictedCategories: null,
        presentationState: const MlModelInitialState(),
      );

  final bool isInitialised;
  final bool showBottomPanel;
  final MlModel model;
  final PredictState predictState;
  final RecordState recordState;
  final List<String> logs;
  final List<num>? lastAccelData;
  final SholatMovementCategory? predictedCategory;
  final List<SholatMovementCategory>? predictedCategories;
  final MlModelPresentationState presentationState;

  MlModelConfig get modelConfig => model.config;

  MlModelState copyWith({
    bool? isInitialised,
    bool? showBottomPanel,
    MlModel? model,
    PredictState? predictState,
    RecordState? recordState,
    List<String>? logs,
    ValueGetter<List<num>?>? lastAccelData,
    SholatMovementCategory? predictedCategory,
    List<SholatMovementCategory>? predictedCategories,
    MlModelPresentationState? presentationState,
  }) {
    return MlModelState(
      isInitialised: isInitialised ?? this.isInitialised,
      showBottomPanel: showBottomPanel ?? this.showBottomPanel,
      model: model ?? this.model,
      predictState: predictState ?? this.predictState,
      recordState: recordState ?? this.recordState,
      logs: logs ?? this.logs,
      lastAccelData:
          lastAccelData != null ? lastAccelData() : this.lastAccelData,
      predictedCategory: predictedCategory ?? this.predictedCategory,
      predictedCategories: predictedCategories ?? this.predictedCategories,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isInitialised,
        showBottomPanel,
        model,
        predictState,
        recordState,
        logs,
        lastAccelData,
        predictedCategory,
        predictedCategories,
        presentationState,
      ];
}

enum PredictState {
  ready,
  predicting,
}

enum RecordState {
  ready,
  preparing,
  recording,
  stopping,
}

@immutable
sealed class MlModelPresentationState {
  const MlModelPresentationState();
}

final class MlModelInitialState extends MlModelPresentationState {
  const MlModelInitialState();
}

final class PredictSuccessState extends MlModelPresentationState {
  const PredictSuccessState();
}

final class PredictFailureState extends MlModelPresentationState {
  const PredictFailureState(this.failure);

  final Failure failure;
}
