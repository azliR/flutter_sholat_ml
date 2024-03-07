import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class Device extends Equatable {
  const Device({
    required this.authKey,
    required this.deviceId,
    required this.deviceName,
  });

  final String authKey;
  final String deviceId;
  final String deviceName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'auth_key': authKey,
      'device_id': deviceId,
      'device_name': deviceName,
    };
  }

  factory Device.fromJson(Map<String, dynamic> map) {
    return Device(
      authKey: (map['auth_key'] ?? '') as String,
      deviceId: (map['device_id'] ?? '') as String,
      deviceName: (map['device_name'] ?? '') as String,
    );
  }

  @override
  List<Object?> get props => [authKey, deviceId, deviceName];
}
