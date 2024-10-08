import 'dart:isolate';

import 'package:dartx/dartx_io.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/ml_model/ml_model_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'dataset_provider.g.dart';

@riverpod
class ProblemFilters extends _$ProblemFilters {
  @override
  Set<ProblemType> build() {
    return ProblemType.values.toSet()
      ..removeAll([
        ProblemType.wrongPreviousMovementCategorySequence,
        ProblemType.wrongNextMovementCategorySequence,
      ]);
  }

  void toggle(ProblemType type) {
    state = state.contains(type)
        ? state.where((element) => element != type).toSet()
        : {...state, type};
  }
}

@riverpod
class DatasetProblems extends _$DatasetProblems {
  @override
  Future<List<Problem>> build() async {
    final preprocessRepository = PreprocessRepository();

    var dataItems =
        ref.watch(preprocessProvider.select((value) => value.dataItems));
    final enablePredictedPreview = ref.watch(enablePredictedPreviewProvider);

    if (enablePredictedPreview) {
      final predictedCategories =
          ref.watch(predictedCategoriesProvider).requireValue!;

      dataItems = await Isolate.run(
        () {
          var lastMovementSetId = const Uuid().v4();
          SholatMovementCategory? lastLabelCategory;
          return dataItems.mapIndexed(
            (index, dataItem) {
              final predictedCategory = predictedCategories[index];
              if (lastLabelCategory != predictedCategory) {
                lastMovementSetId = const Uuid().v4();
              }
              lastLabelCategory = predictedCategory;
              return dataItem.copyWith(
                labelCategory: () => predictedCategory,
                movementSetId: () => lastMovementSetId,
              );
            },
          ).toList();
        },
      );
    }

    final (failure, problems) =
        await preprocessRepository.analyseDataset(dataItems);
    if (failure != null) {
      throw Exception(failure.message);
    }

    return problems!;
  }
}

@riverpod
class EnablePredictedPreview extends _$EnablePredictedPreview {
  @override
  bool build() => false;

  void setEnable(bool enable) {
    if (enable) {
      ref.read(preprocessProvider.notifier).clearSelectedDataItems();

      if (ref.watch(predictedCategoriesProvider).valueOrNull == null) {
        state = false;
      }
    }

    state = enable;
  }
}

// @riverpod
// class DatasetNotifier extends _$DatasetNotifier {
//   final _preprocessRepository = PreprocessRepository();

//   @override
//   Future<void> build() async {}

//   Future<void> save({
//     required String path,
//     required List<DataItem> dataItems,
//     required DatasetProp datasetProp,
//     bool diskOnly = false,
//     bool withVideo = true,
//     bool autoSaving = false,
//   }) async {
//     if (!autoSaving) {
//       state = const AsyncLoading();
//     }

//     final (failure, newPath, updatedDatasetProp) =
//         await _preprocessRepository.saveDataset(
//       path: path,
//       dataItems: dataItems,
//       datasetProp: datasetProp,
//       diskOnly: diskOnly,
//       withVideo: withVideo,
//     );

//     if (failure != null) {
//       throw Exception(failure.message);
//     }

//     ref.read(preprocessProvider.notifier).setDatasetProp(updatedDatasetProp!);

//     // state = copyWith(
//     //   path: newPath ?? path,
//     //   datasetProp: datasetProp,
//     //   isEdited: false,
//     //   presentationState: SaveDatasetSuccessState(isAutosave: autoSaving),
//     // );
//     state = const AsyncData(null);
//   }
// }
