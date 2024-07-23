import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/dataset/dataset_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class BottomPanel extends ConsumerWidget {
  const BottomPanel({
    required this.problems,
    required this.isVerticalLayout,
    required this.onProblemPressed,
    required this.onClosePressed,
    super.key,
  });

  final List<Problem> problems;
  final bool isVerticalLayout;
  final void Function(Problem problem) onProblemPressed;
  final void Function() onClosePressed;

  String _toTitleStr(Problem problem) {
    final startIndex = problem.startIndex;
    final endIndex = problem.endIndex;

    return switch (problem) {
      MissingLabelProblem() => 'Missing label.',
      DeprecatedLabelProblem() => 'Deprecated label.',
      DeprecatedLabelCategoryProblem() => 'Deprecated label category.',
      WrongPreviousMovementSequenceProblem() =>
        "Invalid previous movement sequence of '${problem.label.value}'",
      WrongNextMovementSequenceProblem() =>
        "Invalid next movement sequence of '${problem.label.value}'",
      WrongPreviousMovementCategorySequenceProblem() =>
        "Invalid previous movement category sequence of '${problem.label.value}'",
      WrongNextMovementCategorySequenceProblem() =>
        "Invalid next movement category sequence of '${problem.label.value}'",
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final problemFilters = ref.watch(problemFiltersProvider);
    final filteredProblems = problemFilters.isEmpty
        ? problems
        : problems.where((problem) {
            return switch (problem.runtimeType) {
              MissingLabelProblem =>
                problemFilters.contains(ProblemType.missingLabel),
              DeprecatedLabelProblem =>
                problemFilters.contains(ProblemType.deprecatedLabel),
              DeprecatedLabelCategoryProblem =>
                problemFilters.contains(ProblemType.deprecatedLabelCategory),
              WrongPreviousMovementSequenceProblem => problemFilters
                  .contains(ProblemType.wrongPreviousMovementSequence),
              WrongPreviousMovementCategorySequenceProblem => problemFilters
                  .contains(ProblemType.wrongPreviousMovementCategorySequence),
              WrongNextMovementSequenceProblem =>
                problemFilters.contains(ProblemType.wrongNextMovementSequence),
              WrongNextMovementCategorySequenceProblem => problemFilters
                  .contains(ProblemType.wrongNextMovementCategorySequence),
              _ => false,
            };
          }).toList();

    return Card.filled(
      margin: isVerticalLayout
          ? const EdgeInsets.only(top: 2)
          : const EdgeInsets.fromLTRB(4, 4, 8, 0),
      color: ElevationOverlay.applySurfaceTint(
        colorScheme.surface,
        colorScheme.surfaceTint,
        1,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
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
                  child: Text(filteredProblems.length.toString()),
                ),
                const SizedBox(width: 4),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    ref.invalidate(datasetProblemsProvider);
                  },
                  icon: const Icon(Symbols.refresh_rounded),
                  tooltip: 'Refresh problem',
                ),
                _FilterButton(
                  filteredProblems: filteredProblems,
                  problems: problems,
                ),
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
                itemCount: filteredProblems.length,
                itemBuilder: (context, index) {
                  final problem = filteredProblems[index];
                  return InkWell(
                    onTap: () => onProblemPressed(problem),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Symbols.cancel_rounded,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(
                                    text: _toTitleStr(problem),
                                    children: [
                                      TextSpan(
                                        text: problem.startIndex ==
                                                problem.endIndex
                                            ? ' [i ${problem.startIndex}]'
                                            : ' [i ${problem.startIndex} - ${problem.endIndex}]',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: textTheme.bodyMedium,
                                ),
                                if (problem is MovementSequenceProblem) ...[
                                  Text(
                                    'Expected: ${problem.expectedLabels.map((e) => e?.value).join(', ')}',
                                    style: textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.normal,
                                    ),
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
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.filteredProblems,
    required this.problems,
  });

  final List<Problem> filteredProblems;
  final List<Problem> problems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        if (filteredProblems.length != problems.length)
          Text(
            'Showing ${filteredProblems.length} of ${problems.length}',
          ),
        IconButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return Consumer(
                  builder: (context, ref, child) {
                    const allProblems = ProblemType.values;
                    final problemFilters = ref.watch(problemFiltersProvider);

                    return AlertDialog(
                      title: const Text('Show filter'),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      content: SizedBox(
                        width: 240,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: allProblems.length,
                          itemBuilder: (context, index) {
                            final problem = allProblems[index];

                            return CheckboxListTile(
                              contentPadding: const EdgeInsets.fromLTRB(
                                24,
                                0,
                                24,
                                0,
                              ),
                              title: Text(problem.name),
                              dense: true,
                              value: problemFilters.contains(problem),
                              onChanged: (value) {
                                ref
                                    .read(problemFiltersProvider.notifier)
                                    .toggle(problem);
                              },
                            );
                          },
                        ),
                      ),
                      actions: [
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(problemFiltersProvider),
                          child: const Text('Reset'),
                        ),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Finish'),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
          icon: Badge(
            isLabelVisible: filteredProblems.length != problems.length,
            backgroundColor: colorScheme.primary,
            child: const Icon(Symbols.filter_alt_rounded),
          ),
        ),
      ],
    );
  }
}
