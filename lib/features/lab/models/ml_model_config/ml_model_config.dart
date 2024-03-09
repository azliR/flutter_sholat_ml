import 'package:equatable/equatable.dart';
import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';

enum Smoothing { movingAverage, exponentialSmoothing }

enum Filtering { medianFilter, lowPassFilter }

enum TemporalConsistencyEnforcement { majorityVoting, transitionConstraints }

class MlModelConfig extends Equatable {
  const MlModelConfig({
    required this.enableTeacherForcing,
    required this.batchSize,
    required this.windowSize,
    required this.numberOfFeatures,
    required this.inputDataType,
    required this.smoothings,
    required this.filterings,
    required this.temporalConsistencyEnforcements,
  });

  final bool enableTeacherForcing;
  final int batchSize;
  final int windowSize;
  final int numberOfFeatures;
  final InputDataType inputDataType;
  final Set<Smoothing> smoothings;
  final Set<Filtering> filterings;
  final Set<TemporalConsistencyEnforcement> temporalConsistencyEnforcements;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enableTeacherForcing': enableTeacherForcing,
      'batchSize': batchSize,
      'windowSize': windowSize,
      'numberOfFeatures': numberOfFeatures,
      'inputDataType': inputDataType.index,
    };
  }

  factory MlModelConfig.fromJson(Map<String, dynamic> map) {
    return MlModelConfig(
      enableTeacherForcing: (map['enableTeacherForcing'] ?? false) as bool,
      batchSize: (map['batchSize'] ?? 0) as int,
      windowSize: (map['windowSize'] ?? 0) as int,
      numberOfFeatures: (map['numberOfFeatures'] ?? 0) as int,
      inputDataType: InputDataType.values[map['inputDataType'] as int? ?? 0],
      smoothings: (map['smoothings'] as List<int>?)
              ?.map((e) => Smoothing.values[e])
              .toSet() ??
          {},
      filterings: (map['filterings'] as List<int>?)
              ?.map((e) => Filtering.values[e])
              .toSet() ??
          {},
      temporalConsistencyEnforcements:
          (map['temporalConsistencyEnforcements'] as List<int>?)
                  ?.map((e) => TemporalConsistencyEnforcement.values[e])
                  .toSet() ??
              {},
    );
  }

  MlModelConfig copyWith({
    bool? enableTeacherForcing,
    int? batchSize,
    int? windowSize,
    int? numberOfFeatures,
    InputDataType? inputDataType,
    Set<Smoothing>? smoothings,
    Set<Filtering>? filterings,
    Set<TemporalConsistencyEnforcement>? temporalConsistencyEnforcements,
  }) {
    return MlModelConfig(
      enableTeacherForcing: enableTeacherForcing ?? this.enableTeacherForcing,
      batchSize: batchSize ?? this.batchSize,
      windowSize: windowSize ?? this.windowSize,
      numberOfFeatures: numberOfFeatures ?? this.numberOfFeatures,
      inputDataType: inputDataType ?? this.inputDataType,
      smoothings: smoothings ?? this.smoothings,
      filterings: filterings ?? this.filterings,
      temporalConsistencyEnforcements: temporalConsistencyEnforcements ??
          this.temporalConsistencyEnforcements,
    );
  }

  @override
  List<Object> get props {
    return [
      enableTeacherForcing,
      batchSize,
      windowSize,
      numberOfFeatures,
      inputDataType,
      smoothings,
      filterings,
      temporalConsistencyEnforcements,
    ];
  }
}
