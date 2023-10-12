enum DatasetPropVersion {
  /// Format dataset prop in v1:
  /// ```json
  /// {
  ///    'dir_name': dirName,
  ///    'csv_url': csvUrl,
  ///    'video_url': videoUrl,
  ///    'dataset_version': datasetVersion.code,
  /// }
  /// ```
  v1,

  /// Format dataset prop in v2:
  /// ```json
  /// {
  ///    'dir_name': dirName,
  ///    'csv_url': csvUrl,
  ///    'video_url': videoUrl,
  ///    'thumbnail_url': thumbnailUrl,
  ///    'dataset_version': datasetVersion.code,
  ///    'dataset_prop_version': datasetPropVersion.code
  /// }
  /// ```
  v2;

  factory DatasetPropVersion.fromCode(int value) {
    switch (value) {
      case 1:
        return DatasetPropVersion.v1;
      case 2:
        return DatasetPropVersion.v2;
      default:
        throw Exception('Unknown DatasetPropVersion: $value');
    }
  }

  String get name {
    switch (this) {
      case DatasetPropVersion.v1:
        return 'v1';
      case DatasetPropVersion.v2:
        return 'v2';
    }
  }

  int get code {
    switch (this) {
      case DatasetPropVersion.v1:
        return 1;
      case DatasetPropVersion.v2:
        return 2;
    }
  }
}
