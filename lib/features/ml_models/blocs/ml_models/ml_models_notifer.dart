import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/ml_models/repositories/ml_models_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';

part 'ml_models_state.dart';

final mlModelsProvider =
    NotifierProvider.autoDispose<MlModelsNotifier, MlModelsState>(
        MlModelsNotifier.new);

class MlModelsNotifier extends AutoDisposeNotifier<MlModelsState> {
  MlModelsNotifier() : _mlModelsRepository = MlModelsRepository();

  final MlModelsRepository _mlModelsRepository;

  @override
  MlModelsState build() {
    return MlModelsState.initial(
      sortType: LocalStorageService.getMlModelsSortType(),
      sortDirection: LocalStorageService.getMlModelsSortDirection(),
    );
  }

  Future<(Failure?, List<MlModel>?)> getLocalMlModels(
    int start,
    int limit,
  ) async =>
      _mlModelsRepository.getLocalMlModels(
        start,
        limit,
        sortType: state.sortType,
        sortDirection: state.sortDirection,
      );

  Future<void> pickModel() async {
    state = state.copyWith(presentationState: const PickModelLoadingState());
    final (failure, mlModel) = await _mlModelsRepository.pickModel();
    if (failure != null) {
      state = state.copyWith(
        presentationState: PickModelFailureState(failure),
      );
      return;
    }
    state = state.copyWith(
      presentationState: PickModelSuccessState(mlModel!),
    );
  }

  Future<void> deleteMlModels(List<MlModel> mlModels) async {
    state =
        state.copyWith(presentationState: const DeleteMlModelLoadingState());

    final (failure, _) = await _mlModelsRepository.deleteMlModels(mlModels);
    if (failure != null) {
      state = state.copyWith(
        presentationState: DeleteMlModelFailureState(failure),
      );
      return;
    }

    state = state.copyWith(
      presentationState: DeleteMlModelSuccessState(mlModels),
    );
  }

  void setSortType(SortType sortType) {
    state = state.copyWith(sortType: sortType);
  }

  void setSortDirection(SortDirection sortDirection) {
    state = state.copyWith(sortDirection: sortDirection);
  }
}
