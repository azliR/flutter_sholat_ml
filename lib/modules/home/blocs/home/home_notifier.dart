import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/repositories/home_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

part 'home_state.dart';

final homeProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) => HomeNotifier());

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier()
      : _homeRepository = HomeRepository(),
        super(HomeState.initial());

  final HomeRepository _homeRepository;

  Future<void> loadDatasetsFromDisk() async {
    state = state.copyWith(isLoading: true);

    final (failure, savedPaths) = await _homeRepository.loadDatasetsFromDisk();
    if (failure != null) {
      state = state.copyWith(
        isLoading: false,
        presentationState: LoadDatasetsFailure(failure),
      );
      return;
    }
    state = state.copyWith(
      datasetPaths: savedPaths,
      isLoading: false,
    );
  }

  Future<void> deleteDataset(String path) async {
    final (failure, _) = await _homeRepository.deleteDataset(path);
    if (failure != null) {
      state = state.copyWith(
        isLoading: false,
        presentationState: DeleteDatasetFailure(failure),
      );
      return;
    }
  }
}
