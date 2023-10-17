import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/widgets/dataset_grid_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

class NeedReviewDatasetBody extends ConsumerStatefulWidget {
  const NeedReviewDatasetBody({
    required this.refreshKey,
    required this.isSelectMode,
    super.key,
  });

  final GlobalKey<RefreshIndicatorState> refreshKey;
  final bool isSelectMode;

  @override
  ConsumerState<NeedReviewDatasetBody> createState() =>
      _NeedReviewDatasetState();
}

class _NeedReviewDatasetState extends ConsumerState<NeedReviewDatasetBody> {
  late final DatasetsNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (ref.read(datasetsProvider).needReviewDatasets.isEmpty) {
        widget.refreshKey.currentState?.show();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final datasets = ref.watch(
      datasetsProvider.select((state) => state.needReviewDatasets),
    );

    return RefreshIndicator(
      key: widget.refreshKey,
      onRefresh: () async {
        await _notifier.loadDatasetsFromDisk();
        return Future.delayed(const Duration(seconds: 1));
      },
      child: () {
        if (datasets.isEmpty) {
          return IllustrationWidget(
            type: IllustrationWidgetType.noData,
            action: FilledButton.tonalIcon(
              onPressed: () => widget.refreshKey.currentState?.show(),
              label: const Text('Refresh'),
              icon: const Icon(Symbols.refresh_rounded),
            ),
          );
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.97,
          ),
          padding:
              const EdgeInsets.fromLTRB(12, 8, 12, kBottomNavigationBarHeight),
          itemCount: datasets.length,
          itemBuilder: (context, index) {
            final dataset = datasets[index];

            return Consumer(
              builder: (context, ref, child) {
                final selected = ref.watch(
                  datasetsProvider.select(
                    (state) => state.selectedDatasets.contains(dataset),
                  ),
                );
                return DatasetGridTile(
                  tagged: false,
                  dataset: dataset,
                  selected: selected,
                  onTap: () async {
                    if (widget.isSelectMode) {
                      _notifier.onSelectedDataset(dataset);
                      return;
                    }
                    await context.router
                        .push(PreprocessRoute(path: dataset.path!));
                    await Future.wait([
                      _notifier.loadDatasetsFromDisk(),
                    ]);
                  },
                  onInitialise: () async {
                    if (dataset.thumbnail != null) return;

                    await _notifier.getThumbnail(
                      dataset: dataset,
                      isReviewedDatasets: false,
                    );
                  },
                  onLongPress: () => _notifier.onSelectedDataset(dataset),
                  action: _buildMenu(dataset.path),
                );
              },
            );
          },
        );
      }(),
    );
  }

  MenuAnchor _buildMenu(String? datasetPath) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          iconSize: 20,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: child!,
        );
      },
      menuChildren: [
        if (datasetPath != null)
          MenuItemButton(
            leadingIcon: const Icon(Symbols.delete_rounded),
            onPressed: () async {
              await _notifier.deleteDataset(datasetPath);
              await widget.refreshKey.currentState?.show();
            },
            child: const Text('Delete from device'),
          ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
