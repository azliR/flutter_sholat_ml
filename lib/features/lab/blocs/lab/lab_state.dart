part of 'lab_notifier.dart';

enum InputDataType {
  float32,
  int32,
}

@immutable
class LabState extends Equatable {
  const LabState({
    required this.isInitialised,
    required this.showBottomPanel,
    required this.modelConfig,
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
    required MlModelConfig modelConfig,
  }) =>
      LabState(
        isInitialised: false,
        showBottomPanel: showBottomPanel,
        modelConfig: modelConfig,
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
  final MlModelConfig modelConfig;
  final PredictState predictState;
  final RecordState recordState;
  final List<String> logs;
  final List<num>? lastAccelData;
  final SholatMovementCategory? predictedCategory;
  final List<SholatMovementCategory>? predictedCategories;
  final LabPresentationState presentationState;

  LabState copyWith({
    bool? isInitialised,
    bool? showBottomPanel,
    MlModelConfig? modelConfig,
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
      modelConfig: modelConfig ?? this.modelConfig,
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
        modelConfig,
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
