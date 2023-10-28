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
  v2,

  /// Format dataset csv in v2:
  /// ```
  /// {timestamp},{x},{y},{z},{heartRate},{movementSetId},{deviceLocation},{note},{labelCategory},{label},{noise}'
  /// ```
  v3;

  factory DatasetVersion.fromValue(int value) {
    return DatasetVersion.values.firstWhere((e) => e.value == value);
  }

  String get name {
    switch (this) {
      case DatasetVersion.v1:
        return 'v1';
      case DatasetVersion.v2:
        return 'v2';
      case DatasetVersion.v3:
        return 'v3';
    }
  }

  int get value {
    switch (this) {
      case DatasetVersion.v1:
        return 1;
      case DatasetVersion.v2:
        return 2;
      case DatasetVersion.v3:
        return 3;
    }
  }
}
