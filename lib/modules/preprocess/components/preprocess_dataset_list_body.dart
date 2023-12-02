import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/data_item_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:video_player/video_player.dart';

class PreprocessDatasetList extends ConsumerStatefulWidget {
  const PreprocessDatasetList({
    required this.scrollController,
    required this.videoPlayerController,
    required this.trackballBehavior,
    required this.onDataItemPressed,
    super.key,
  });

  final ScrollController scrollController;
  final VideoPlayerController videoPlayerController;
  final TrackballBehavior trackballBehavior;
  final void Function(int index) onDataItemPressed;

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

    return Stack(
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
                  final selectedDataItemIndexes = ref.watch(
                    preprocessProvider
                        .select((state) => state.selectedDataItemIndexes),
                  );

                  final dataItem = dataItems[index];
                  final selected = selectedDataItemIndexes.contains(index);

                  return DataItemTile(
                    index: index,
                    dataItem: dataItem,
                    highlighted: index == currentHighlightedIndex,
                    selected: selected,
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
              onPressed: () {
                final lastLabeledIndex =
                    dataItems.lastIndexWhere((dataItem) => dataItem.isLabeled);
                widget.scrollController.jumpTo(lastLabeledIndex * 32);
                _notifier.setCurrentHighlightedIndex(lastLabeledIndex);
              },
              child: const Icon(Symbols.arrow_downward_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
