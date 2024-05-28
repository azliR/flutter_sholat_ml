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

sealed class MovementSequenceProblem<T> extends Problem {
  const MovementSequenceProblem({
    required super.startIndex,
    required super.endIndex,
    required this.label,
    required this.expectedLabels,
  });

  final T label;
  final List<T?> expectedLabels;
}

final class WrongPreviousMovementSequenceProblem
    extends MovementSequenceProblem<SholatMovement> {
  const WrongPreviousMovementSequenceProblem({
    required super.startIndex,
    required super.endIndex,
    required super.label,
    required super.expectedLabels,
  });
}

final class WrongNextMovementSequenceProblem
    extends MovementSequenceProblem<SholatMovement> {
  const WrongNextMovementSequenceProblem({
    required super.startIndex,
    required super.endIndex,
    required super.label,
    required super.expectedLabels,
  });
}

final class WrongPreviousMovementCategorySequenceProblem
    extends MovementSequenceProblem<SholatMovementCategory> {
  const WrongPreviousMovementCategorySequenceProblem({
    required super.startIndex,
    required super.endIndex,
    required super.label,
    required super.expectedLabels,
  });
}

final class WrongNextMovementCategorySequenceProblem
    extends MovementSequenceProblem<SholatMovementCategory> {
  const WrongNextMovementCategorySequenceProblem({
    required super.startIndex,
    required super.endIndex,
    required super.label,
    required super.expectedLabels,
  });
}
