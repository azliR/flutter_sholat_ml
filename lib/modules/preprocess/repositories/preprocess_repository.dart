import 'dart:io';

import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/preprocess/preprocess.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

class PreprocessRepository {
  Future<(Failure?, Preprocess?)> getPreprocess(String path) async {
    try {
      final directory = Directory(path);
      final entities = await directory.list().toList();
      final csvPath = entities
          .firstWhere((entity) => entity.path.split('.').last == 'csv')
          .path;
      final videoPath = entities
          .firstWhere((entity) => entity.path.split('.').last == 'mp4')
          .path;

      final preprocess = Preprocess(
        csvPath: csvPath,
        videoPath: videoPath,
      );
      return (null, preprocess);
    } catch (e, stackTrace) {
      const message = 'Failed getting dataset file paths';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<Dataset>?)> readDatasets(String path) async {
    try {
      final datasetList = await File(path).readAsLines();
      final datasets = datasetList.map((dataset) {
        final split = dataset.split(',');
        return Dataset(
          timestamp: Duration(milliseconds: int.parse(split[0])),
          x: double.parse(split[1]),
          y: double.parse(split[2]),
          z: double.parse(split[3]),
        );
      }).toList();
      return (null, datasets);
    } catch (e, stackTrace) {
      const message = 'Failed getting dataset file paths';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
