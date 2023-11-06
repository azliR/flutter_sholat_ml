import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/home/widgets/dataset_grid_tile_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
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
  static const _pageSize = 20;

  late final DatasetsNotifier _notifier;

  final _pagingController = PagingController<int, Dataset>(firstPageKey: 0);

  Future<void> _fetchPage(int pageKey) async {
    final (failure, datasets) = _notifier.getLocalDatasets(pageKey, _pageSize);

    if (failure != null) {
      _pagingController.error = failure.error;
      return;
    }

    final isLastPage = datasets!.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(datasets);
    } else {
      final nextPageKey = pageKey + datasets.length;
      _pagingController.appendPage(datasets, nextPageKey);
    }
  }

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);

    _pagingController.addPageRequestListener(_fetchPage);
    super.initState();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: widget.refreshKey,
      onRefresh: () async {
        _pagingController.refresh();
        return Future.delayed(const Duration(seconds: 1));
      },
      child: () {
        return PagedGridView(
          pagingController: _pagingController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.97,
          ),
          padding:
              const EdgeInsets.fromLTRB(12, 8, 12, kBottomNavigationBarHeight),
          builderDelegate: PagedChildBuilderDelegate<Dataset>(
            noItemsFoundIndicatorBuilder: (context) {
              return IllustrationWidget(
                type: IllustrationWidgetType.noData,
                actions: [
                  FilledButton.tonalIcon(
                    onPressed: () => _notifier.importDatasets(),
                    label: const Text('Import dataset'),
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
                        (dataset) =>
                            dataset.property.id == rawDataset.property.id,
                        orElse: () => rawDataset,
                      ),
                    ),
                  );
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
                      // await Future.wait([
                      //   _notifier.loadDatasetsFromDisk(),
                      // ]);
                    },
                    onInitialise: () async {
                      var updatedDataset = dataset;
                      if (dataset.path == null) {
                        updatedDataset = await _notifier.loadDatasetFromDisk(
                              dataset: dataset,
                              isReviewedDataset: false,
                            ) ??
                            dataset;
                      }
                      if (dataset.thumbnail == null &&
                          updatedDataset.path != null) {
                        await _notifier.getThumbnail(
                          dataset: updatedDataset,
                          isReviewedDatasets: false,
                        );
                      }
                    },
                    onLongPress: () => _notifier.onSelectedDataset(dataset),
                    action: _buildMenu(dataset.path),
                  );
                },
              );
            },
          ),
        );
      }(),
    );
  }

  Widget _buildMenu(String? datasetPath) {
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
              await _notifier.exportAndShareDataset(datasetPath);
            },
            child: const Text('Export & share'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Symbols.delete_rounded),
            onPressed: () async {
              await _notifier.deleteDataset(datasetPath);
              await widget.refreshKey.currentState?.show();
            },
            child: const Text('Delete from device'),
          ),
        ],
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
