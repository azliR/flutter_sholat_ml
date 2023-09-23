// ignore_for_file: public_member_api_docs, sort_constructors_first
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
      'authKey': authKey,
      'deviceId': deviceId,
      'deviceName': deviceName,
    };
  }

  factory Device.fromJson(Map<String, dynamic> map) {
    return Device(
      authKey: (map['authKey'] ?? '') as String,
      deviceId: (map['deviceId'] ?? '') as String,
      deviceName: (map['deviceName'] ?? '') as String,
    );
  }

  @override
  List<Object?> get props => [authKey, deviceId, deviceName];
}
