part of 'lab_notifier.dart';

@immutable
class LabState extends Equatable {
  const LabState({
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

  factory LabState.initial({
    required bool showBottomPanel,
    required MlModel model,
  }) =>
      LabState(
        isInitialised: false,
        showBottomPanel: showBottomPanel,
        model: model,
        predictState: PredictState.ready,
        recordState: RecordState.ready,
        logs: const [],
        lastAccelData: null,
        predictedCategory: null,
        predictedCategories: null,
        presentationState: const LabInitialState(),
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
  final LabPresentationState presentationState;

  MlModelConfig get modelConfig => model.config;

  LabState copyWith({
    bool? isInitialised,
    bool? showBottomPanel,
    MlModel? model,
    PredictState? predictState,
    RecordState? recordState,
    List<String>? logs,
    ValueGetter<List<num>?>? lastAccelData,
    SholatMovementCategory? predictedCategory,
    List<SholatMovementCategory>? predictedCategories,
    LabPresentationState? presentationState,
  }) {
    return LabState(
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
sealed class LabPresentationState {
  const LabPresentationState();
}

final class LabInitialState extends LabPresentationState {
  const LabInitialState();
}

final class PredictSuccessState extends LabPresentationState {
  const PredictSuccessState();
}

final class PredictFailureState extends LabPresentationState {
  const PredictFailureState(this.failure);

  final Failure failure;
}
