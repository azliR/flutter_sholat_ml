import 'package:flutter/foundation.dart';

@immutable
class DatasetThumbnail {
  const DatasetThumbnail({
    required this.dirName,
    required this.thumbnailPath,
    required this.error,
  });

  final String dirName;
  final String? thumbnailPath;
  final String? error;
}
