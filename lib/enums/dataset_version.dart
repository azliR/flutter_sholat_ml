enum DatasetVersion {
  /// Format dataset csv in v1:
  /// ```
  /// {timestamp},{x},{y},{z},{heartRate},{deviceLocation},{labelCategory},
  /// {label},
  /// ```
  v1,

  /// Format dataset csv in v2:
  /// ```
  /// {timestamp},{x},{y},{z},{heartRate},{movementSetId},{deviceLocation},
  /// {note},{labelCategory},{label},
  /// ```
  v2,

  /// Format dataset csv in v3:
  /// ```
  /// {timestamp},{x},{y},{z},{heartRate},{movementSetId},{deviceLocation},
  /// {note},{labelCategory},{label},{noise},
  /// ```
  v3,

  /// Format dataset csv in v4:
  /// ```
  /// {timestamp},{x},{y},{z},{heartRate},{movementSetId},{note},
  /// {labelCategory},{label},{noise},
  /// ```
  v4;

  factory DatasetVersion.fromValue(int value) {
    return DatasetVersion.values.firstWhere((e) => e.value == value);
  }

  String get name => switch (this) {
        DatasetVersion.v1 => 'v1',
        DatasetVersion.v2 => 'v2',
        DatasetVersion.v3 => 'v3',
        DatasetVersion.v4 => 'v4',
      };

  String nameWithIsLatest({String latestText = '', String defaultText = ''}) {
    if (this == DatasetVersion.values.last) {
      return name + latestText;
    }
    return name + defaultText;
  }

  int get value => switch (this) {
        DatasetVersion.v1 => 1,
        DatasetVersion.v2 => 2,
        DatasetVersion.v3 => 3,
        DatasetVersion.v4 => 4,
      };
}
