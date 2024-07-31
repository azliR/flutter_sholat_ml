// import 'package:equatable/equatable.dart';
// import 'package:json_annotation/json_annotation.dart';

// part 'weightings.g.dart';

// sealed class Weighting extends Equatable {
//   const Weighting();

//   factory Weighting.fromJson(Map<String, dynamic> json) {
//     return switch (json['name']) {
//       'Transition Weighting' => TransitionWeighting.fromJson(json),
//       // 'Low Pass Filter' => LowPassFilter.fromJson(json),
//       _ => throw Exception('Unknown smoothing type: ${json['name']}'),
//     };
//   }

//   factory Weighting.fromName(String name) {
//     return switch (name) {
//       'Transition Weighting' => const TransitionWeighting(),
//       // 'Low Pass Filter' => const LowPassFilter(),
//       _ => throw Exception('Unknown smoothing type: $name'),
//     };
//   }

//   static List<String> values = [
//     'Transition Weighting',
//     // 'Low Pass Filter',
//   ];

//   Map<String, dynamic> toJson();

//   String get name;

//   @override
//   List<Object?> get props => [name];
// }

// @JsonSerializable()
// final class TransitionWeighting extends Weighting {
//   const TransitionWeighting({this.weight});

//   factory TransitionWeighting.fromJson(Map<String, dynamic> json) =>
//       _$TransitionWeightingFromJson(json);

//   final double? weight;

//   @JsonKey(includeToJson: true)
//   @override
//   String get name => 'Transition Weighting';

//   @override
//   Map<String, dynamic> toJson() => _$TransitionWeightingToJson(this);
// }
