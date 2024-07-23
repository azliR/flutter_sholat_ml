import 'package:dartx/dartx_io.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/features/ml_model/repositories/ml_model_repository.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/dataset/dataset_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ml_model_provider.g.dart';

@riverpod
class SelectedMlModel extends _$SelectedMlModel {
  @override
  MlModel? build() => null;

  void setModel(MlModel? model) => state = model;
}

@riverpod
class OnlyPredictLabeled extends _$OnlyPredictLabeled {
  @override
  bool build() {
    return LocalStorageService.getPreprocessOnlyPredictLabeled();
  }

  void setEnable(bool onlyPredictLabeled) {
    state = onlyPredictLabeled;
    LocalStorageService.setPreprocessOnlyPredictLabeled(onlyPredictLabeled);
  }
}

@riverpod
class PredictedCategories extends _$PredictedCategories {
  final _preprocessRepository = PreprocessRepository();
  final _mlModelRepository = MlModelRepository();

  @override
  Future<List<SholatMovementCategory?>?> build() async {
    ref.onDispose(_mlModelRepository.dispose);
    return null;
  }

  void clearPrediction() {
    ref.read(enablePredictedPreviewProvider.notifier).setEnable(false);
    state = const AsyncData(null);
  }

  Future<void> startPrediction() async {
    state = const AsyncLoading();

    final model = ref.read(selectedMlModelProvider);
    if (model == null) {
      state = const AsyncData(null);
      return;
    }

    final originalDataItems =
        ref.read(preprocessProvider.select((value) => value.dataItems));

    final dataItems = List<DataItem>.from(originalDataItems);

    final onlyPredictLabeled = ref.read(onlyPredictLabeledProvider);
    if (onlyPredictLabeled) {
      dataItems.removeWhere((dataItem) => !dataItem.isLabeled);
    }

    const windowStep = 10;

    final (extractingFailure, X, _) =
        await _preprocessRepository.createSegmentsAndLabels(
      dataItems: dataItems,
      windowSize: model.config.windowSize,
      windowStep: windowStep,
    );

    if (extractingFailure != null) {
      state = AsyncError(
        extractingFailure.error ?? extractingFailure.message,
        extractingFailure.stackTrace ?? StackTrace.current,
      );
      return;
    }

    final data = X!.expand((e) => e).expand((e) => e).toList();
    final batchSize =
        data.length / model.config.windowSize ~/ model.config.numberOfFeatures;

    final (failure, predictions) = await _mlModelRepository.predict(
      path: model.path,
      data: data,
      previousLabels: [],
      config: model.config.copyWith(
        batchSize: batchSize,
      ),
      skipWhenLocked: false,
      disposeAfterUse: true,
    );

    if (failure != null) {
      state = AsyncError(
        failure.error ?? failure.message,
        failure.stackTrace ?? StackTrace.current,
      );
    }

    if (predictions == null) {
      state = const AsyncData(null);
      return;
    }

    final expandedPredictions =
        predictions.expand<SholatMovementCategory?>((category) {
      return List.filled(windowStep, category);
    }).toList();

    if (onlyPredictLabeled) {
      final firstUnlabeled =
          originalDataItems.firstWhile((dataItem) => !dataItem.isLabeled);
      final lastUnlabeled =
          originalDataItems.lastWhile((dataItem) => !dataItem.isLabeled);

      print(firstUnlabeled.length);

      expandedPredictions
        ..insertAll(
          0,
          List.filled(firstUnlabeled.length, null),
        )
        ..insertAll(
          expandedPredictions.length,
          List.filled(lastUnlabeled.length, null),
        );
    }

    if (expandedPredictions.length < originalDataItems.length) {
      expandedPredictions.addAll(
        List.filled(
            originalDataItems.length - expandedPredictions.length, null),
      );
    } else if (expandedPredictions.length > originalDataItems.length) {
      expandedPredictions.removeRange(
        originalDataItems.length,
        expandedPredictions.length,
      );
    }

    state = AsyncData(expandedPredictions);
  }
}

@riverpod
Future<double?> modelAccuracy(ModelAccuracyRef ref) async {
  final preprocessRepository = PreprocessRepository();

  final predictedCategoriesAsync = ref.watch(predictedCategoriesProvider);

  return predictedCategoriesAsync.when(
    data: (predictedCategories) async {
      if (predictedCategories == null) {
        return null;
      }

      final dataItems =
          ref.read(preprocessProvider.select((value) => value.dataItems));

      final accuracy = preprocessRepository.evaluateModel(
        categories: dataItems.map((e) => e.labelCategory).toList(),
        predictedCategories: predictedCategories,
      );

      return accuracy;
    },
    loading: () => null,
    error: (error, stackTrace) {
      throw Exception(error.toString());
    },
  );
}

@riverpod
Future<double?> modelFluctuationRate(
  ModelFluctuationRateRef ref,
) async {
  final preprocessRepository = PreprocessRepository();

  final predictedCategoriesAsync = ref.watch(predictedCategoriesProvider);

  return predictedCategoriesAsync.when(
    data: (predictedCategories) async {
      if (predictedCategories == null) {
        return null;
      }

      final accuracy = preprocessRepository.evaluateFluctuationRate(
        predictedCategories: predictedCategories,
        labeledCategories: ref
            .read(preprocessProvider)
            .dataItems
            .map(
              (e) => e.labelCategory,
            )
            .toList(),
      );

      return accuracy;
    },
    loading: () => null,
    error: (error, stackTrace) {
      throw Exception(error.toString());
    },
  );
}
