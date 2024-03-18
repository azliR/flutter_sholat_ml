import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/lab/repositories/lab_repository.dart';
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ml_model_provider.g.dart';

final _preprocessRepository = PreprocessRepository();
final _labRepository = LabRepository();

enum PredictState {
  ready,
  predicting,
}

@riverpod
class SelectedMlModel extends _$SelectedMlModel {
  @override
  MlModel? build() => null;

  void setModel(MlModel? model) => state = model;
}

@riverpod
class PredictedCategories extends _$PredictedCategories {
  @override
  List<SholatMovementCategory?>? build() => null;

  void setPredictions(List<SholatMovementCategory?>? categories) =>
      state = categories;
}

@riverpod
class Prediction extends _$Prediction {
  @override
  PredictState build() => PredictState.ready;

  Future<void> startPrediction() async {
    final model = ref.read(selectedMlModelProvider);
    if (model == null) {
      state = PredictState.ready;
      return;
    }

    state = PredictState.predicting;

    final dataItems =
        ref.read(preprocessProvider.select((value) => value.dataItems));

    final (computeFailure, data) =
        await _preprocessRepository.extractFeatureFromDatItems(dataItems);

    if (computeFailure != null) {
      state = PredictState.ready;
      throw Exception(computeFailure.message);
    }

    final batchSize = dataItems.length ~/ model.config.windowSize;

    final (failure, predictions) = await _labRepository.predict(
      path: model.path,
      data: data!,
      previousLabels: null,
      config: model.config.copyWith(
        batchSize: batchSize,
      ),
      skipWhenLocked: false,
    );

    if (failure != null) {
      state = PredictState.ready;
      throw Exception(failure.message);
    }

    if (predictions == null) {
      state = PredictState.ready;
      return;
    }

    var firstTakbirFound = false;
    final expandedPredictions = predictions.expand((category) {
      if (!firstTakbirFound && category == SholatMovementCategory.takbir) {
        firstTakbirFound = true;
      }

      return List.filled(batchSize, firstTakbirFound ? category : null);
    }).toList();

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

    ref
        .read(predictedCategoriesProvider.notifier)
        .setPredictions(expandedPredictions);

    state = PredictState.ready;
  }
}
