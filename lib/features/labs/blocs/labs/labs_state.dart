part of 'labs_notifer.dart';

enum SortType {
  modelName,
  lastUpdated;

  String get name => switch (this) {
        SortType.modelName => 'Name',
        SortType.lastUpdated => 'Last Updated'
      };
}

enum SortDirection {
  ascending,
  descending;

  String get name => switch (this) {
        SortDirection.ascending => 'Ascending',
        SortDirection.descending => 'Descending'
      };
}

class LabsState extends Equatable {
  const LabsState({
    required this.sortType,
    required this.sortDirection,
    required this.presentationState,
  });

  factory LabsState.initial({
    required SortType sortType,
    required SortDirection sortDirection,
  }) =>
      LabsState(
        sortType: sortType,
        sortDirection: sortDirection,
        presentationState: const LabsInitialState(),
      );

  final SortType sortType;
  final SortDirection sortDirection;
  final LabsPresentationState presentationState;

  LabsState copyWith({
    SortType? sortType,
    SortDirection? sortDirection,
    LabsPresentationState? presentationState,
  }) {
    return LabsState(
      sortType: sortType ?? this.sortType,
      sortDirection: sortDirection ?? this.sortDirection,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [sortType, sortDirection, presentationState];
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
