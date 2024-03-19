part of 'ml_models_notifer.dart';

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

class MlModelsState extends Equatable {
  const MlModelsState({
    required this.sortType,
    required this.sortDirection,
    required this.presentationState,
  });

  factory MlModelsState.initial({
    required SortType sortType,
    required SortDirection sortDirection,
  }) =>
      MlModelsState(
        sortType: sortType,
        sortDirection: sortDirection,
        presentationState: const MlModelsInitialState(),
      );

  final SortType sortType;
  final SortDirection sortDirection;
  final MlModelsPresentationState presentationState;

  MlModelsState copyWith({
    SortType? sortType,
    SortDirection? sortDirection,
    MlModelsPresentationState? presentationState,
  }) {
    return MlModelsState(
      sortType: sortType ?? this.sortType,
      sortDirection: sortDirection ?? this.sortDirection,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [sortType, sortDirection, presentationState];
}

@immutable
sealed class MlModelsPresentationState {
  const MlModelsPresentationState();
}

final class MlModelsInitialState extends MlModelsPresentationState {
  const MlModelsInitialState();
}

final class PickModelLoadingState extends MlModelsPresentationState {
  const PickModelLoadingState();
}

final class PickModelSuccessState extends MlModelsPresentationState {
  const PickModelSuccessState(this.model);

  final MlModel model;
}

final class PickModelFailureState extends MlModelsPresentationState {
  const PickModelFailureState(this.failure);

  final Failure failure;
}

final class DeleteMlModelLoadingState extends MlModelsPresentationState {
  const DeleteMlModelLoadingState();
}

final class DeleteMlModelSuccessState extends MlModelsPresentationState {
  const DeleteMlModelSuccessState(this.mlModels);

  final List<MlModel> mlModels;
}

final class DeleteMlModelFailureState extends MlModelsPresentationState {
  const DeleteMlModelFailureState(this.failure);

  final Failure failure;
}
