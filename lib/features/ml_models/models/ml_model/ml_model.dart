import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ml_model.freezed.dart';
part 'ml_model.g.dart';

@freezed
class MlModel with _$MlModel {
  const factory MlModel({
    required String id,
    required String name,
    required String path,
    required String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(
      MlModelConfig(
        enableTeacherForcing: false,
        batchSize: 1,
        windowSize: 20,
        numberOfFeatures: 3,
        inputDataType: InputDataType.float32,
        // smoothings: {},
        // filterings: {},
        temporalConsistencyEnforcements: {},
      ),
    )
    MlModelConfig config,
  }) = _MlModel;

  factory MlModel.fromJson(Map<String, dynamic> json) =>
      _$MlModelFromJson(json);
}
