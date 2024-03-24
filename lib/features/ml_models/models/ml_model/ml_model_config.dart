import 'package:freezed_annotation/freezed_annotation.dart';

part 'ml_model_config.freezed.dart';
part 'ml_model_config.g.dart';

enum InputDataType {
  float32,
  int32,
}

enum Smoothing {
  movingAverage,
  exponentialSmoothing;

  String get name => switch (this) {
        Smoothing.movingAverage => 'Moving Average',
        Smoothing.exponentialSmoothing => 'Exponential Smoothing'
      };
}

enum Filtering {
  medianFilter,
  lowPassFilter;

  String get name => switch (this) {
        Filtering.medianFilter => 'Median Filter',
        Filtering.lowPassFilter => 'Low Pass Filter'
      };
}

enum TemporalConsistencyEnforcement {
  majorityVoting,
  transitionConstraints;

  String get name => switch (this) {
        TemporalConsistencyEnforcement.majorityVoting => 'Majority Voting',
        TemporalConsistencyEnforcement.transitionConstraints =>
          'Transition Constraints'
      };
}

@freezed
class MlModelConfig with _$MlModelConfig {
  const factory MlModelConfig({
    required bool enableTeacherForcing,
    required int batchSize,
    required int windowSize,
    required int numberOfFeatures,
    required InputDataType inputDataType,
    required Set<Smoothing> smoothings,
    required Set<Filtering> filterings,
    required Set<TemporalConsistencyEnforcement>
        temporalConsistencyEnforcements,
    @Default(10) int stepSize,
  }) = _MlModelConfig;

  factory MlModelConfig.fromJson(Map<String, dynamic> json) =>
      _$MlModelConfigFromJson(json);
}
