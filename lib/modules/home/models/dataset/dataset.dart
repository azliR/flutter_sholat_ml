import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Dataset extends Equatable {
  const Dataset({
    required this.x,
    required this.y,
    required this.z,
    this.heartRate,
    this.timestamp,
    this.labelCategory,
    this.label,
  });

  final num x;
  final num y;
  final num z;
  final int? heartRate;
  final Duration? timestamp;
  final String? labelCategory;
  final String? label;

  bool get isLabeled => labelCategory != null && label != null;

  Dataset copyWith({
    num? x,
    num? y,
    num? z,
    int? heartRate,
    Duration? timestamp,
    String? labelCategory,
    String? label,
  }) {
    return Dataset(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      heartRate: heartRate ?? this.heartRate,
      timestamp: timestamp ?? this.timestamp,
      labelCategory: labelCategory ?? this.labelCategory,
      label: label ?? this.label,
    );
  }

  @override
  List<Object?> get props =>
      [x, y, z, heartRate, timestamp, labelCategory, label];
}
