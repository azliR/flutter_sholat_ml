part of 'lab_notifier.dart';

@immutable
class LabState extends Equatable {
  const LabState({
    required this.isInitialised,
    required this.predictState,
    required this.dataItems,
    required this.lastAccelData,
    required this.predictResult,
    required this.presentationState,
  });

  factory LabState.initial() => const LabState(
        isInitialised: false,
        predictState: PredictState.ready,
        dataItems: [],
        lastAccelData: null,
        predictResult: null,
        presentationState: LabInitialState(),
      );

  final bool isInitialised;
  final PredictState predictState;
  final List<DataItem> dataItems;
  final List<double>? lastAccelData;
  final String? predictResult;
  final LabPresentationState presentationState;

  LabState copyWith({
    bool? isInitialised,
    PredictState? predictState,
    List<DataItem>? dataItems,
    ValueGetter<List<double>?>? lastAccelData,
    String? predictResult,
    LabPresentationState? presentationState,
  }) {
    return LabState(
      isInitialised: isInitialised ?? this.isInitialised,
      predictState: predictState ?? this.predictState,
      dataItems: dataItems ?? this.dataItems,
      lastAccelData:
          lastAccelData != null ? lastAccelData() : this.lastAccelData,
      predictResult: predictResult ?? this.predictResult,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isInitialised,
        predictState,
        dataItems,
        lastAccelData,
        predictResult,
        presentationState,
      ];
}

enum PredictState {
  ready,
  preparing,
  predicting,
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
