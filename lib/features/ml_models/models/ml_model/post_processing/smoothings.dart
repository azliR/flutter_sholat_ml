import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'smoothings.g.dart';

sealed class Smoothing extends Equatable {
  const Smoothing();

  factory Smoothing.fromJson(Map<String, dynamic> json) {
    return switch (json['name']) {
      'Moving Average' => MovingAverage.fromJson(json),
      'Exponential Smoothing' => ExponentialSmoothing.fromJson(json),
      _ => throw Exception('Unknown smoothing type: ${json['name']}'),
    };
  }

  factory Smoothing.fromName(String name) {
    return switch (name) {
      'Moving Average' => const MovingAverage(),
      'Exponential Smoothing' => const ExponentialSmoothing(),
      _ => throw Exception('Unknown smoothing type: $name'),
    };
  }

  static List<String> values = ['Moving Average', 'Exponential Smoothing'];

  Map<String, dynamic> toJson();

  String get name;

  @override
  List<Object?> get props => [name];
}

@JsonSerializable()
final class MovingAverage extends Smoothing {
  const MovingAverage();

  factory MovingAverage.fromJson(Map<String, dynamic> json) =>
      _$MovingAverageFromJson(json);

  @JsonKey(includeToJson: true)
  @override
  String get name => 'Moving Average';

  @override
  Map<String, dynamic> toJson() => _$MovingAverageToJson(this);
}

@JsonSerializable()
final class ExponentialSmoothing extends Smoothing {
  const ExponentialSmoothing({this.alpha});

  factory ExponentialSmoothing.fromJson(Map<String, dynamic> json) =>
      _$ExponentialSmoothingFromJson(json);

  final double? alpha;

  @JsonKey(includeToJson: true)
  @override
  String get name => 'Exponential Smoothing';

  @override
  Map<String, dynamic> toJson() => _$ExponentialSmoothingToJson(this);

  ExponentialSmoothing copyWith({double? alpha}) {
    return ExponentialSmoothing(
      alpha: alpha ?? this.alpha,
    );
  }
}
