import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> pickModel() async {
    state = state.copyWith(presentationState: const PickModelProgressState());
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
}
