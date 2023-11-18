import 'dart:async';

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

class ReviewedDatasetBody extends ConsumerStatefulWidget {
  const ReviewedDatasetBody({super.key});

  @override
  ConsumerState<ReviewedDatasetBody> createState() => _ReviewedDatasetState();
}

class _ReviewedDatasetState extends ConsumerState<ReviewedDatasetBody> {
  static const _pageSize = 20;

  late final DatasetsNotifier _notifier;

  Future<void> _fetchPage(int pageKey) async {
    final (failure, datasets) =
        await _notifier.getCloudDatasets(pageKey, _pageSize);

    if (failure != null) {
      _notifier.reviewedPagingController.error = failure.error;
      return;
    }

    final isLastPage = datasets!.length < _pageSize;
    if (isLastPage) {
      _notifier.reviewedPagingController.appendLastPage(datasets);
    } else {
      final nextPageKey = pageKey + datasets.length;
      _notifier.reviewedPagingController.appendPage(datasets, nextPageKey);
    }
  }

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);

    _notifier.reviewedPagingController.addPageRequestListener(_fetchPage);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _notifier.reviewedRefreshKey,
      onRefresh: () async {
        _notifier.reviewedPagingController.refresh();
        return Future.delayed(const Duration(seconds: 1));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth ~/ 180;
          final aspectRatio =
              constraints.maxWidth / (crossAxisCount * 200) - 0.16;

          return PagedGridView(
            pagingController: _notifier.reviewedPagingController,
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              Dimens.bottomListPadding,
            ),
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
                      onPressed: () =>
                          _notifier.needReviewRefreshKey.currentState?.show(),
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
                      onPressed: () =>
                          _notifier.needReviewRefreshKey.currentState?.show(),
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
                        (state) => state.reviewedDatasets.firstWhere(
                          (dataset) =>
                              dataset.property.id == rawDataset.property.id,
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
                      dataset: dataset,
                      selected: selected,
                      labeled: true,
                      onTap: () async {
                        if (dataset.downloaded ?? false) {
                          await context.router
                              .push(PreprocessRoute(path: dataset.path!));
                          return;
                        }
                        await _notifier.downloadDatasetAt(
                          index,
                          dataset: dataset,
                        );
                      },
                      onInitialise: () async {
                        if (dataset.thumbnail == null && dataset.path != null) {
                          await _notifier.getThumbnailAt(
                            index,
                            dataset: dataset,
                            isReviewedDatasets: true,
                          );
                        }
                      },
                      action: _buildMenu(index, dataset),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  MenuAnchor _buildMenu(int index, Dataset dataset) {
    final datasetPath = dataset.path;

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
        MenuItemButton(
          leadingIcon: const Icon(Symbols.download_rounded),
          onPressed: () async {
            await _notifier.downloadDatasetAt(
              index,
              dataset: dataset,
              forceDownload: true,
            );
          },
          child: const Text('Force download dataset'),
        ),
        if (datasetPath != null)
          MenuItemButton(
            leadingIcon: const Icon(Symbols.delete_rounded),
            onPressed: () async {
              await _notifier.deleteDatasetAt(
                index,
                isReviewedDatasets: true,
              );
            },
            child: const Text('Delete from device'),
          ),
        MenuItemButton(
          leadingIcon: const Icon(Symbols.delete_forever_rounded),
          onPressed: () => _notifier.deleteDatasetFromCloud(index, dataset),
          child: const Text('Delete permanently'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
