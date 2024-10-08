import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/constants/dimens.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/features/datasets/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/features/datasets/widgets/dataset_grid_tile_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReviewedDatasetBody extends ConsumerStatefulWidget {
  const ReviewedDatasetBody({
    required this.pagingController,
    required this.refreshKey,
    super.key,
  });

  final PagingController<int, Dataset> pagingController;
  final GlobalKey<RefreshIndicatorState> refreshKey;

  @override
  ConsumerState<ReviewedDatasetBody> createState() => _ReviewedDatasetState();
}

class _ReviewedDatasetState extends ConsumerState<ReviewedDatasetBody> {
  late final DatasetsNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: widget.refreshKey,
      onRefresh: () async {
        _notifier.refreshDatasets(isReviewedDataset: true);
        widget.pagingController.refresh();
        return Future.delayed(const Duration(seconds: 1));
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            child: PagedGridView(
              pagingController: widget.pagingController,
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                Dimens.bottomListPadding,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 720,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 108,
              ),
              builderDelegate: PagedChildBuilderDelegate<Dataset>(
                noItemsFoundIndicatorBuilder: (context) {
                  return IllustrationWidget(
                    icon: const Icon(Symbols.cloud_off_rounded),
                    title: const Text('No uploaded datasets found!'),
                    description: const Text(
                      'You can upload datasets when reviewing datasets. ☁️',
                    ),
                    actions: [
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
                    icon: const Icon(Symbols.cloud_off_rounded),
                    title: const Text('Oops!'),
                    description: const Text(
                      'We had trouble loading the datasets. Could you please give it another try?',
                    ),
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
                          (state) => state.reviewedDatasets.firstWhere(
                            (dataset) =>
                                dataset.property.id == rawDataset.property.id,
                            orElse: () => rawDataset,
                          ),
                        ),
                      );
                      final lastOpened = ref.watch(
                        datasetsProvider.select(
                          (state) =>
                              state.lastOpenedDatasetId == dataset.property.id,
                        ),
                      );

                      return DatasetGridTile(
                        dataset: dataset,
                        selected: false,
                        labeled: true,
                        lastOpened: lastOpened,
                        // onInitialise: () async {
                        // if (dataset.thumbnail == null &&
                        //     dataset.path != null) {
                        //   await _notifier.getThumbnailAt(
                        //     index,
                        //     dataset: dataset,
                        //     isReviewedDatasets: true,
                        //   );
                        // }
                        // },
                        onTap: () async {
                          _notifier.setLastOpenedDatasetId(dataset.property.id);

                          await context.router
                              .push(PreprocessRoute(path: dataset.path!));
                          // if (dataset.downloaded ?? false) {
                          //   return;
                          // }
                          // await _notifier.downloadDatasetAt(
                          //   index,
                          //   dataset: dataset,
                          // );
                        },
                        // action: _buildMenu(index, dataset),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // MenuAnchor _buildMenu(int index, Dataset dataset) {
  //   final datasetPath = dataset.path;

  //   return MenuAnchor(
  //     builder: (context, controller, child) {
  //       return IconButton(
  //         style: IconButton.styleFrom(
  //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  //         ),
  //         iconSize: 20,
  //         onPressed: () {
  //           if (controller.isOpen) {
  //             controller.close();
  //           } else {
  //             controller.open();
  //           }
  //         },
  //         icon: child!,
  //       );
  //     },
  //     menuChildren: [
  //       MenuItemButton(
  //         leadingIcon: const Icon(Symbols.download_rounded),
  //         onPressed: () async {
  //           await _notifier.downloadDatasetAt(
  //             index,
  //             dataset: dataset,
  //             forceDownload: true,
  //           );
  //         },
  //         child: const Text('Force download dataset'),
  //       ),
  //       if (datasetPath != null && (dataset.downloaded ?? false)) ...[
  //         MenuItemButton(
  //           leadingIcon: const Icon(Symbols.share_rounded),
  //           onPressed: () async {
  //             await _notifier.exportAndShareDatasets([datasetPath]);
  //           },
  //           child: const Text('Export & share'),
  //         ),
  //         MenuItemButton(
  //           leadingIcon: const Icon(Symbols.delete_rounded),
  //           onPressed: () async {
  //             await _notifier.deleteDatasetAt(
  //               index,
  //               isReviewedDatasets: true,
  //             );
  //           },
  //           child: const Text('Delete from device'),
  //         ),
  //       ],
  //       MenuItemButton(
  //         leadingIcon: const Icon(Symbols.delete_forever_rounded),
  //         onPressed: () => _notifier.deleteDatasetFromCloud(index, dataset),
  //         child: const Text('Delete permanently'),
  //       ),
  //     ],
  //     child: const Icon(Symbols.more_vert_rounded),
  //   );
  // }
}
