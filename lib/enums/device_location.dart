enum DeviceLocation {
  leftWrist,
  rightWrist;

  factory DeviceLocation.fromValue(String value) {
    return DeviceLocation.values.firstWhere((e) => e.value == value);
  }

  String get name => switch (this) {
        DeviceLocation.leftWrist => 'Left wrist',
        DeviceLocation.rightWrist => 'Right wrist',
      };

  String get value => switch (this) {
        DeviceLocation.leftWrist => 'left_wrist',
        DeviceLocation.rightWrist => 'right_wrist',
      };
}
