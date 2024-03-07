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

final class PickModelProgressState extends LabsPresentationState {
  const PickModelProgressState();
}

final class PickModelSuccessState extends LabsPresentationState {
  const PickModelSuccessState(this.path);

  final String path;
}

final class PickModelFailureState extends LabsPresentationState {
  const PickModelFailureState(this.failure);

  final Failure failure;
}
