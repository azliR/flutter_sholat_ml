import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/enums/dataset_prop_version.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';

@immutable
class DatasetProp extends Equatable {
  const DatasetProp({
    required this.dirName,
    required this.datasetVersion,
    required this.datasetPropVersion,
    this.csvUrl,
    this.videoUrl,
    this.thumbnailUrl,
  });

  final String dirName;
  final String? csvUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final DatasetVersion datasetVersion;
  final DatasetPropVersion datasetPropVersion;

  bool get isSubmitted => csvUrl != null && videoUrl != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dir_name': dirName,
      'csv_url': csvUrl,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'dataset_version': datasetVersion.value,
      'dataset_prop_version': datasetPropVersion.value,
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return <String, dynamic>{
      'csv_url': csvUrl,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'dataset_version': datasetVersion.value,
      'dataset_prop_version': datasetPropVersion.value,
    };
  }

  factory DatasetProp.fromJson(Map<String, dynamic> json) {
    return DatasetProp(
      dirName: json['dir_name'] as String,
      csvUrl: json['csv_url'] as String?,
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      datasetVersion: json['dataset_version'] == null
          ? DatasetVersion.v1
          : DatasetVersion.fromValue(json['dataset_version'] as int),
      datasetPropVersion: json['dataset_prop_version'] == null
          ? DatasetPropVersion.v1
          : DatasetPropVersion.fromValue(json['dataset_prop_version'] as int),
    );
  }

  factory DatasetProp.fromFirestoreJson(
    Map<String, dynamic> json,
    String dirName,
  ) {
    return DatasetProp(
      dirName: dirName,
      csvUrl: json['csv_url'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      datasetVersion: DatasetVersion.fromValue(json['dataset_version'] as int),
      datasetPropVersion: DatasetPropVersion.fromValue(
        json['dataset_prop_version'] as int? ?? DatasetPropVersion.v1.value,
      ),
    );
  }

  @override
  List<Object?> get props => [
        dirName,
        csvUrl,
        videoUrl,
        thumbnailUrl,
        datasetVersion,
        datasetPropVersion,
      ];
}
