// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dartx/dartx_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/asset_images.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/features/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/features/preprocess/widgets/data_item_tile_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sliver_tools/sliver_tools.dart';

class DatasetList extends ConsumerStatefulWidget {
  const DatasetList({
    required this.scrollController,
    required this.onDataItemPressed,
    super.key,
  });

  final ScrollController scrollController;
  final void Function(int index) onDataItemPressed;

  @override
  ConsumerState<DatasetList> createState() => _DatasetListState();
}

class _DatasetListState extends ConsumerState<DatasetList> {
  late final PreprocessNotifier _notifier;

  late List<_DataItemSection> _sectionList;

  List<_DataItemSection> _generateSection(List<DataItem> dataItems) {
    var currentIndex = 0;
    var isLastLabeled = false;

    return dataItems
        .groupBy((dataItem) {
          if (dataItem.movementSetId != null) {
            isLastLabeled = true;
            return dataItem.movementSetId;
          }
          if (isLastLabeled) {
            isLastLabeled = false;
            return currentIndex++;
          }
          isLastLabeled = false;
          return currentIndex;
        })
        .entries
        .map(
          (entry) => _DataItemSection(
            movementSetId:
                entry.key is String ? entry.key.toString() : 'Unlabelled',
            labelCategory: entry.value.first.labelCategory,
            dataItems: entry.value,
          ),
        )
        .toList();
  }

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier);

    final dataItems =
        ref.read(preprocessProvider.select((state) => state.dataItems));
    _sectionList = _generateSection(dataItems);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      preprocessProvider.select((state) => state.dataItems),
      (previous, dataItems) {
        _sectionList = _generateSection(dataItems);
      },
    );

    final dataItems =
        ref.watch(preprocessProvider.select((state) => state.dataItems));
    final predictedCategories = ref
        .watch(preprocessProvider.select((state) => state.predictedCategories));

    return Column(
      children: [
        const Divider(height: 0),
        _buildDataItemHeader(),
        const Divider(height: 0),
        Expanded(
          child: Scrollbar(
            child: CustomScrollView(
              slivers: [
                for (var sectionIndex = 0;
                    sectionIndex < _sectionList.length;
                    sectionIndex++)
                  MultiSliver(
                    pushPinnedChildren: true,
                    children: [
                      SliverPersistentHeader(
                        floating: true,
                        delegate: _ExpandableHeaderDelegate(
                          index: sectionIndex,
                          section: _sectionList[sectionIndex],
                          onTap: () {
                            setState(() {
                              _sectionList[sectionIndex] =
                                  _sectionList[sectionIndex].copyWith(
                                expanded: !_sectionList[sectionIndex].expanded,
                              );
                            });
                          },
                        ),
                      ),
                      SliverVisibility(
                        visible: _sectionList[sectionIndex].expanded,
                        sliver: SliverFixedExtentList(
                          itemExtent: 32,
                          delegate: SliverChildBuilderDelegate(
                            childCount:
                                _sectionList[sectionIndex].dataItems.length,
                            (context, index) {
                              final section = _sectionList[sectionIndex];
                              final dataItem = section.dataItems[index];
                              final predictedCategory =
                                  predictedCategories?[index];

                              final realIndex = dataItems.indexOf(dataItem);

                              return _buildDataItemTile(
                                realIndex,
                                dataItem,
                                predictedCategory,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );

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
                          context,
                          'No labeled data items were found.',
                        );
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

  Widget _buildDataItemTile(
    int index,
    DataItem dataItem,
    SholatMovementCategory? predictedCategory,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final currentHighlightedIndex = ref.watch(
          preprocessProvider.select((value) => value.currentHighlightedIndex),
        );
        final selected = ref.watch(
          preprocessProvider.select(
            (state) => state.selectedDataItemIndexes.contains(index),
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
                DeprecatedLabelCategoryProblem() => Iterable.generate(
                    problem.endIndex - problem.startIndex + 1,
                    (index) => problem.startIndex + index,
                  ).contains(index),
                WrongMovementSequenceProblem() => Iterable.generate(
                    problem.endIndex - problem.startIndex + 1,
                    (index) => problem.startIndex + index,
                  ).contains(index),
              },
            ),
          ),
        );

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

class _ExpandableHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ExpandableHeaderDelegate({
    required this.index,
    required this.section,
    required this.onTap,
  });

  final int index;
  final _DataItemSection section;
  final void Function() onTap;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget? icon;
    if (section.isLabeled) {
      final category = section.labelCategory!;
      final iconPath = switch (category) {
        SholatMovementCategory.takbir => AssetImages.takbir,
        SholatMovementCategory.berdiri => AssetImages.berdiri,
        SholatMovementCategory.ruku => AssetImages.ruku,
        SholatMovementCategory.iktidal => AssetImages.iktidal,
        SholatMovementCategory.qunut => AssetImages.qunut,
        SholatMovementCategory.sujud => AssetImages.sujud,
        SholatMovementCategory.duduk => AssetImages.duduk,
        SholatMovementCategory.transisi => AssetImages.transisi,
      };
      icon = SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          colorScheme.outline,
          BlendMode.srcIn,
        ),
      );
    }

    return Material(
      color: colorScheme.background,
      child: ListTile(
        title: Row(
          children: [
            SizedBox(
              child: icon,
            ),
            const SizedBox(width: 8),
            Text(section.labelCategory?.name ?? 'Unlabelled'),
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(section.dataItems.length.toString()),
            ),
          ],
        ),
        leading: Text(index.toString()),
        trailing: Icon(
          section.expanded
              ? Symbols.arrow_drop_up_rounded
              : Symbols.arrow_drop_down_rounded,
        ),
        dense: true,
        onTap: onTap,
      ),
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return this != oldDelegate;
  }
}

class _DataItemSection {
  _DataItemSection({
    required this.movementSetId,
    required this.labelCategory,
    required this.dataItems,
    this.expanded = false,
  });

  final String movementSetId;
  final SholatMovementCategory? labelCategory;
  final List<DataItem> dataItems;
  final bool expanded;

  bool get isLabeled => labelCategory != null;

  _DataItemSection copyWith({
    String? movementSetId,
    SholatMovementCategory? labelCategory,
    List<DataItem>? dataItems,
    bool? expanded,
  }) {
    return _DataItemSection(
      movementSetId: movementSetId ?? this.movementSetId,
      labelCategory: labelCategory ?? this.labelCategory,
      dataItems: dataItems ?? this.dataItems,
      expanded: expanded ?? this.expanded,
    );
  }
}
