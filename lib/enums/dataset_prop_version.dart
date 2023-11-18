enum DatasetPropVersion {
  /// Format dataset prop in v1:
  /// ```json
  /// {
  ///    'dir_name': String,
  ///    'csv_url': String?,
  ///    'video_url': String?,
  ///    'dataset_version': Enum
  /// }
  /// ```
  v1,

  /// Format dataset prop in v2:
  /// ```json
  /// {
  ///    'dir_name': String,
  ///    'csv_url': String?,
  ///    'video_url': String?,
  ///    'thumbnail_url': String?,
  ///    'dataset_version': Enum,
  ///    'dataset_prop_version': Enum
  /// }
  /// ```
  v2,

  /// Format dataset prop in v3:
  /// ```json
  /// {
  ///    'id': String,
  ///    'csv_url': String?,
  ///    'video_url': String?,
  ///    'thumbnail_url': String?,
  ///    'dataset_version': Enum,
  ///    'dataset_prop_version': Enum,
  ///    'created_at': DateTime
  /// }
  /// ```
  v3,

  /// Format dataset prop in v4:
  /// ```json
  /// {
  ///    'id': String,
  ///    'csv_url': String?,
  ///    'video_url': String?,
  ///    'thumbnail_url': String?,
  ///    'has_evaluated': bool,
  ///    'dataset_version': Enum,
  ///    'dataset_prop_version': Enum,
  ///    'created_at': DateTime
  /// }
  /// ```
  v4;

  factory DatasetPropVersion.fromValue(int value) {
    return DatasetPropVersion.values.firstWhere((e) => e.value == value);
  }

  String get name {
    switch (this) {
      case DatasetPropVersion.v1:
        return 'v1';
      case DatasetPropVersion.v2:
        return 'v2';
      case DatasetPropVersion.v3:
        return 'v3';
      case DatasetPropVersion.v4:
        return 'v4';
    }
  }

  String nameWithIsLatest({String latestText = '', String defaultText = ''}) {
    if (this == DatasetPropVersion.values.last) {
      return name + latestText;
    }
    return name + defaultText;
  }

  int get value {
    switch (this) {
      case DatasetPropVersion.v1:
        return 1;
      case DatasetPropVersion.v2:
        return 2;
      case DatasetPropVersion.v3:
        return 3;
      case DatasetPropVersion.v4:
        return 4;
    }
  }
}
