part of 'labs_notifer.dart';

class LabsState extends Equatable {
  const LabsState({
    required this.presentationState,
  });

  factory LabsState.initial() => const LabsState(
        presentationState: LabsInitialState(),
      );

  final LabsPresentationState presentationState;

  LabsState copyWith({
    LabsPresentationState? presentationState,
  }) {
    return LabsState(
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [presentationState];
}

@immutable
sealed class LabsPresentationState {
  const LabsPresentationState();
}

final class LabsInitialState extends LabsPresentationState {
  const LabsInitialState();
}

final class PickModelLoadingState extends LabsPresentationState {
  const PickModelLoadingState();
}

final class PickModelSuccessState extends LabsPresentationState {
  const PickModelSuccessState(this.model);

  final MlModel model;
}

final class PickModelFailureState extends LabsPresentationState {
  const PickModelFailureState(this.failure);

  final Failure failure;
}

final class DeleteMlModelLoadingState extends LabsPresentationState {
  const DeleteMlModelLoadingState();
}

final class DeleteMlModelSuccessState extends LabsPresentationState {
  const DeleteMlModelSuccessState(this.mlModels);

  final List<MlModel> mlModels;
}

final class DeleteMlModelFailureState extends LabsPresentationState {
  const DeleteMlModelFailureState(this.failure);

  final Failure failure;
}
