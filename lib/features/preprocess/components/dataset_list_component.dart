import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/features/preprocess/widgets/data_item_tile_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

class DatasetList extends ConsumerStatefulWidget {
  const DatasetList({
    required this.scrollController,
    required this.onDataItemPressed,
    super.key,
  });

  final ScrollController scrollController;
  final void Function(int index) onDataItemPressed;

  @override
  ConsumerState<DatasetList> createState() => _PreprocessDatasetListState();
}

class _PreprocessDatasetListState extends ConsumerState<DatasetList> {
  late final PreprocessNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final dataItems =
        ref.watch(preprocessProvider.select((state) => state.dataItems));
    final predictedCategories = ref
        .watch(preprocessProvider.select((state) => state.predictedCategories));
    // final (_, indexes, groupedDataItems) =
    //     dataItems.fold((0, <int>[], <DataItem>[]), (previousValue, element) {
    //   final index = previousValue.$1;
    //   final indexes = previousValue.$2;
    //   final dataItems = previousValue.$3;
    //   if (element.isLabeled &&
    //       dataItems
    //           .any((value) => value.movementSetId == element.movementSetId)) {
    //     return (index + 1, indexes, dataItems);
    //   }
    //   return (index + 1, indexes..add(index), dataItems..add(element));
    // });

    return Column(
      children: [
        _buildDataItemHeader(),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Scrollbar(
                child: ListView.builder(
                  controller: widget.scrollController,
                  cacheExtent: 32,
                  itemExtent: 32,
                  itemCount: dataItems.length,
                  itemBuilder: (context, index) {
                    return Consumer(
                      builder: (context, ref, child) {
                        final currentHighlightedIndex = ref.watch(
                          preprocessProvider
                              .select((value) => value.currentHighlightedIndex),
                        );
                        final selected = ref.watch(
                          preprocessProvider.select(
                            (state) =>
                                state.selectedDataItemIndexes.contains(index),
                          ),
                        );
                        final hasProblem = ref.watch(
                          preprocessProvider.select(
                            (state) => state.problems.any(
                              (problem) => switch (problem) {
                                MissingLabelProblem() => Iterable.generate(
                                    problem.endIndex - problem.startIndex + 1,
                                    (index) => problem.startIndex + index,
                                  ).contains(index),
                                DeprecatedLabelProblem() => Iterable.generate(
                                    problem.endIndex - problem.startIndex + 1,
                                    (index) => problem.startIndex + index,
                                  ).contains(index),
                                DeprecatedLabelCategoryProblem() =>
                                  Iterable.generate(
                                    problem.endIndex - problem.startIndex + 1,
                                    (index) => problem.startIndex + index,
                                  ).contains(index),
                                WrongMovementSequenceProblem() =>
                                  Iterable.generate(
                                    problem.endIndex - problem.startIndex + 1,
                                    (index) => problem.startIndex + index,
                                  ).contains(index),
                              },
                            ),
                          ),
                        );

                        final dataItem = dataItems[index];
                        final predictedCategory = predictedCategories?[index];

                        return DataItemTile(
                          index: index,
                          dataItem: dataItem,
                          predictedCategory: predictedCategory,
                          isHighlighted: index == currentHighlightedIndex,
                          isSelected: selected,
                          hasProblem: hasProblem,
                          onTap: () => widget.onDataItemPressed(index),
                          onLongPress: () async {
                            _notifier
                              ..setSelectedDataset(index)
                              ..setCurrentHighlightedIndex(index);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FloatingActionButton.small(
                    tooltip: 'Last labeled data item',
                    onPressed: () {
                      final lastLabeledIndex = dataItems
                          .lastIndexWhere((dataItem) => dataItem.isLabeled);

                      if (lastLabeledIndex < 0) {
                        showSnackbar(
                            context, 'No labeled data items were found.');
                        return;
                      }

                      widget.scrollController.jumpTo(lastLabeledIndex * 32);
                      _notifier.setCurrentHighlightedIndex(lastLabeledIndex);
                    },
                    child: const Icon(Symbols.arrow_downward_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataItemHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DefaultTextStyle(
      style: textTheme.bodyMedium!.copyWith(
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Center(child: Text('i')),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text('timestamp'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('x')),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('y')),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('z')),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text('noise'),
            ),
          ),
          Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}
