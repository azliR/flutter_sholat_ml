// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';

@immutable
class Dataset {
  const Dataset({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  final double x;
  final double y;
  final double z;
  final DateTime timestamp;

  @override
  bool operator ==(covariant Dataset other) {
    if (identical(this, other)) return true;

    return other.x == x &&
        other.y == y &&
        other.z == z &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ z.hashCode ^ timestamp.hashCode;
  }
}
