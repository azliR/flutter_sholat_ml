import 'dart:math';

import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:hive/hive.dart';

class LocalMlModelStorageService {
  static const String kBox = 'ml_models_box';
  static final _box = Hive.box<MlModel>(name: kBox);

  static int get mlModelLength => _box.length;

  static List<MlModel> getMlModelRange(int start, int end) {
    if (_box.length == 0) {
      return [];
    }
    final keys = _box.keys.toList()
      ..sort((previous, current) => current.compareTo(previous));
    final keyRange =
        keys.getRange(min(start, keys.length), min(end, keys.length));
    return _box.getAll(keyRange).cast<MlModel>();
  }

  static void putMlModel(MlModel mlModel) {
    return _box.put(mlModel.id, mlModel);
  }

  static bool deleteMlModel(String key) {
    return _box.delete(key);
  }
}
