import 'package:dartx/dartx_io.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/enums/sholat_noise_movement.dart';

@immutable
class DataItem extends Equatable {
  const DataItem({
    required this.x,
    required this.y,
    required this.z,
    this.timestamp,
    this.heartRate,
    this.movementSetId,
    this.note,
    this.labelCategory,
    this.label,
    this.noiseMovement,
  });

  factory DataItem.fromCsv(
    String csv, {
    required DatasetVersion version,
  }) {
    final split = csv.split(',');

    switch (version) {
      case DatasetVersion.v1:
        return DataItem(
          timestamp: Duration(milliseconds: int.parse(split[0])),
          x: int.parse(split[1]),
          y: int.parse(split[2]),
          z: int.parse(split[3]),
          heartRate: int.tryParse(split[4]),
          // deviceLocation: DeviceLocation.fromValue(split[5]),
          labelCategory: split.elementAtOrNull(6).isNotNullOrBlank
              ? SholatMovementCategory.fromValue(split[6])
              : null,
          label: split.elementAtOrNull(7).isNotNullOrBlank
              ? SholatMovement.fromValue(split[7])
              : null,
        );
      case DatasetVersion.v2:
        return DataItem(
          timestamp: Duration(milliseconds: int.parse(split[0])),
          x: int.parse(split[1]),
          y: int.parse(split[2]),
          z: int.parse(split[3]),
          heartRate: int.tryParse(split[4]),
          movementSetId:
              split.elementAtOrNull(5).isNotNullOrBlank ? split[5] : null,
          // deviceLocation: DeviceLocation.fromValue(split[6]),
          note: split.elementAtOrNull(7).isNotNullOrBlank ? split[7] : null,
          labelCategory: split.elementAtOrNull(8).isNotNullOrBlank
              ? SholatMovementCategory.fromValue(split[8])
              : null,
          label: split.elementAtOrNull(9).isNotNullOrBlank
              ? SholatMovement.fromValue(split[9])
              : null,
        );
      case DatasetVersion.v3:
        return DataItem(
          timestamp: Duration(milliseconds: int.parse(split[0])),
          x: int.parse(split[1]),
          y: int.parse(split[2]),
          z: int.parse(split[3]),
          heartRate: int.tryParse(split[4]),
          movementSetId:
              split.elementAtOrNull(5).isNotNullOrBlank ? split[5] : null,
          // deviceLocation: DeviceLocation.fromValue(split[6]),
          note: split.elementAtOrNull(7).isNotNullOrBlank ? split[7] : null,
          labelCategory: split.elementAtOrNull(8).isNotNullOrBlank
              ? SholatMovementCategory.fromValue(split[8])
              : null,
          label: split.elementAtOrNull(9).isNotNullOrBlank
              ? SholatMovement.fromValue(split[9])
              : null,
          noiseMovement: split.elementAtOrNull(10).isNotNullOrBlank
              ? SholatNoiseMovement.fromValue(split[10])
              : null,
        );
      case DatasetVersion.v4:
        return DataItem(
          timestamp: Duration(milliseconds: int.parse(split[0])),
          x: int.parse(split[1]),
          y: int.parse(split[2]),
          z: int.parse(split[3]),
          heartRate: int.tryParse(split[4]),
          movementSetId:
              split.elementAtOrNull(5).isNotNullOrBlank ? split[5] : null,
          note: split.elementAtOrNull(6).isNotNullOrBlank ? split[6] : null,
          labelCategory: split.elementAtOrNull(7).isNotNullOrBlank
              ? SholatMovementCategory.fromValue(split[7])
              : null,
          label: split.elementAtOrNull(8).isNotNullOrBlank
              ? SholatMovement.fromValue(split[8])
              : null,
          noiseMovement: split.elementAtOrNull(9).isNotNullOrBlank
              ? SholatNoiseMovement.fromValue(split[9])
              : null,
        );
    }
  }

  final Duration? timestamp;
  final num x;
  final num y;
  final num z;
  final int? heartRate;
  final String? movementSetId;
  final String? note;
  final SholatMovementCategory? labelCategory;
  final SholatMovement? label;
  final SholatNoiseMovement? noiseMovement;

  bool get isLabeled =>
      movementSetId != null && labelCategory != null && label != null;

  DatasetVersion get version => DatasetVersion.values.last;

  DataItem copyWith({
    Duration? timestamp,
    num? x,
    num? y,
    num? z,
    int? heartRate,
    ValueGetter<String?>? movementSetId,
    String? note,
    ValueGetter<SholatMovementCategory?>? labelCategory,
    ValueGetter<SholatMovement?>? label,
    ValueGetter<SholatNoiseMovement?>? noiseMovement,
  }) {
    return DataItem(
      timestamp: timestamp ?? this.timestamp,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      heartRate: heartRate ?? this.heartRate,
      movementSetId:
          movementSetId != null ? movementSetId() : this.movementSetId,
      note: note ?? this.note,
      labelCategory:
          labelCategory != null ? labelCategory() : this.labelCategory,
      label: label != null ? label() : this.label,
      noiseMovement:
          noiseMovement != null ? noiseMovement() : this.noiseMovement,
    );
  }

  String toCsv() {
    final timestamp = this.timestamp!.inMilliseconds.toString();
    final x = this.x.toString();
    final y = this.y.toString();
    final z = this.z.toString();
    final heartRate = this.heartRate ?? '';
    final movementSetId = this.movementSetId ?? '';
    final note = this.note ?? '';
    final labelCategory = this.labelCategory?.value ?? '';
    final label = this.label?.value ?? '';
    final noiseMovement = this.noiseMovement?.value ?? '';

    return '$timestamp,$x,$y,$z,$heartRate,$movementSetId,'
        '$note,$labelCategory,$label,$noiseMovement,\n';
  }

  @override
  List<Object?> get props => [
        timestamp,
        x,
        y,
        z,
        heartRate,
        movementSetId,
        note,
        labelCategory,
        label,
        noiseMovement,
      ];
}
