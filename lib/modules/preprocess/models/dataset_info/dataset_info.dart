// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';

@immutable
class DatasetInfo {
  const DatasetInfo({
    required this.dirName,
    required this.csvUrl,
    required this.videoUrl,
  });

  final String dirName;
  final String csvUrl;
  final String videoUrl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dir_name': dirName,
      'csv_url': csvUrl,
      'video_url': videoUrl,
    };
  }

  Map<String, dynamic> toFirestoreJson() {
    return <String, dynamic>{
      'csv_url': csvUrl,
      'video_url': videoUrl,
    };
  }

  factory DatasetInfo.fromJson(Map<String, dynamic> json) {
    return DatasetInfo(
      dirName: (json['dir_name'] ?? '') as String,
      csvUrl: (json['csv_url'] ?? '') as String,
      videoUrl: (json['video_url'] ?? '') as String,
    );
  }

  factory DatasetInfo.fromFirestoreJson(
    Map<String, dynamic> json,
    String dirName,
  ) {
    return DatasetInfo(
      dirName: dirName,
      csvUrl: (json['csv_url'] ?? '') as String,
      videoUrl: (json['video_url'] ?? '') as String,
    );
  }
}
