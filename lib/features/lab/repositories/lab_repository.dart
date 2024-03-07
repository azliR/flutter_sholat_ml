import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:onnxruntime/onnxruntime.dart';

class LabRepository {
  OrtSession? _session;

  Future<void> initialiseOrt(String path) async {
    OrtEnv.instance.init();
    final sessionOptions = OrtSessionOptions();
    _session = OrtSession.fromFile(File(path), sessionOptions);
  }

  (Failure?, bool) predict({
    required String path,
    required Float32List data,
    required void Function(String label) onPredict,
  }) {
    try {
      EasyThrottle.throttle('predict', const Duration(seconds: 5), () async {
        if (_session == null) {
          await initialiseOrt(path);
        }

        final inputOrt =
            OrtValueTensor.createTensorWithDataList(data, [1, 40, 3]);

        final inputs = {'x': inputOrt};
        final runOptions = OrtRunOptions();
        final outputs = await _session!.runAsync(runOptions, inputs);

        final yPred = outputs![0]!.value! as List<List<double>>;
        log(yPred.toString());

        final maxIndex = _argmax(yPred[0]);
        log(maxIndex.toString());

        final labels = {
          0: 'sujud',
          1: 'iktidal',
          2: 'transisi',
          3: 'takbir',
          4: 'ruku',
          5: 'berdiri',
          6: 'duduk',
          7: 'qunut',
        };

        onPredict(labels[maxIndex]!);

        inputOrt.release();
        runOptions.release();

        for (final element in outputs) {
          element?.release();
        }
      });
      return (null, true);
    } catch (e, stackTrace) {
      const message = 'Failed to predict';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, false);
    }
  }

  int _argmax(List<double> list) {
    var maxValue = double.negativeInfinity;
    var maxIndex = 0;

    for (var i = 0; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  List<int> argmaxByAxis(List<List<double>> matrix, int axis) {
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

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
