import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/enums/dataset_prop_version.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';

@immutable
class DatasetProp extends Equatable {
  DatasetProp({
    required this.id,
    required this.hasEvaluated,
    required this.datasetVersion,
    required this.createdAt,
    this.csvUrl,
    this.videoUrl,
    this.thumbnailUrl,
  }) : datasetPropVersion = DatasetPropVersion.values.last;

  factory DatasetProp.fromJson(Map<String, dynamic> json) {
    final propVersion = json['dataset_prop_version'] == null
        ? DatasetPropVersion.v1
        : DatasetPropVersion.fromValue(json['dataset_prop_version'] as int);

    switch (propVersion) {
      // Prop v1 and v2 is backward compatible
      case DatasetPropVersion.v1:
      case DatasetPropVersion.v2:
        return DatasetProp._(
          id: json['dir_name'] as String,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          hasEvaluated: false,
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt:
              DateTime.tryParse(json['dir_name'] as String) ?? DateTime.now(),
        );
      case DatasetPropVersion.v3:
      case DatasetPropVersion.v4:
        return DatasetProp._(
          id: json['id'] as String,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          hasEvaluated: json['has_evaluated'] as bool? ?? false,
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt: DateTime.parse(json['created_at'] as String),
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
      // Prop v1 and v2 is backward compatible
      case DatasetPropVersion.v1:
      case DatasetPropVersion.v2:
        return DatasetProp._(
          id: id,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          hasEvaluated: false,
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt:
              (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      case DatasetPropVersion.v3:
      case DatasetPropVersion.v4:
        return DatasetProp._(
          id: id,
          csvUrl: json['csv_url'] as String?,
          videoUrl: json['video_url'] as String?,
          thumbnailUrl: json['thumbnail_url'] as String?,
          hasEvaluated: json['has_evaluated'] as bool? ?? false,
          datasetVersion: json['dataset_version'] == null
              ? DatasetVersion.v1
              : DatasetVersion.fromValue(json['dataset_version'] as int),
          datasetPropVersion: propVersion,
          createdAt: (json['created_at'] as Timestamp).toDate(),
        );
    }
  }

  const DatasetProp._({
    required this.id,
    required this.hasEvaluated,
    required this.datasetVersion,
    required this.datasetPropVersion,
    required this.createdAt,
    this.csvUrl,
    this.videoUrl,
    this.thumbnailUrl,
  });

  final String id;
  final String? csvUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool hasEvaluated;
  final DatasetVersion datasetVersion;
  final DatasetPropVersion datasetPropVersion;
  final DateTime createdAt;

  bool get isSubmitted => csvUrl != null && videoUrl != null;

  DatasetProp copyWith({
    String? id,
    String? csvUrl,
    String? videoUrl,
    String? thumbnailUrl,
    bool? hasEvaluated,
    DatasetVersion? datasetVersion,
    DatasetPropVersion? datasetPropVersion,
    DateTime? createdAt,
  }) {
    return DatasetProp._(
      id: id ?? this.id,
      csvUrl: csvUrl ?? this.csvUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      hasEvaluated: hasEvaluated ?? this.hasEvaluated,
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
      'has_evaluated': hasEvaluated,
      'dataset_version': datasetVersion.value,
      'dataset_prop_version': DatasetPropVersion.values.last.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return <String, dynamic>{
      'csv_url': csvUrl,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'has_evaluated': hasEvaluated,
      'dataset_version': datasetVersion.value,
      'dataset_prop_version': DatasetPropVersion.values.last.value,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        csvUrl,
        videoUrl,
        thumbnailUrl,
        hasEvaluated,
        datasetVersion,
        datasetPropVersion,
        createdAt,
      ];
}
