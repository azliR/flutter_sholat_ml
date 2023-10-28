enum DeviceLocation {
  leftWrist,
  rightWrist;

  factory DeviceLocation.fromValue(String value) {
    return DeviceLocation.values.firstWhere((e) => e.value == value);
  }

  String get name {
    switch (this) {
      case DeviceLocation.leftWrist:
        return 'Left wrist';
      case DeviceLocation.rightWrist:
        return 'Right wrist';
    }
  }

  String get value {
    switch (this) {
      case DeviceLocation.leftWrist:
        return 'left_wrist';
      case DeviceLocation.rightWrist:
        return 'right_wrist';
    }
  }
}
