import 'package:dartx/dartx_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/asset_images.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/data_item/data_item_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/dataset/dataset_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/ml_model/ml_model_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/widgets/data_item_tile_widget.dart';
import 'package:flutter_svg/svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

class DatasetList extends ConsumerStatefulWidget {
  const DatasetList({
    required this.scrollController,
    super.key,
  });

  final ScrollController scrollController;

  @override
  ConsumerState<DatasetList> createState() => _DatasetListState();
}

class _DatasetListState extends ConsumerState<DatasetList> {
  late final PreprocessNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final predictedCategories =
        ref.watch(predictedCategoriesProvider).valueOrNull;
    final sectionsAsync = ref.watch(generateDataItemSectionProvider);

    return Column(
      children: [
        if (sectionsAsync.isLoading) const LinearProgressIndicator(),
        const Divider(height: 0),
        _buildDataItemHeader(),
        const Divider(height: 0),
        sectionsAsync.maybeWhen(
          orElse: () {
            final sections = sectionsAsync.valueOrNull ?? [];

            return Expanded(
              child: Scrollbar(
                child: CustomScrollView(
                  controller: widget.scrollController,
                  slivers: sections.mapIndexed((sectionIndex, section) {
                    final headerKey = GlobalKey(
                      debugLabel: section.labelCategory?.name ??
                          sectionIndex.toString(),
                    );
                    final selectedSectionIndex =
                        ref.watch(selectedSectionIndexProvider);

                    return MultiSliver(
                      pushPinnedChildren: true,
                      children: [
                        SliverPersistentHeader(
                          key: headerKey,
                          floating: true,
                          delegate: _ExpandableHeaderDelegate(
                            index: sectionIndex,
                            selected: selectedSectionIndex == sectionIndex,
                            section: sections[sectionIndex],
                            onTap: (overlapsContent) {
                              if (overlapsContent) {
                                Scrollable.ensureVisible(
                                  headerKey.currentContext!,
                                );
                              }

                              ref
                                  .read(
                                      generateDataItemSectionProvider.notifier)
                                  .toggleSectionAt(sectionIndex);
                              ref
                                  .read(selectedSectionIndexProvider.notifier)
                                  .setSectionIndex(sectionIndex);
                            },
                          ),
                        ),
                        if (sections[sectionIndex].expanded)
                          SliverFixedExtentList(
                            itemExtent: 32,
                            delegate: SliverChildBuilderDelegate(
                              childCount:
                                  sections[sectionIndex].dataItems.length,
                              (context, index) {
                                final section = sections[sectionIndex];
                                final dataItem = section.dataItems[index];
                                final predictedCategory =
                                    predictedCategories?[index];

                                return _buildDataItemTile(
                                  index: section.startIndex + index,
                                  sectionIndex: sectionIndex,
                                  dataItem: dataItem,
                                  predictedCategory: predictedCategory,
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
          error: (error, stackTrace) => Center(
            child: Text(error.toString()),
          ),
        ),
      ],
    );
  }

  Widget _buildDataItemTile({
    required int index,
    required int sectionIndex,
    required DataItem dataItem,
    required SholatMovementCategory? predictedCategory,
  }) {
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
          analyseDatasetProvider.select(
            (state) =>
                state.valueOrNull?.any(
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
                ) ??
                false,
          ),
        );

        return DataItemTile(
          index: index,
          dataItem: dataItem,
          predictedCategory: predictedCategory,
          isHighlighted: index == currentHighlightedIndex,
          isSelected: selected,
          hasProblem: hasProblem,
          onTap: () async {
            final state = ref.read(preprocessProvider);

            if (state.isJumpSelectMode) {
              await _notifier.jumpSelect(index);
            } else if (state.selectedDataItemIndexes.isNotEmpty) {
              _notifier.setSelectedDataset(index);
            }
            _notifier.setCurrentHighlightedIndex(index);

            ref
                .read(selectedSectionIndexProvider.notifier)
                .setSectionIndex(sectionIndex);
          },
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
    required this.selected,
    required this.section,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final DataItemSection section;
  final void Function(bool overlapsContent) onTap;

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
      icon = SvgPicture(
        AssetBytesLoader(iconPath),
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
      shape: selected
          ? RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: colorScheme.outline),
            )
          : null,
      child: ListTile(
        title: Row(
          children: [
            SizedBox(
              child: icon,
            ),
            const SizedBox(width: 8),
            Text(section.labelCategory?.name ?? 'Unlabelled'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(section.dataItems.length.toString()),
            ),
            const SizedBox(width: 8),
            if (section.movementSetId != null)
              Tooltip(
                message: 'Movement Set ID',
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(section.movementSetId!.substring(0, 6)),
                ),
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
        onTap: () => onTap(overlapsContent),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
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

class DataItemSection {
  DataItemSection({
    required this.startIndex,
    required this.labelCategory,
    required this.dataItems,
    this.movementSetId,
    this.expanded = false,
  });

  final int startIndex;
  final String? movementSetId;
  final SholatMovementCategory? labelCategory;
  final List<DataItem> dataItems;
  final bool expanded;

  bool get isLabeled => labelCategory != null;

  DataItemSection copyWith({
    int? startIndex,
    String? movementSetId,
    SholatMovementCategory? labelCategory,
    List<DataItem>? dataItems,
    bool? expanded,
  }) {
    return DataItemSection(
      startIndex: startIndex ?? this.startIndex,
      movementSetId: movementSetId ?? this.movementSetId,
      labelCategory: labelCategory ?? this.labelCategory,
      dataItems: dataItems ?? this.dataItems,
      expanded: expanded ?? this.expanded,
    );
  }
}
