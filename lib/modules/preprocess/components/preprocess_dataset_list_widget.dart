import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/data_item_tile_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PreprocessDatasetList extends ConsumerStatefulWidget {
  const PreprocessDatasetList({
    required this.scrollController,
    required this.trackballBehavior,
    super.key,
  });

  final ScrollController scrollController;
  final TrackballBehavior trackballBehavior;

  @override
  ConsumerState<PreprocessDatasetList> createState() =>
      _PreprocessDatasetListState();
}

class _PreprocessDatasetListState extends ConsumerState<PreprocessDatasetList> {
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

    return Focus(
      autofocus: true,
      onKey: (node, event) {
        _notifier.setJumpSelectMode(enable: event.isShiftPressed);
        return KeyEventResult.handled;
      },
      child: Scrollbar(
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
                final selectedDataItemIndexes = ref.watch(
                  preprocessProvider
                      .select((state) => state.selectedDataItemIndexes),
                );

                final dataset = dataItems[index];
                final selected = selectedDataItemIndexes.contains(index);

                return DataItemTile(
                  index: index,
                  dataItem: dataset,
                  highlighted: index == currentHighlightedIndex,
                  selected: selected,
                  onTap: () async {
                    final isJumpSelectMode = ref.read(
                      preprocessProvider
                          .select((value) => value.isJumpSelectMode),
                    );
                    if (isJumpSelectMode) {
                      await _notifier.jumpSelect(index);
                    } else if (selectedDataItemIndexes.isNotEmpty) {
                      _notifier.setSelectedDataset(index);
                    }
                    _notifier.setCurrentHighlightedIndex(index);
                    widget.trackballBehavior.showByIndex(index);
                  },
                  onLongPress: () async {
                    _notifier
                      ..setSelectedDataset(index)
                      ..setCurrentHighlightedIndex(index);
                    widget.trackballBehavior.showByIndex(index);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
