import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/data_item_tile_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PreprocessDatasetList extends ConsumerStatefulWidget {
  const PreprocessDatasetList({
    required this.scrollController,
    required this.trackballBehavior,
    required this.datasets,
    super.key,
  });

  final ScrollController scrollController;
  final TrackballBehavior trackballBehavior;
  final List<DataItem> datasets;

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
    return Scrollbar(
      child: ListView.builder(
        controller: widget.scrollController,
        cacheExtent: 32,
        itemExtent: 32,
        itemCount: widget.datasets.length,
        itemBuilder: (context, index) {
          return Consumer(
            builder: (context, ref, child) {
              final currentHighlightedIndex = ref.watch(
                preprocessProvider
                    .select((value) => value.currentHighlightedIndex),
              );
              final selectedDatasets = ref.watch(
                preprocessProvider.select((state) => state.selectedDataItems),
              );

              final dataset = widget.datasets[index];
              final selected = selectedDatasets.contains(dataset);

              return DataItemTile(
                index: index,
                dataset: dataset,
                highlighted: index == currentHighlightedIndex,
                selected: selected,
                onTap: () async {
                  if (selectedDatasets.isNotEmpty) {
                    final isJumpSelectMode = ref.read(
                      preprocessProvider
                          .select((value) => value.isJumpSelectMode),
                    );
                    if (isJumpSelectMode) {
                      await _notifier.jumpSelect(index);
                    } else {
                      _notifier.setSelectedDataset(index);
                    }
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
    );
  }
}
