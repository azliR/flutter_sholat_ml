import 'package:equatable/equatable.dart';
import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';

class MlModelConfig extends Equatable {
  const MlModelConfig({
    required this.enableTeacherForcing,
    required this.batchSize,
    required this.windowSize,
    required this.numberOfFeatures,
    required this.inputDataType,
  });

  final bool enableTeacherForcing;
  final int batchSize;
  final int windowSize;
  final int numberOfFeatures;
  final InputDataType inputDataType;

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
    );
  }

  MlModelConfig copyWith({
    bool? enableTeacherForcing,
    int? batchSize,
    int? windowSize,
    int? numberOfFeatures,
    InputDataType? inputDataType,
  }) {
    return MlModelConfig(
      enableTeacherForcing: enableTeacherForcing ?? this.enableTeacherForcing,
      batchSize: batchSize ?? this.batchSize,
      windowSize: windowSize ?? this.windowSize,
      numberOfFeatures: numberOfFeatures ?? this.numberOfFeatures,
      inputDataType: inputDataType ?? this.inputDataType,
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
    ];
  }
}
