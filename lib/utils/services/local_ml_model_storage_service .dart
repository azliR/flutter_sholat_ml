import 'dart:math';

import 'package:dartx/dartx_io.dart';
import 'package:flutter_sholat_ml/features/ml_models/blocs/ml_models/ml_models_notifer.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:hive/hive.dart';

class LocalMlModelStorageService {
  static const String kBox = 'ml_models_box';
  static final _box = Hive.box<MlModel>(name: kBox);

  static int get mlModelLength => _box.length;

  static Future<List<MlModel>> getMlModelRange(
    int start,
    int end, {
    required SortType sortType,
    required SortDirection sortDirection,
  }) async {
    if (_box.length == 0) {
      return [];
    }

    final keys = _box.keys.toList();
    final data = _box.getAll(keys).cast<MlModel>().sortedWith(
      (a, b) {
        int comparison;
        switch (sortType) {
          case SortType.modelName:
            comparison = a.name.compareTo(b.name);
          case SortType.lastUpdated:
            comparison = a.updatedAt.compareTo(b.updatedAt);
        }

        if (sortDirection == SortDirection.descending) {
          comparison = -comparison;
        }

        return comparison;
      },
    ).getRange(min(start, keys.length), min(end, keys.length));

    return data.toList().cast();
  }

  static void putMlModel(MlModel model) {
    return _box.put(model.id, model);
  }

  static bool deleteMlModel(MlModel model) {
    return _box.delete(model.id);
  }
}
