import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'filterings.g.dart';

sealed class Filtering extends Equatable {
  const Filtering();

  factory Filtering.fromJson(Map<String, dynamic> json) {
    return switch (json['name']) {
      'Median Filter' => MedianFilter.fromJson(json),
      'Low Pass Filter' => LowPassFilter.fromJson(json),
      _ => throw Exception('Unknown smoothing type: ${json['name']}'),
    };
  }

  factory Filtering.fromName(String name) {
    return switch (name) {
      'Median Filter' => const MedianFilter(),
      'Low Pass Filter' => const LowPassFilter(),
      _ => throw Exception('Unknown smoothing type: $name'),
    };
  }

  static List<String> values = ['Median Filter', 'Low Pass Filter'];

  Map<String, dynamic> toJson();

  String get name;

  @override
  List<Object?> get props => [name];
}

@JsonSerializable()
final class MedianFilter extends Filtering {
  const MedianFilter();

  factory MedianFilter.fromJson(Map<String, dynamic> json) =>
      _$MedianFilterFromJson(json);

  @JsonKey(includeToJson: true)
  @override
  String get name => 'Median Filter';

  @override
  Map<String, dynamic> toJson() => _$MedianFilterToJson(this);
}

@JsonSerializable()
final class LowPassFilter extends Filtering {
  const LowPassFilter({this.alpha});

  factory LowPassFilter.fromJson(Map<String, dynamic> json) =>
      _$LowPassFilterFromJson(json);

  final double? alpha;

  @JsonKey(includeToJson: true)
  @override
  String get name => 'Low Pass Filter';

  @override
  Map<String, dynamic> toJson() => _$LowPassFilterToJson(this);

  LowPassFilter copyWith({double? alpha}) {
    return LowPassFilter(
      alpha: alpha ?? this.alpha,
    );
  }
}
