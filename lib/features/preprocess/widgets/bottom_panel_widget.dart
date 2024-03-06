import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:material_symbols_icons/symbols.dart';

class BottomPanel extends StatelessWidget {
  const BottomPanel({
    required this.problems,
    required this.onProblemPressed,
    required this.onClosePressed,
    super.key,
  });

  final List<Problem> problems;
  final void Function(Problem problem) onProblemPressed;
  final void Function() onClosePressed;

  String _toTitleStr(Problem problem) {
    final startIndex = problem.startIndex;
    final endIndex = problem.endIndex;

    return switch (problem) {
      MissingLabelProblem() =>
        'Missing label from index ${endIndex - startIndex == 0 ? 'at index $startIndex' : '$startIndex to $endIndex'}',
      DeprecatedLabelProblem() =>
        'Deprecated label ${problem.label.value} from index $startIndex to $endIndex',
      DeprecatedLabelCategoryProblem() =>
        'Deprecated label category ${problem.labelCategory.value} from index $startIndex to $endIndex',
      WrongMovementSequenceProblem() =>
        'Wrong movement sequence of ${problem.label.value} from index $startIndex to $endIndex',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              Text(
                'Problems',
                style: textTheme.titleSmall,
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(problems.length.toString()),
              ),
              const Spacer(),
              IconButton(
                style: IconButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onClosePressed,
                icon: const Icon(
                  Symbols.close_rounded,
                  size: 20,
                ),
              ),
            ],
          ),
          const Divider(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: problems.length,
              itemBuilder: (context, index) {
                final problem = problems[index];
                return InkWell(
                  onTap: () => onProblemPressed(problem),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Symbols.error,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_toTitleStr(problem)),
                              if (problem is WrongMovementSequenceProblem) ...[
                                Text(
                                  'Expected previous labels: ${problem.expectedPreviousLabels.map((e) => e.value).join(', ')}',
                                  style: textTheme.labelMedium,
                                ),
                                Text(
                                  'Expected next labels: ${problem.expectedNextLabels.map((e) => e.value).join(', ')}',
                                  style: textTheme.labelMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
