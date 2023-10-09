enum DeviceLocation {
  leftWrist,
  rightWrist;

  String get name {
    switch (this) {
      case DeviceLocation.leftWrist:
        return 'Left wrist';
      case DeviceLocation.rightWrist:
        return 'Right wrist';
    }
  }

  String get code {
    switch (this) {
      case DeviceLocation.leftWrist:
        return 'left_wrist';
      case DeviceLocation.rightWrist:
        return 'right_wrist';
    }
  }

  static DeviceLocation fromCode(String name) {
    switch (name) {
      case 'left_wrist':
        return DeviceLocation.leftWrist;
      case 'right_wrist':
        return DeviceLocation.rightWrist;
      default:
        throw ArgumentError('Invalid device location name: $name');
    }
  }
}
