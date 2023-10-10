import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';

@immutable
class DatasetInfo {
  const DatasetInfo({
    required this.dirName,
    required this.datasetVersion,
    this.csvUrl,
    this.videoUrl,
  });

  final String dirName;
  final String? csvUrl;
  final String? videoUrl;
  final DatasetVersion datasetVersion;

  bool get isSubmitted => csvUrl != null && videoUrl != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dir_name': dirName,
      'csv_url': csvUrl,
      'video_url': videoUrl,
      'dataset_version': datasetVersion.code,
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return <String, dynamic>{
      'csv_url': csvUrl,
      'video_url': videoUrl,
      'dataset_version': datasetVersion.code,
    };
  }

  factory DatasetInfo.fromJson(Map<String, dynamic> json) {
    return DatasetInfo(
      dirName: json['dir_name'] as String,
      csvUrl: json['csv_url'] as String?,
      videoUrl: json['video_url'] as String?,
      datasetVersion: json['dataset_version'] == null
          ? DatasetVersion.v1
          : DatasetVersion.fromCode(json['dataset_version'] as String),
    );
  }

  factory DatasetInfo.fromFirestoreJson(
    Map<String, dynamic> json,
    String dirName,
  ) {
    return DatasetInfo(
      dirName: dirName,
      csvUrl: json['csv_url'] as String,
      videoUrl: json['video_url'] as String,
      datasetVersion:
          DatasetVersion.fromCode(json['dataset_version'] as String),
    );
  }
}
