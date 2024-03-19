import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/ml_model/repositories/ml_model_repository.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ml_model_provider.g.dart';

final _preprocessRepository = PreprocessRepository();
final _mlModelRepository = MlModelRepository();

@riverpod
class SelectedMlModel extends _$SelectedMlModel {
  @override
  MlModel? build() => null;

  void setModel(MlModel? model) => state = model;
}

@riverpod
class PredictedCategories extends _$PredictedCategories {
  @override
  Future<List<SholatMovementCategory?>?> build() async => null;

  void clearPrediction() => state = const AsyncData(null);

  Future<void> startPrediction() async {
    state = const AsyncData(null);
    state = const AsyncLoading();

    final model = ref.read(selectedMlModelProvider);
    if (model == null) {
      state = const AsyncData(null);
      return;
    }

    final dataItems =
        ref.read(preprocessProvider.select((value) => value.dataItems));
    const windowStep = 10;

    final (extractingFailure, X, y) =
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
      previousLabels: null,
      config: model.config.copyWith(
        batchSize: batchSize,
      ),
      skipWhenLocked: false,
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

    var firstTakbirFound = false;
    final expandedPredictions = predictions.expand((category) {
      if (!firstTakbirFound && category == SholatMovementCategory.takbir) {
        firstTakbirFound = true;
      }

      return List.filled(windowStep, firstTakbirFound ? category : null);
    }).toList();

    print('predictions:' + predictions.length.toString());
    print('expandedPredictions:' + expandedPredictions.length.toString());

    if (expandedPredictions.length < dataItems.length) {
      expandedPredictions.addAll(
        List.filled(dataItems.length - expandedPredictions.length, null),
      );
    } else if (expandedPredictions.length > dataItems.length) {
      expandedPredictions.removeRange(
        dataItems.length,
        expandedPredictions.length,
      );
    }

    state = AsyncData(expandedPredictions);
  }
}

@riverpod
Future<double?> modelEvaluation(ModelEvaluationRef ref) async {
  // final predictedCategoriesAsync = AsyncData(<SholatMovementCategory>[]);
  final predictedCategoriesAsync = ref.watch(predictedCategoriesProvider);

  return predictedCategoriesAsync.when(
    data: (predictedCategories) async {
      if (predictedCategories == null) {
        return null;
      }

      final dataItems =
          ref.read(preprocessProvider.select((value) => value.dataItems));

      final (failure, evaluation) = await _preprocessRepository.evaluateModel(
        categories: dataItems.map((e) => e.labelCategory).toList(),
        predictedCategories: predictedCategories,
      );

      if (failure != null) {
        throw Exception(failure.message);
      }

      return evaluation;
    },
    loading: () => null,
    error: (error, stackTrace) {
      throw Exception(error.toString());
    },
  );
}
