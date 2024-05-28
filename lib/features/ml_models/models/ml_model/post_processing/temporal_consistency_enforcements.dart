import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'temporal_consistency_enforcements.g.dart';

sealed class TemporalConsistencyEnforcement extends Equatable {
  const TemporalConsistencyEnforcement();

  factory TemporalConsistencyEnforcement.fromJson(Map<String, dynamic> json) {
    return switch (json['name']) {
      'Majority Voting' => MajorityVoting.fromJson(json),
      'Transition Constraints' => TransitionConstraints.fromJson(json),
      _ => throw Exception('Unknown smoothing type: ${json['name']}'),
    };
  }

  factory TemporalConsistencyEnforcement.fromName(String name) {
    return switch (name) {
      'Majority Voting' => const MajorityVoting(),
      'Transition Constraints' => const TransitionConstraints(),
      _ => throw Exception('Unknown smoothing type: $name'),
    };
  }

  static List<String> values = ['Majority Voting', 'Transition Constraints'];

  Map<String, dynamic> toJson();

  String get name;

  @override
  List<Object?> get props => [name];
}

@JsonSerializable()
final class MajorityVoting extends TemporalConsistencyEnforcement {
  const MajorityVoting({this.minConsecutivePredictions});

  factory MajorityVoting.fromJson(Map<String, dynamic> json) =>
      _$MajorityVotingFromJson(json);

  final int? minConsecutivePredictions;

  @JsonKey(includeToJson: true)
  @override
  String get name => 'Majority Voting';

  @override
  Map<String, dynamic> toJson() => _$MajorityVotingToJson(this);
}

@JsonSerializable()
final class TransitionConstraints extends TemporalConsistencyEnforcement {
  const TransitionConstraints({this.minDuration});

  factory TransitionConstraints.fromJson(Map<String, dynamic> json) =>
      _$TransitionConstraintsFromJson(json);

  final int? minDuration;

  @JsonKey(includeToJson: true)
  @override
  String get name => 'Transition Constraints';

  @override
  Map<String, dynamic> toJson() => _$TransitionConstraintsToJson(this);

  TransitionConstraints copyWith({int? minDuration}) {
    return TransitionConstraints(
      minDuration: minDuration ?? this.minDuration,
    );
  }
}
