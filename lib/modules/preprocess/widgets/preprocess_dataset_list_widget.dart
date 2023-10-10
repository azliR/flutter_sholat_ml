import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/modules/preprocess/widgets/dataset_tile_widget.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

final dontShowAgainProvider = StateProvider.autoDispose<bool>((ref) => false);

class PreprocessDatasetList extends ConsumerStatefulWidget {
  const PreprocessDatasetList({
    required this.scrollController,
    required this.trackballBehavior,
    required this.datasets,
    super.key,
  });

  final ScrollController scrollController;
  final TrackballBehavior trackballBehavior;
  final List<Dataset> datasets;

  @override
  ConsumerState<PreprocessDatasetList> createState() =>
      _PreprocessDatasetListState();
}

class _PreprocessDatasetListState extends ConsumerState<PreprocessDatasetList> {
  late final PreprocessNotifier _notifier;

  var _showWarning = true;

  Future<bool?> _showWarningDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final dontShowAgain = ref.watch(dontShowAgainProvider);
            return AlertDialog(
              title: const Text('Warning'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This dataset has been tagged. Are you sure you want to change the tag?',
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (value) {
                          ref
                              .read(dontShowAgainProvider.notifier)
                              .update((state) => value!);
                        },
                      ),
                      const Text("Don't show this again"),
                    ],
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    _showWarning = !dontShowAgain;
                  },
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                    _showWarning = !dontShowAgain;
                  },
                  child: const Text('Change tag'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
                preprocessProvider.select((state) => state.selectedDatasets),
              );

              final dataset = widget.datasets[index];
              final selected = selectedDatasets.contains(dataset);

              return DatasetTileWidget(
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
                      await _notifier.jumpSelect(
                        index,
                        onShowWarning: () async {
                          if (_showWarning) {
                            final result = await _showWarningDialog();
                            return result ?? false;
                          } else {
                            return true;
                          }
                        },
                      );
                    } else {
                      if (dataset.isLabeled && !selected && _showWarning) {
                        final result = await _showWarningDialog();
                        if (result == null || !result) return;
                      }
                      _notifier.onSelectedDatasetChanged(index);
                    }
                  }
                  _notifier.onCurrentHighlightedIndexChanged(index);
                  widget.trackballBehavior.showByIndex(index);
                },
                onLongPress: () async {
                  if (dataset.isLabeled && _showWarning) {
                    final result = await _showWarningDialog();
                    if (result == null || !result) return;
                  }
                  _notifier
                    ..onSelectedDatasetChanged(index)
                    ..onCurrentHighlightedIndexChanged(index);
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
