enum DatasetVersion {
  /// Format dataset csv in v1:
  /// ```
  /// {timestamp},{x},{y},{z},{heartRate},{deviceLocation},{labelCategory},{label}'
  /// ```
  v1,

  /// Format dataset csv in v2:
  /// ```
  /// {timestamp},{x},{y},{z},{heartRate},{movementSetId},{deviceLocation},{note},{labelCategory},{label}'
  /// ```
  v2;

  factory DatasetVersion.fromCode(int value) {
    switch (value) {
      case 1:
        return DatasetVersion.v1;
      case 2:
        return DatasetVersion.v2;
      default:
        throw Exception('Unknown DatasetVersion: $value');
    }
  }

  String get name {
    switch (this) {
      case DatasetVersion.v1:
        return 'v1';
      case DatasetVersion.v2:
        return 'v2';
    }
  }

  int get code {
    switch (this) {
      case DatasetVersion.v1:
        return 1;
      case DatasetVersion.v2:
        return 2;
    }
  }
}
