import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum DeviceLocation {
  leftWrist,
  rightWrist;

  String get name {
    switch (this) {
      case DeviceLocation.leftWrist:
        return 'Left wrist';
      case DeviceLocation.rightWrist:
        return 'Right wrist';
    }
  }

  String get code {
    switch (this) {
      case DeviceLocation.leftWrist:
        return 'left_wrist';
      case DeviceLocation.rightWrist:
        return 'right_wrist';
    }
  }

  static DeviceLocation fromCode(String name) {
    switch (name) {
      case 'left_wrist':
        return DeviceLocation.leftWrist;
      case 'right_wrist':
        return DeviceLocation.rightWrist;
      default:
        throw ArgumentError('Invalid device location name: $name');
    }
  }
}

@immutable
class Dataset extends Equatable {
  const Dataset({
    required this.x,
    required this.y,
    required this.z,
    required this.deviceLocation,
    this.heartRate,
    this.timestamp,
    this.labelCategory,
    this.label,
    this.note,
  });

  factory Dataset.fromCsv(String csv) {
    final split = csv.split(',');

    return Dataset(
      timestamp: Duration(milliseconds: int.parse(split[0])),
      x: int.parse(split[1]),
      y: int.parse(split[2]),
      z: int.parse(split[3]),
      heartRate: int.tryParse(split[4]),
      deviceLocation: DeviceLocation.fromCode(split[5]),
      labelCategory:
          split.elementAtOrNull(6)?.isNotEmpty ?? false ? split[6] : null,
      label: split.elementAtOrNull(7)?.isNotEmpty ?? false ? split[7] : null,
      note: split.elementAtOrNull(8)?.isNotEmpty ?? false ? split[8] : null,
    );
  }

  final num x;
  final num y;
  final num z;
  final int? heartRate;
  final DeviceLocation deviceLocation;
  final Duration? timestamp;
  final String? labelCategory;
  final String? label;
  final String? note;

  bool get isLabeled => labelCategory != null && label != null;

  Dataset copyWith({
    num? x,
    num? y,
    num? z,
    int? heartRate,
    DeviceLocation? deviceLocation,
    Duration? timestamp,
    String? labelCategory,
    String? label,
    String? note,
  }) {
    return Dataset(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      heartRate: heartRate ?? this.heartRate,
      deviceLocation: deviceLocation ?? this.deviceLocation,
      timestamp: timestamp ?? this.timestamp,
      labelCategory: labelCategory ?? this.labelCategory,
      label: label ?? this.label,
      note: note ?? this.note,
    );
  }

  String toCsv() {
    final timestamp = this.timestamp!.inMilliseconds.toString();
    final x = this.x.toString();
    final y = this.y.toString();
    final z = this.z.toString();
    final heartRate = this.heartRate ?? '';
    final deviceLocation = this.deviceLocation.code;
    final labelCategory = this.labelCategory ?? '';
    final label = this.label ?? '';
    final note = this.note ?? '';

    return '$timestamp,$x,$y,$z,$heartRate,'
        '$deviceLocation,$labelCategory,$label,$note\n';
  }

  @override
  List<Object?> get props => [
        x,
        y,
        z,
        heartRate,
        deviceLocation,
        timestamp,
        labelCategory,
        label,
        note,
      ];
}
