import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/labs/repositories/labs_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';

part 'labs_state.dart';

final labsProvider =
    NotifierProvider.autoDispose<LabsNotifier, LabsState>(LabsNotifier.new);

class LabsNotifier extends AutoDisposeNotifier<LabsState> {
  LabsNotifier() : _labsRepository = LabsRepository();

  final LabsRepository _labsRepository;

  @override
  LabsState build() {
    return LabsState.initial();
  }

  (Failure?, List<MlModel>?) getLocalMlModels(
    int start,
    int limit,
  ) =>
      _labsRepository.getLocalMlModels(start, limit);

  Future<void> pickModel() async {
    state = state.copyWith(presentationState: const PickModelLoadingState());
    final (failure, path) = await _labsRepository.pickModel();
    if (failure != null) {
      state = state.copyWith(
        presentationState: PickModelFailureState(failure),
      );
      return;
    }
    state = state.copyWith(
      presentationState: PickModelSuccessState(path!),
    );
  }

  Future<void> deleteMlModels(List<MlModel> mlModels) async {
    state =
        state.copyWith(presentationState: const DeleteMlModelLoadingState());

    final (failure, _) = await _labsRepository.deleteMlModels(mlModels);
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
}
