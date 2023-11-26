import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/constants/dimens.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/home/widgets/dataset_grid_tile_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:material_symbols_icons/symbols.dart';

class NeedReviewDatasetBody extends ConsumerStatefulWidget {
  const NeedReviewDatasetBody({
    required this.refreshKey,
    required this.pagingController,
    super.key,
  });

  final GlobalKey<RefreshIndicatorState> refreshKey;
  final PagingController<int, Dataset> pagingController;

  @override
  ConsumerState<NeedReviewDatasetBody> createState() =>
      _NeedReviewDatasetState();
}

class _NeedReviewDatasetState extends ConsumerState<NeedReviewDatasetBody> {
  late final DatasetsNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RefreshIndicator(
      key: widget.refreshKey,
      onRefresh: () async {
        _notifier.refreshDatasets(isReviewedDataset: false);
        widget.pagingController.refresh();
        return Future.delayed(const Duration(seconds: 1));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Card(
                    color: colorScheme.errorContainer,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    margin: const EdgeInsets.all(8),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Symbols.warning_rounded,
                              color: colorScheme.error,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Be careful!',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Dataset that saved in local will deleted when the app uninstalled.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    Dimens.bottomListPadding,
                  ),
                  sliver: _buildGrid(constraints),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(BoxConstraints constraints) {
    final crossAxisCount = constraints.maxWidth ~/ 180;
    final aspectRatio = constraints.maxWidth / (crossAxisCount * 200) - 0.1;

    return PagedSliverGrid(
      pagingController: widget.pagingController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: aspectRatio,
      ),
      builderDelegate: PagedChildBuilderDelegate<Dataset>(
        noItemsFoundIndicatorBuilder: (context) {
          return IllustrationWidget(
            type: IllustrationWidgetType.noData,
            actions: [
              FilledButton.tonalIcon(
                onPressed: () => _notifier.importDatasets(),
                label: const Text('Import datasets'),
                icon: const Icon(Symbols.upload_rounded),
              ),
              FilledButton.tonalIcon(
                onPressed: () => widget.refreshKey.currentState?.show(),
                label: const Text('Refresh'),
                icon: const Icon(Symbols.refresh_rounded),
              ),
            ],
          );
        },
        firstPageErrorIndicatorBuilder: (context) {
          return IllustrationWidget(
            type: IllustrationWidgetType.error,
            actions: [
              FilledButton.tonalIcon(
                onPressed: () => widget.refreshKey.currentState?.show(),
                label: const Text('Refresh'),
                icon: const Icon(Symbols.refresh_rounded),
              ),
            ],
          );
        },
        itemBuilder: (context, rawDataset, index) {
          return Consumer(
            builder: (context, ref, child) {
              final dataset = ref.watch(
                datasetsProvider.select(
                  (state) => state.needReviewDatasets.firstWhere(
                    (dataset) => dataset.property.id == rawDataset.property.id,
                    orElse: () => rawDataset,
                  ),
                ),
              );
              final selected = ref.watch(
                datasetsProvider.select(
                  (state) => state.selectedDatasetIndexes.contains(index),
                ),
              );
              return DatasetGridTile(
                labeled: false,
                dataset: dataset,
                selected: selected,
                onInitialise: () async {
                  if (dataset.thumbnail == null && dataset.path != null) {
                    await _notifier.getThumbnailAt(
                      index,
                      dataset: dataset,
                      isReviewedDatasets: false,
                    );
                  }
                },
                onTap: () async {
                  final isSelectMode = ref.read(
                    datasetsProvider.select(
                      (value) => value.selectedDatasetIndexes.isNotEmpty,
                    ),
                  );

                  if (isSelectMode) {
                    _notifier.onSelectedDataset(index);
                    return;
                  }
                  await context.router
                      .push(PreprocessRoute(path: dataset.path!));
                  // await _notifier.loadDatasetFromDisk(
                  //   dataset: dataset,
                  //   isReviewedDataset: false,
                  //   createDirIfNotExist: false,
                  // );
                },
                onLongPress: () => _notifier.onSelectedDataset(index),
                action: _buildMenu(index, dataset.path),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenu(int index, String? datasetPath) {
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
        if (datasetPath != null) ...[
          MenuItemButton(
            leadingIcon: const Icon(Symbols.share_rounded),
            onPressed: () async {
              await _notifier.exportAndShareDatasets([datasetPath]);
            },
            child: const Text('Export & share'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Symbols.delete_rounded),
            onPressed: () async {
              await _notifier.deleteDatasetAt(
                index,
                isReviewedDatasets: false,
              );
            },
            child: const Text('Delete from device'),
          ),
        ],
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
