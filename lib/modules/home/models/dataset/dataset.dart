import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Dataset extends Equatable {
  const Dataset({
    required this.x,
    required this.y,
    required this.z,
    this.timestamp,
    this.labelCategory,
    this.label,
  });

  final num x;
  final num y;
  final num z;
  final Duration? timestamp;
  final String? labelCategory;
  final String? label;

  bool get isLabeled => labelCategory != null && label != null;

  Dataset copyWith({
    num? x,
    num? y,
    num? z,
    Duration? timestamp,
    String? labelCategory,
    String? label,
  }) {
    return Dataset(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      timestamp: timestamp ?? this.timestamp,
      labelCategory: labelCategory ?? this.labelCategory,
      label: label ?? this.label,
    );
  }

  @override
  List<Object?> get props => [x, y, z, timestamp, labelCategory, label];
}
