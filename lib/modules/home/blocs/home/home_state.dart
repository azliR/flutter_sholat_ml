// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_notifier.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.isLoading,
    required this.datasetPaths,
    required this.presentationState,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: false,
        datasetPaths: [],
        presentationState: HomeInitial(),
      );

  final bool isLoading;
  final List<String> datasetPaths;
  final HomePresentationState presentationState;

  HomeState copyWith({
    bool? isLoading,
    List<String>? datasetPaths,
    HomePresentationState? presentationState,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      datasetPaths: datasetPaths ?? this.datasetPaths,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        datasetPaths,
        presentationState,
      ];
}

@immutable
sealed class HomePresentationState {
  const HomePresentationState();
}

final class HomeInitial extends HomePresentationState {
  const HomeInitial();
}

final class LoadDatasetsFailure extends HomePresentationState {
  const LoadDatasetsFailure(this.failure);

  final Failure? failure;
}

final class DeleteDatasetFailure extends HomePresentationState {
  const DeleteDatasetFailure(this.failure);

  final Failure? failure;
}
