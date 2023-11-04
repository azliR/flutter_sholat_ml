import 'dart:math';

import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:hive/hive.dart';

class LocalDatasetStorageService {
  static const String kBox = 'datasets_box';
  static final _box = Hive.box<DatasetProp>(name: kBox);

  static void putAll(Map<String, DatasetProp> datasetProps) {
    // _box.clear();
    _box.putAll(datasetProps);
  }

  static int get datasetLength => _box.length;

  static List<DatasetProp> getDatasetRange(int start, int end) {
    if (_box.length == 0) {
      return [];
    }
    return _box.getRange(min(start, _box.length), min(end, _box.length));
  }

  static void putDataset(String key, DatasetProp dataset) {
    _box.put(key, dataset);
  }

  static void deleteDataset(String key) {
    _box.delete(key);
  }
}
