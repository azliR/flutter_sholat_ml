import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/constants/dimens.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/home/widgets/dataset_grid_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReviewedDatasetBody extends ConsumerStatefulWidget {
  const ReviewedDatasetBody({
    required this.refreshKey,
    required this.isSelectMode,
    super.key,
  });

  final GlobalKey<RefreshIndicatorState> refreshKey;
  final bool isSelectMode;

  @override
  ConsumerState<ReviewedDatasetBody> createState() => _ReviewedDatasetState();
}

class _ReviewedDatasetState extends ConsumerState<ReviewedDatasetBody> {
  late final DatasetsNotifier _notifier;
  FirestoreQueryBuilderSnapshot<Dataset>? _snapshot;

  var _datasetsKey = UniqueKey();

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
        setState(() {
          _datasetsKey = UniqueKey();
        });
        return Future.delayed(const Duration(seconds: 1));
      },
      child: FirestoreQueryBuilder<Dataset>(
        key: _datasetsKey,
        query: _notifier.reviewedDatasetsQuery,
        builder: (context, snapshot, _) {
          _snapshot ??= snapshot;

          if (snapshot.hasError) {
            return IllustrationWidget(
              type: IllustrationWidgetType.error,
              action: FilledButton.tonalIcon(
                onPressed: () => widget.refreshKey.currentState?.show(),
                label: const Text('Refresh'),
                icon: const Icon(Symbols.refresh_rounded),
              ),
            );
          }
          if (snapshot.docs.isEmpty) {
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
              childAspectRatio: 0.87,
            ),
            padding:
                const EdgeInsets.fromLTRB(12, 8, 12, Dimens.bottomListPadding),
            itemCount: snapshot.docs.length,
            itemBuilder: (context, index) {
              if (snapshot.hasMore && index + 1 == snapshot.docs.length) {
                snapshot.fetchMore();
              }

              final rawDataset = snapshot.docs[index].data();

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
                      (state) => state.selectedDatasets.contains(dataset),
                    ),
                  );

                  return DatasetGridTile(
                    dataset: dataset,
                    selected: selected,
                    tagged: true,
                    onTap: () async {
                      if (dataset.downloaded ?? false) {
                        await context.router
                            .push(PreprocessRoute(path: dataset.path!));
                        return;
                      }
                      await _notifier.downloadDataset(dataset);
                    },
                    onInitialise: () async {
                      var updatedDataset = dataset;
                      if (dataset.path == null) {
                        updatedDataset = await _notifier.loadDatasetFromDisk(
                              dataset: dataset,
                              isReviewedDataset: true,
                            ) ??
                            dataset;
                      }
                      if (dataset.thumbnail == null &&
                          updatedDataset.path != null) {
                        await _notifier.getThumbnail(
                          dataset: updatedDataset,
                          isReviewedDatasets: true,
                        );
                      }
                    },
                    action: _buildMenu(dataset),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  MenuAnchor _buildMenu(Dataset dataset) {
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
            await _notifier.downloadDataset(dataset, forceDownload: true);
          },
          child: const Text('Force download dataset'),
        ),
        if (datasetPath != null)
          MenuItemButton(
            leadingIcon: const Icon(Symbols.delete_rounded),
            onPressed: () async {
              await _notifier.deleteDataset(datasetPath);
              await widget.refreshKey.currentState?.show();
            },
            child: const Text('Delete from device'),
          ),
        MenuItemButton(
          leadingIcon: const Icon(Symbols.delete_forever_rounded),
          onPressed: () async {
            await _notifier.deleteDatasetFromCloud(dataset);
            await widget.refreshKey.currentState?.show();
          },
          child: const Text('Delete permanently'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
