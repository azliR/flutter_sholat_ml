import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dartx/dartx_io.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model_config.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/post_processing/temporal_consistency_enforcements.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/post_processing/weightings.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_ml_model_storage_service%20.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:synchronized/synchronized.dart';

class MlModelRepository {
  final _lock = Lock();
  final _majorityVoter = MajorityVoter();

  OrtSession? _session;
  OrtSessionOptions? _sessionOptions;

  final _labelCategories = {
    0: SholatMovementCategory.takbir,
    1: SholatMovementCategory.berdiri,
    2: SholatMovementCategory.ruku,
    3: SholatMovementCategory.iktidal,
    4: SholatMovementCategory.qunut,
    5: SholatMovementCategory.sujud,
    6: SholatMovementCategory.duduk,
    7: SholatMovementCategory.transisi,
  };

  void _initialiseOrt(String path) {
    OrtEnv.instance.init(
      level: OrtLoggingLevel.verbose,
    );
    _sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromFile(File(path), _sessionOptions!);
  }

  Future<(Failure?, List<SholatMovementCategory>?)> predict({
    required String path,
    required List<num> data,
    required List<SholatMovementCategory> previousLabels,
    required MlModelConfig config,
    required bool skipWhenLocked,
    bool disposeAfterUse = false,
    void Function()? onPredicting,
  }) async {
    try {
      if (_lock.locked && skipWhenLocked) return (null, null);

      onPredicting?.call();

      return await _lock.synchronized(() async {
        if (_session == null) {
          _initialiseOrt(path);
        }

        final inputOrt = OrtValueTensor.createTensorWithDataList(
          _convertInputDType(data: data, inputDType: config.inputDataType),
          [config.batchSize, config.windowSize, config.numberOfFeatures],
        );

        final Map<String, OrtValueTensor> inputs;

        if (config.enableTeacherForcing) {
          final numberOfClasses = _labelCategories.length;
          final teacherInput = _generateTeacherForcingLabels(
            lastPredictedCategories: previousLabels,
            batchSize: config.batchSize,
          );

          final teacherInputOrt = OrtValueTensor.createTensorWithDataList(
            _convertInputDType(
              data: teacherInput,
              inputDType: config.inputDataType,
            ),
            [config.batchSize, numberOfClasses],
          );

          log(teacherInputOrt.value.toString());
          inputs = {
            'input_data': inputOrt,
            'teacher_input': teacherInputOrt,
          };
        } else {
          inputs = {
            'x': inputOrt,
          };
        }

        final runOptions = OrtRunOptions();
        final outputs = await _session!.runAsync(runOptions, inputs);

        final yPred = outputs![0]!.value! as List<List<double>>;
        var postProcessedPred = yPred;

        // for (final smoothing in config.smoothings) {
        //   switch (smoothing) {
        //     case MovingAverage():
        //       postProcessedPred =
        //           _movingAverageSmoothing(postProcessedPred, config.windowSize);
        //     case ExponentialSmoothing():
        //       postProcessedPred =
        //           _exponentialSmoothing(postProcessedPred, smoothing.alpha!);
        //   }
        // }

        // for (final filtering in config.filterings) {
        //   switch (filtering) {
        //     case MedianFilter():
        //       postProcessedPred =
        //           _medianFilter(postProcessedPred, config.windowSize);
        //     case LowPassFilter():
        //       postProcessedPred =
        //           _lowPassFilter(postProcessedPred, filtering.alpha!);
        //   }
        // }

        for (final tce in config.temporalConsistencyEnforcements) {
          switch (tce) {
            case MajorityVoting():
              break;
            // case TransitionConstraints():
            //   postProcessedPred =
            //       _transitionConstraints(postProcessedPred, tce.minDuration!);
          }
        }

        for (final weighting in config.weightings) {
          switch (weighting) {
            case TransitionWeighting():
              postProcessedPred = transitionWeighting(
                rawPredictions: postProcessedPred,
                prevPredictions: previousLabels,
                weight: weighting.weight!,
              );
          }
        }

        final indexes = _argmaxByAxis(postProcessedPred, 1);

        inputOrt.release();
        runOptions.release();

        for (final element in outputs) {
          element?.release();
        }

        final predictions = indexes.map((i) {
          var prediction = _labelCategories[i]!;
          for (final tce in config.temporalConsistencyEnforcements) {
            switch (tce) {
              case MajorityVoting():
                final newPrediction = _majorityVoter.votedPrediction(
                  prediction,
                  tce.minConsecutivePredictions!,
                );
                prediction = newPrediction;
              // case TransitionConstraints():
              //   break;
            }
          }

          return prediction;
        }).toList();
        return (null, predictions);
      });
    } catch (e, stackTrace) {
      const message = 'Failed to predict';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    } finally {
      if (disposeAfterUse) {
        _session?.release();
        _sessionOptions?.release();

        _session = null;
        _sessionOptions = null;

        _majorityVoter.reset();
      }
    }
  }

  List<num> _generateTeacherForcingLabels({
    required List<SholatMovementCategory>? lastPredictedCategories,
    required int batchSize,
  }) {
    final numberOfClassess = SholatMovementCategory.values.length;
    final totalDataSize = batchSize * numberOfClassess;

    if (lastPredictedCategories == null) {
      return List.filled(totalDataSize, 0);
    }

    final lastPredictedIndex = lastPredictedCategories
        .takeLast(batchSize)
        .map((e) => e.index)
        .expand((e) => List.filled(numberOfClassess, 0)..[e] = 1)
        .toList();

    if (lastPredictedIndex.length < totalDataSize) {
      lastPredictedIndex.insertAll(
        0,
        List.filled(totalDataSize - lastPredictedIndex.length, 0),
      );
    }

    return lastPredictedIndex;
  }

  List<List<double>> _movingAverageSmoothing(
    List<List<double>> predictions,
    int windowSize,
  ) {
    final smoothedPredictions = <List<double>>[];
    for (var i = 0; i < predictions.length; i++) {
      final smoothedProbabilities =
          List<double>.filled(predictions[i].length, 0);
      for (var j = 0; j < predictions[i].length; j++) {
        var sum = 0.0;
        var count = 0;
        for (int k = math.max(0, i - windowSize ~/ 2);
            k <= math.min(predictions.length - 1, i + windowSize ~/ 2);
            k++) {
          sum += predictions[k][j];
          count++;
        }
        smoothedProbabilities[j] = sum / count;
      }
      smoothedPredictions.add(smoothedProbabilities);
    }
    return smoothedPredictions;
  }

  List<List<double>> _exponentialSmoothing(
    List<List<double>> predictions,
    double alpha,
  ) {
    final smoothedPredictions =
        List<List<double>>.filled(predictions.length, []);

    for (var i = 0; i < predictions.length; i++) {
      final sublist = predictions[i];
      final smoothedSublist = _exponentialSmoothingSublist(sublist, alpha);
      smoothedPredictions[i] = smoothedSublist;
    }

    return smoothedPredictions;
  }

  List<double> _exponentialSmoothingSublist(
    List<double> sublist,
    double alpha,
  ) {
    final smoothedSublist = List<double>.filled(sublist.length, 0);

    // Initialize the previous smoothed value with the first data point
    var prevSmoothedValue = sublist[0];
    smoothedSublist[0] = prevSmoothedValue;

    for (var i = 1; i < sublist.length; i++) {
      final currentValue = sublist[i];
      final smoothedValue =
          alpha * currentValue + (1 - alpha) * prevSmoothedValue;
      smoothedSublist[i] = smoothedValue;
      prevSmoothedValue = smoothedValue;
    }

    return smoothedSublist;
  }

  List<List<double>> _medianFilter(
    List<List<double>> predictions,
    int windowSize,
  ) {
    final numRows = predictions.length;
    final numCols = predictions[0].length;
    final filteredPredictions = List<List<double>>.generate(
      numRows,
      (_) => List.filled(numCols, 0.0),
    );

    final offset = windowSize ~/ 2;

    for (var row = 0; row < numRows; row++) {
      for (var col = 0; col < numCols; col++) {
        final window = <double>[];

        for (var i = math.max(0, row - offset);
            i <= math.min(numRows - 1, row + offset);
            i++) {
          for (var j = math.max(0, col - offset);
              j <= math.min(numCols - 1, col + offset);
              j++) {
            window.add(predictions[i][j]);
          }
        }

        window.sort();
        final median = window[window.length ~/ 2];
        filteredPredictions[row][col] = median;
      }
    }

    return filteredPredictions;
  }

  List<List<double>> _lowPassFilter(
    List<List<double>> predictions,
    double alpha,
  ) {
    final filteredData = List<List<double>>.filled(predictions.length, []);

    for (var i = 0; i < predictions.length; i++) {
      final sublist = predictions[i];
      final filteredSublist = _lowPassFilterSublist(sublist, alpha);
      filteredData[i] = filteredSublist;
    }

    return filteredData;
  }

  List<double> _lowPassFilterSublist(List<double> sublist, double alpha) {
    final filteredSublist = List<double>.filled(sublist.length, 0);

    var prevValue = sublist[0];
    filteredSublist[0] = prevValue;

    for (var i = 1; i < sublist.length; i++) {
      final currentValue = sublist[i];
      final filteredValue = alpha * prevValue + (1 - alpha) * currentValue;
      filteredSublist[i] = filteredValue;
      prevValue = filteredValue;
    }

    return filteredSublist;
  }

  List<List<double>> _majorityVoting(
    List<List<double>> predictions,
    int windowSize,
  ) {
    final votedPredictions = <List<double>>[];

    for (var i = 0; i < predictions.length; i++) {
      final start = math.max(0, i - windowSize ~/ 2);
      final end = math.min(predictions.length - 1, i + windowSize ~/ 2);
      final window = predictions.sublist(start, end + 1);

      final numClasses = window.first.length;
      final voteCounts = List.generate(numClasses, (_) => 0);

      for (final probabilities in window) {
        final maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
        voteCounts[maxIndex]++;
      }

      final maxVoteCount = voteCounts.reduce(math.max);
      final winnerIndices = [
        for (int j = 0; j < voteCounts.length; j++)
          if (voteCounts[j] == maxVoteCount) j,
      ];

      if (winnerIndices.length == 1) {
        final winnerIndex = winnerIndices.first;
        final votedProbabilities = List<double>.filled(numClasses, 0);
        votedProbabilities[winnerIndex] = 1.0;
        votedPredictions.add(votedProbabilities);
      } else {
        votedPredictions.add(predictions[i]);
      }
    }

    return votedPredictions;
  }

  List<List<double>> _transitionConstraints(
    List<List<double>> predictions,
    int minDuration,
  ) {
    final constrainedPredictions = List<List<double>>.from(predictions);

    for (var i = 1; i < predictions.length; i++) {
      final prevPrediction = predictions[i - 1];
      final currentPrediction = predictions[i];

      if (prevPrediction != currentPrediction) {
        var durationCount = 1;
        var j = i + 1;

        while (j < predictions.length && predictions[j] == currentPrediction) {
          durationCount++;
          j++;
        }

        if (durationCount < minDuration) {
          for (var k = i; k < i + durationCount; k++) {
            constrainedPredictions[k] = prevPrediction;
          }
          i += durationCount - 1;
        } else {
          i += durationCount - 1;
        }
      }
    }

    return constrainedPredictions;
  }

  List<SholatMovementCategory> _getTop2Predictions(List<double> prediction) {
    final entries = <MapEntry<SholatMovementCategory, double>>[];
    for (var i = 0; i < prediction.length; i++) {
      entries.add(MapEntry(SholatMovementCategory.values[i], prediction[i]));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    if (entries.first.value < 0.5) {
      print('[low]:${entries.first.key} $prediction');
    }
    return [entries[0].key, entries[1].key];
  }

  List<List<double>> transitionWeighting({
    required List<List<double>> rawPredictions,
    required List<SholatMovementCategory>? prevPredictions,
    required double weight,
  }) {
    final lastPredictions = prevPredictions ?? [];

    return rawPredictions.map(
      (rawPrediction) {
        final predictionIndex = _argmax(rawPrediction);
        final currentPrediction = _labelCategories[predictionIndex]!;

        if (lastPredictions.isEmpty) {
          lastPredictions.add(currentPrediction);
          return rawPrediction;
        }

        if (currentPrediction == lastPredictions.last) {
          return rawPrediction;
        }

        final Iterable<SholatMovementCategory>? nextMovementCategories;
        if (currentPrediction == SholatMovementCategory.transisi) {
          nextMovementCategories = lastPredictions
              .lastOrNullWhere(
                (pred) => pred != SholatMovementCategory.transisi,
              )
              ?.nextMovementCategoriesBySequence;
        } else {
          nextMovementCategories =
              currentPrediction.nextMovementCategoriesBySequence;
        }

        if (nextMovementCategories == null) {
          lastPredictions.add(currentPrediction);
          return rawPrediction;
        }

        final top2 = _getTop2Predictions(rawPrediction);

        print('[before]: $rawPrediction');
        for (final category in nextMovementCategories) {
          final index = category.index;
          rawPrediction[index] = rawPrediction[index] + weight;
        }
        print('[before1]: $rawPrediction');

        lastPredictions.add(_labelCategories[_argmax(rawPrediction)]!);

        return rawPrediction;
      },
    ).toList();
  }

  int _argmax(List<double> list) => list.indexOf(list.reduce(math.max));

  List<int> _argmaxByAxis(List<List<double>> matrix, int axis) {
    if (axis == 0) {
      final maxIndices = <int>[];
      final numRows = matrix.length;

      for (var row = 0; row < numRows; row++) {
        final rowValues = <double>[];
        for (final col in matrix) {
          rowValues.add(col[row]);
        }
        maxIndices.add(_argmax(rowValues));
      }

      return maxIndices;
    } else {
      return matrix.map(_argmax).toList();
    }
  }

  List<num> _convertInputDType({
    required List<num> data,
    required InputDataType inputDType,
  }) {
    switch (inputDType) {
      case InputDataType.float32:
        return Float32List.fromList(data.map((e) => e.toDouble()).toList());
      case InputDataType.int32:
        return Int32List.fromList(data.map((e) => e.toInt()).toList());
    }
  }

  void setShowBottomPanel({required bool showBottomPanel}) {
    LocalStorageService.setMlModelShowBottomPanel(
      enable: showBottomPanel,
    );
  }

  bool? getShowBottomPanel() {
    return LocalStorageService.getMlModelShowBottomPanel();
  }

  void saveModel(MlModel model) {
    LocalMlModelStorageService.putMlModel(model);
  }

  void dispose() {
    _session?.release();
    _sessionOptions?.release();
    OrtEnv.instance.release();
  }
}

class MajorityVoter {
  MajorityVoter();

  final List<SholatMovementCategory> _predictionWindow = [];

  SholatMovementCategory votedPrediction(
    SholatMovementCategory prediction,
    int threshold,
  ) {
    _predictionWindow.add(prediction);

    if (_predictionWindow.length > threshold) {
      _predictionWindow.removeAt(0);
    }

    final counts = <SholatMovementCategory, int>{};
    for (final prediction in _predictionWindow) {
      counts[prediction] = (counts[prediction] ?? 0) + 1;
    }

    return counts.entries.maxBy((entry) => entry.value)?.key ?? prediction;
  }

  void reset() {
    _predictionWindow.clear();
  }
}
