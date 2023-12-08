import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';

sealed class Problem {
  const Problem({
    required this.startIndex,
    required this.endIndex,
  });

  final int startIndex;
  final int endIndex;
}

final class MissingLabelProblem extends Problem {
  const MissingLabelProblem({
    required super.startIndex,
    required super.endIndex,
  });
}

final class DeprecatedLabelProblem extends Problem {
  const DeprecatedLabelProblem({
    required super.startIndex,
    required super.endIndex,
    required this.label,
  });

  final SholatMovement label;
}

final class DeprecatedLabelCategoryProblem extends Problem {
  const DeprecatedLabelCategoryProblem({
    required super.startIndex,
    required super.endIndex,
    required this.labelCategory,
  });

  final SholatMovementCategory labelCategory;
}

final class WrongMovementSequenceProblem extends Problem {
  const WrongMovementSequenceProblem({
    required super.startIndex,
    required super.endIndex,
    required this.label,
    required this.expectedPreviousLabels,
    required this.expectedNextLabels,
  });

  final SholatMovement label;
  final List<SholatMovement> expectedPreviousLabels;
  final List<SholatMovement> expectedNextLabels;
}
