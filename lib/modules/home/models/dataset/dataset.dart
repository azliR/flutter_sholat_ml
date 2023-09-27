import 'package:flutter/foundation.dart';

@immutable
class Dataset {
  const Dataset({
    required this.x,
    required this.y,
    required this.z,
    this.timestamp,
  });

  final num x;
  final num y;
  final num z;
  final Duration? timestamp;

  @override
  bool operator ==(covariant Dataset other) {
    if (identical(this, other)) return true;

    return other.x == x &&
        other.y == y &&
        other.z == z &&
        other.timestamp == timestamp;
  }

  Dataset copyWith({
    num? x,
    num? y,
    num? z,
    Duration? timestamp,
  }) {
    return Dataset(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ z.hashCode ^ timestamp.hashCode;
  }
}
