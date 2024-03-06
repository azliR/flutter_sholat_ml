// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';

@immutable
class Wearable {
  const Wearable({
    required this.activeStatus,
    required this.macAddress,
    required this.authKey,
    required this.deviceSource,
    required this.firmwareVersion,
    required this.hardwareVersion,
    required this.productionSource,
  });

  final bool activeStatus;
  final String macAddress;
  final String authKey;
  final String deviceSource;
  final String firmwareVersion;
  final String hardwareVersion;
  final String productionSource;

  factory Wearable.fromJson(Map<String, dynamic> json) {
    return Wearable(
      activeStatus: (json['activeStatus'] ?? false) as bool,
      macAddress: (json['macAddress'] ?? '') as String,
      authKey: (json['authKey'] ?? '') as String,
      deviceSource: (json['deviceSource'] ?? '') as String,
      firmwareVersion: (json['firmwareVersion'] ?? '') as String,
      hardwareVersion: (json['hardwareVersion'] ?? '') as String,
      productionSource: (json['productionSource'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'activeStatus': activeStatus,
      'macAddress': macAddress,
      'authKey': authKey,
      'deviceSource': deviceSource,
      'firmwareVersion': firmwareVersion,
      'hardwareVersion': hardwareVersion,
      'productionSource': productionSource,
    };
  }
}
