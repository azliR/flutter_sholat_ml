import 'package:flutter/foundation.dart';

@immutable
class DatasetThumbnail {
  const DatasetThumbnail({
    required this.datasetDir,
    required this.thumbnailPath,
    required this.error,
  });

  final String datasetDir;
  final String? thumbnailPath;
  final String? error;
}
