import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:onnxruntime/onnxruntime.dart';

class LabRepository {
  OrtSession? _session;
  Future<void> Function()? _predictFuture;

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

  Future<void> initialiseOrt(String path) async {
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromFile(File(path), sessionOptions);
  }

  bool predict({
    required String path,
    required List<num> data,
    required List<num>? previousLabels,
    required InputDataType inputDataType,
    required int batchSize,
    required int windowSize,
    required int numberOfFeatures,
    required void Function(List<SholatMovementCategory> labelCategories)
        onPredict,
    required void Function(Failure failure) onError,
  }) {
    if (_predictFuture != null) return false;

    _predictFuture = () async {
      try {
        if (_session == null) {
          await initialiseOrt(path);
        }

        final inputOrt = OrtValueTensor.createTensorWithDataList(
          _convertInputDType(data: data, inputDType: inputDataType),
          [batchSize, windowSize, numberOfFeatures],
        );

        OrtValueTensor? teacherInputOrt;
        final Map<String, OrtValueTensor> inputs;

        if (previousLabels != null) {
          final numberOfClasses = _labelCategories.length;

          teacherInputOrt = OrtValueTensor.createTensorWithDataList(
            _convertInputDType(data: previousLabels, inputDType: inputDataType),
            [batchSize, numberOfClasses],
          );

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
        final smoothedPred = movingAverageSmoothing(yPred, windowSize);
        final indexes = argmaxByAxis(smoothedPred, windowSize);
        // log(indexes.toString());
        // log(yPred.toString());
        // log(movingAverageSmoothing(yPred[0], windowSize).toString());
        onPredict(indexes.map((i) => _labelCategories[i]!).toList());
        // onPredict(
        //   applyTransitionConstraints(yPred, 10, windowSize)
        //       .map((i) => _labelCategories[i]!)
        //       .toList(),
        // );

        inputOrt.release();
        runOptions.release();

        for (final element in outputs) {
          element?.release();
        }
      } catch (e, stackTrace) {
        const message = 'Failed to predict';
        final failure = Failure(message, error: e, stackTrace: stackTrace);
        onError(failure);
      } finally {
        _predictFuture = null;
      }
    };
    _predictFuture?.call();

    return true;
  }

  final predictionWindow = <int>[];

  List<int> applyTransitionConstraints(
    List<List<double>> predictions,
    int minDuration,
    int windowSize,
  ) {
    final classLabels = <int>[];
    int? prevActivity;
    var activityDuration = 0;

    for (var i = 0; i < predictions.length; i++) {
      final probabilities = predictions[i];
      final currentActivity =
          probabilities.indexOf(probabilities.reduce(math.max));

      // Add the current prediction to the window
      predictionWindow.add(currentActivity);

      // Remove the oldest prediction from the window if it exceeds the window size
      if (predictionWindow.length > windowSize) {
        predictionWindow.removeAt(0);
      }

      // Use the majority vote from the window as the current activity
      final windowActivities = predictionWindow.toList();
      final majVote = _getMajorityVote(windowActivities);

      if (majVote != prevActivity) {
        activityDuration = 1;
        prevActivity = majVote;

        if (activityDuration < minDuration) {
          classLabels.addAll(List.filled(activityDuration, prevActivity));
        } else {
          classLabels.addAll(
            List.filled(activityDuration - minDuration, prevActivity),
          );
        }
      } else {
        activityDuration++;
      }

      classLabels.add(majVote);
    }

    if (activityDuration < minDuration) {
      classLabels.addAll(List.filled(activityDuration, prevActivity!));
    } else {
      classLabels
          .addAll(List.filled(activityDuration - minDuration, prevActivity!));
    }

    return classLabels;
  }

  int _getMajorityVote(List<int> activities) {
    final counts = <int, int>{};
    for (final activity in activities) {
      counts[activity] = (counts[activity] ?? 0) + 1;
    }

    var maxCount = 0;
    var maxActivity = -1;
    for (final entry in counts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxActivity = entry.key;
      }
    }

    return maxActivity;
  }

  List<List<num>> movingAverageSmoothing(
    List<List<num>> predictions,
    int windowSize,
  ) {
    final smoothedPredictions = <List<num>>[];
    for (var i = 0; i < predictions.length; i++) {
      final smoothedProbabilities =
          List<num>.filled(predictions[i].length, 0.0);
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

  List<List<double>> majorityVoting(
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
        final votedProbabilities = List.filled(numClasses, 0.0);
        votedProbabilities[winnerIndex] = 1.0;
        votedPredictions.add(votedProbabilities);
      } else {
        votedPredictions.add(predictions[i]);
      }
    }

    return votedPredictions;
  }

  int _argmax(List<num> list) {
    var maxValue = -1 as num;
    var maxIndex = 0;

    for (var i = 0; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  List<int> argmaxByAxis(List<List<num>> matrix, int axis) {
    if (axis == 0) {
      final maxIndices = <int>[];
      final numRows = matrix.length;

      for (var row = 0; row < numRows; row++) {
        final rowValues = <num>[];
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
    LocalStorageService.setLabShowBottomPanel(
      enable: showBottomPanel,
    );
  }

  bool? getShowBottomPanel() {
    return LocalStorageService.getLabShowBottomPanel();
  }

  void setInputDataType(InputDataType type) {
    LocalStorageService.setLabInputDataType(type);
  }

  InputDataType getInputDataType() {
    return LocalStorageService.getLabInputDataType();
  }

  void setEnableTeacherForcing({required bool enableTeacherForcing}) {
    LocalStorageService.setLabEnableTeacherForcing(
      enable: enableTeacherForcing,
    );
  }

  bool? getEnableTeacherForcing() {
    return LocalStorageService.getLabEnableTeacherForcing();
  }

  void setBatchSize(int size) {
    LocalStorageService.setLabBatchSize(size);
  }

  int getBatchSize() {
    return LocalStorageService.getLabBatchSize();
  }

  void setWindowSize(int size) {
    LocalStorageService.setLabWindowSize(size);
  }

  int getWindowSize() {
    return LocalStorageService.getLabWindowSize();
  }

  void setNumberOfFeatures(int step) {
    LocalStorageService.setLabNumberOfFeatures(step);
  }

  int getNumberOfFeatures() {
    return LocalStorageService.getLabNumberOfFeatures();
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
