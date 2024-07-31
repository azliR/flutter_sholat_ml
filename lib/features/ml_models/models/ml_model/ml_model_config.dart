import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/post_processing/temporal_consistency_enforcements.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ml_model_config.freezed.dart';
part 'ml_model_config.g.dart';

enum InputDataType {
  float32,
  int32,
}

@freezed
class MlModelConfig with _$MlModelConfig {
  const factory MlModelConfig({
    required bool enableTeacherForcing,
    required int batchSize,
    required int windowSize,
    required int numberOfFeatures,
    required InputDataType inputDataType,
    // required Set<Smoothing> smoothings,
    // required Set<Filtering> filterings,
    required Set<TemporalConsistencyEnforcement>
        temporalConsistencyEnforcements,
    // @Default({}) Set<Weighting> weightings,
    @Default(10) int stepSize,
  }) = _MlModelConfig;

  factory MlModelConfig.fromJson(Map<String, dynamic> json) =>
      _$MlModelConfigFromJson(json);
}
