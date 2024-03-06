import 'dart:math';

import 'package:flutter_sholat_ml/features/home/models/dataset/dataset_prop.dart';
import 'package:hive/hive.dart';

class LocalDatasetStorageService {
  static const String kBox = 'datasets_box';
  static final _box = Hive.box<DatasetProp>(name: kBox);

  static int get datasetLength => _box.length;

  static List<DatasetProp> getDatasetRange(int start, int end) {
    if (_box.length == 0) {
      return [];
    }
    final keys = _box.keys.toList()
      ..sort((previous, current) => current.compareTo(previous));
    final keyRange =
        keys.getRange(min(start, keys.length), min(end, keys.length));
    return _box.getAll(keyRange).cast<DatasetProp>();
  }

  static void putDataset(DatasetProp datasetProp) {
    return _box.put(datasetProp.id, datasetProp);
  }

  static bool deleteDataset(String key) {
    return _box.delete(key);
  }
}
