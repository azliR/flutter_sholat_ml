import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/enums/dataset_prop_version.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';
import 'package:flutter_sholat_ml/enums/device_location.dart';

@immutable
class DatasetProp extends Equatable {
  DatasetProp({
    required this.id,
    required this.isCompressed,
    required this.hasEvaluated,
    required this.deviceLocation,
    required this.datasetVersion,
    required this.createdAt,
    this.csvUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.isSyncedWithCloud,
  }) : datasetPropVersion = DatasetPropVersion.values.last;

  factory DatasetProp.fromJson(Map<String, dynamic> json) {
    final propVersion = json['dataset_prop_version'] == null
        ? DatasetPropVersion.v1
        : DatasetPropVersion.fromValue(json['dataset_prop_version'] as int);

    switch (propVersion) {
      case DatasetPropVersion.v1:
        return DatasetProp._(
          // v1
          id: json['dir_name'] as String,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          // new
          isCompressed: false,
          hasEvaluated: false,
          deviceLocation: DeviceLocation.leftWrist,
          datasetPropVersion: propVersion,
          createdAt:
              DateTime.tryParse(json['dir_name'] as String) ?? DateTime.now(),
        );
      case DatasetPropVersion.v2:
        return DatasetProp._(
          // v2
          id: json['dir_name'] as String,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          // new
          isSyncedWithCloud: json['csv_url'] != null &&
              json['video_url'] != null &&
              json['thumbnail_url'] != null,
          isCompressed: false,
          hasEvaluated: false,
          deviceLocation: DeviceLocation.leftWrist,
          createdAt:
              DateTime.tryParse(json['dir_name'] as String) ?? DateTime.now(),
        );
      case DatasetPropVersion.v3:
        return DatasetProp._(
          // v3
          id: json['id'] as String,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt:
              DateTime.tryParse(json['created_at'] as String) ?? DateTime.now(),
          // new
          isSyncedWithCloud: json['csv_url'] != null &&
              json['video_url'] != null &&
              json['thumbnail_url'] != null,
          isCompressed: false,
          hasEvaluated: false,
          deviceLocation: DeviceLocation.leftWrist,
        );
      case DatasetPropVersion.v4:
        return DatasetProp._(
          id: json['id'] as String,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          isSyncedWithCloud: json['is_synced_with_cloud'] as bool? ?? false,
          isCompressed: json['is_compressed'] as bool? ?? false,
          hasEvaluated: json['has_evaluated'] as bool? ?? false,
          deviceLocation: json['device_location'] == null
              ? DeviceLocation.leftWrist
              : DeviceLocation.fromValue(json['device_location'] as String),
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt:
              DateTime.tryParse(json['created_at'] as String) ?? DateTime.now(),
        );
    }
  }

  factory DatasetProp.fromFirestoreJson(
    Map<String, dynamic> json,
    String id,
  ) {
    final propVersion = json['dataset_prop_version'] == null
        ? DatasetPropVersion.v1
        : DatasetPropVersion.fromValue(json['dataset_prop_version'] as int);

    switch (propVersion) {
      case DatasetPropVersion.v1:
        return DatasetProp._(
          // v1
          id: id,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          datasetVersion:
              DatasetVersion.fromValue(json['dataset_version'] as int),
          // new
          isCompressed: false,
          hasEvaluated: false,
          deviceLocation: DeviceLocation.leftWrist,
          datasetPropVersion: propVersion,
          createdAt:
              DateTime.tryParse(json['dir_name'] as String) ?? DateTime.now(),
        );
      case DatasetPropVersion.v2:
        return DatasetProp._(
          // v2
          id: id,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          datasetVersion:
              DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          // new
          isSyncedWithCloud: json['csv_url'] != null &&
              json['video_url'] != null &&
              json['thumbnail_url'] != null,
          isCompressed: false,
          hasEvaluated: false,
          deviceLocation: DeviceLocation.leftWrist,
          createdAt:
              DateTime.tryParse(json['dir_name'] as String) ?? DateTime.now(),
        );
      case DatasetPropVersion.v3:
        return DatasetProp._(
          // v3
          id: id,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          datasetVersion:
              DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt: (json['created_at'] as Timestamp).toDate(),
          // new
          isSyncedWithCloud: json['csv_url'] != null &&
              json['video_url'] != null &&
              json['thumbnail_url'] != null,
          isCompressed: false,
          hasEvaluated: false,
          deviceLocation: DeviceLocation.leftWrist,
        );
      case DatasetPropVersion.v4:
        return DatasetProp._(
          id: id,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          isSyncedWithCloud: true, // default true when fetching from firestore
          isCompressed: json['is_compressed'] as bool,
          hasEvaluated: json['has_evaluated'] as bool,
          deviceLocation:
              DeviceLocation.fromValue(json['device_location'] as String),
          datasetVersion:
              DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt: (json['created_at'] as Timestamp).toDate(),
        );
    }
  }

  const DatasetProp._({
    required this.id,
    required this.isCompressed,
    required this.hasEvaluated,
    required this.deviceLocation,
    required this.datasetVersion,
    required this.datasetPropVersion,
    required this.createdAt,
    this.csvUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.isSyncedWithCloud,
  });

  final String id;
  final String? csvUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool? isSyncedWithCloud;
  final bool isCompressed;
  final bool hasEvaluated;
  final DeviceLocation deviceLocation;
  final DatasetVersion datasetVersion;
  final DatasetPropVersion datasetPropVersion;
  final DateTime createdAt;

  bool get isUploaded => csvUrl != null && videoUrl != null;

  DatasetProp copyWith({
    String? id,
    String? csvUrl,
    String? videoUrl,
    String? thumbnailUrl,
    bool? isSyncedWithCloud,
    bool? isCompressed,
    bool? hasEvaluated,
    DeviceLocation? deviceLocation,
    DatasetVersion? datasetVersion,
    DatasetPropVersion? datasetPropVersion,
    DateTime? createdAt,
  }) {
    return DatasetProp._(
      id: id ?? this.id,
      csvUrl: csvUrl ?? this.csvUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isSyncedWithCloud: isSyncedWithCloud ?? this.isSyncedWithCloud,
      isCompressed: isCompressed ?? this.isCompressed,
      hasEvaluated: hasEvaluated ?? this.hasEvaluated,
      deviceLocation: deviceLocation ?? this.deviceLocation,
      datasetVersion: datasetVersion ?? this.datasetVersion,
      datasetPropVersion: datasetPropVersion ?? this.datasetPropVersion,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'csv_url': csvUrl,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'is_synced_with_cloud':
          datasetPropVersion == DatasetPropVersion.values.last
              ? isSyncedWithCloud
              : null,
      'is_compressed': isCompressed,
      'has_evaluated': hasEvaluated,
      'device_location': deviceLocation.value,
      'dataset_version': datasetVersion.value,
      'dataset_prop_version': DatasetPropVersion.values.last.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return toJson()
      ..removeWhere(
        (key, value) => key == 'id' || key == 'is_synced_with_cloud',
      )
      ..['created_at'] = Timestamp.fromDate(createdAt);
  }

  @override
  List<Object?> get props => [
        id,
        csvUrl,
        videoUrl,
        thumbnailUrl,
        isSyncedWithCloud,
        isCompressed,
        hasEvaluated,
        deviceLocation,
        datasetVersion,
        datasetPropVersion,
        createdAt,
      ];
}
