import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/components/need_review_datasets_body_component.dart';
import 'package:flutter_sholat_ml/modules/home/components/reviewed_dataset_body_component.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/home/repositories/home_repository.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class DatasetsPage extends ConsumerStatefulWidget {
  const DatasetsPage({this.onInitialised, super.key});

  final void Function(
    GlobalKey<RefreshIndicatorState> needReviewKey,
    GlobalKey<RefreshIndicatorState> reviewedKey,
  )? onInitialised;

  @override
  ConsumerState<DatasetsPage> createState() => _DatasetsPageState();
}

class _DatasetsPageState extends ConsumerState<DatasetsPage>
    with SingleTickerProviderStateMixin {
  late final DatasetsNotifier _notifier;
  late final TabController _tabController;

  static const _pageSize = 20;

  final _needReviewPagingController =
      PagingController<int, Dataset>(firstPageKey: 0);
  final _reviewedPagingController =
      PagingController<int, Dataset>(firstPageKey: 0);
  final _needReviewRefreshKey = GlobalKey<RefreshIndicatorState>();
  final _reviewedRefreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _showDeleteDatasetsDialog({bool isLocalOnly = true}) async {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isLocalOnly
                ? 'Delete datasets?'
                : 'Delete datasets and cloud storage?',
          ),
          content: Text(
            isLocalOnly
                ? 'Deleting datasets will remove them from your device.'
                : 'Deleting datasets will remove them from your device and cloud storage.',
          ),
          icon: isLocalOnly
              ? const Icon(Symbols.delete_rounded)
              : const Icon(Symbols.delete_forever_rounded),
          iconColor: colorScheme.error,
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _notifier.deleteSelectedDatasets(isReviewedDatasets: false);
                _needReviewRefreshKey.currentState?.show();
              },
              child: const Text('Delete all'),
            ),
          ],
        );
      },
    );
  }

  void _showDownloadProgressDialog(double? csvProgress, double? videoProgress) {
    if (context.loaderOverlay.visible) {
      context.loaderOverlay.progress((csvProgress, videoProgress));
      return;
    }

    final textTheme = Theme.of(context).textTheme;

    context.loaderOverlay.show(
      widgetBuilder: (value) {
        final (csvProgress, videoProgress) =
            value as (double?, double?)? ?? (null, null);

        return Center(
          child: SizedBox(
            width: 240,
            child: Card(
              elevation: 8,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Downloading dataset',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    if (csvProgress == null && videoProgress == null) ...[
                      LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      const Text('Preparing...'),
                    ] else ...[
                      if (csvProgress != null) ...[
                        LinearProgressIndicator(
                          value: csvProgress,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Downloading csv at ${(csvProgress * 100).toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (videoProgress != null) ...[
                        LinearProgressIndicator(
                          value: videoProgress,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Downloading video at ${(videoProgress * 100).toStringAsFixed(0)}%',
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showExportProgressDialog(double progress) {
    if (context.loaderOverlay.visible) {
      context.loaderOverlay.progress(progress);
      return;
    }

    final textTheme = Theme.of(context).textTheme;

    context.loaderOverlay.show(
      progress: 0.0,
      widgetBuilder: (value) {
        final progress = value as double? ?? 0.0;

        return Center(
          child: SizedBox(
            width: 240,
            child: Card(
              elevation: 8,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Exporting dataset',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exporting at ${(progress * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchLocalDatasetsPage(int pageKey) async {
    final (failure, datasets) =
        await _notifier.getLocalDatasets(pageKey, _pageSize);

    if (failure != null) {
      _needReviewPagingController.error = failure.error;
      return;
    }

    final isLastPage = datasets!.length < _pageSize;
    if (isLastPage) {
      _needReviewPagingController.appendLastPage(datasets);
    } else {
      final nextPageKey = pageKey + datasets.length;
      _needReviewPagingController.appendPage(datasets, nextPageKey);
    }
  }

  Future<void> _fetchCloudDatasetsPage(int pageKey) async {
    final (failure, datasets) =
        await _notifier.getCloudDatasets(pageKey, _pageSize);

    if (failure != null) {
      _reviewedPagingController.error = failure.error;
      return;
    }

    final isLastPage = datasets!.length < _pageSize;
    if (isLastPage) {
      _reviewedPagingController.appendLastPage(datasets);
    } else {
      final nextPageKey = pageKey + datasets.length;
      _reviewedPagingController.appendPage(datasets, nextPageKey);
    }
  }

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);

    widget.onInitialised?.call(_needReviewRefreshKey, _reviewedRefreshKey);

    _needReviewPagingController.addPageRequestListener(_fetchLocalDatasetsPage);
    _reviewedPagingController.addPageRequestListener(_fetchCloudDatasetsPage);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _tabController.previousIndex) {
        _notifier.clearSelections();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _needReviewPagingController.dispose();
    _reviewedPagingController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);

    ref.listen(datasetsProvider, (previous, next) {
      if (previous?.presentationState != next.presentationState) {
        final presentationState = next.presentationState;
        switch (presentationState) {
          case DatasetsInitial():
            break;
          case LoadDatasetsFailureState():
            showErrorSnackbar(context, 'Failed to load datasets');
          case DeleteDatasetLoadingState():
            context.loaderOverlay.show();
          case DeleteDatasetFromDiskSuccessState():
            context.loaderOverlay.hide();

            if (!presentationState.isReviewedDataset) {
              _needReviewPagingController.itemList =
                  ref.read(datasetsProvider).needReviewDatasets;

              final deletedLength = presentationState.deletedIndexes.length;
              showSnackbar(context, '$deletedLength dataset(s) deleted');
              return;
            }

            Future.wait(
              presentationState.deletedIndexes.map((index) async {
                await _notifier.refreshDatasetStatusAt(
                  index,
                  isReviewedDataset: presentationState.isReviewedDataset,
                );
              }),
            );
            showSnackbar(context, 'Dataset deleted from disk');
          case DeleteDatasetFromCloudSuccessState():
            showSnackbar(
              context,
              'Dataset deleted from cloud storage',
              hidePreviousSnackbar: true,
            );
          case DeleteDatasetFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, 'Failed to delete dataset');
          case DownloadDatasetProgressState():
            final csvProgress = presentationState.csvProgress;
            final videoProgress = presentationState.videoProgress;
            _showDownloadProgressDialog(csvProgress, videoProgress);
          case DownloadDatasetSuccessState():
            context.loaderOverlay.hide();
            _notifier.refreshDatasetStatusAt(
              presentationState.index,
              isReviewedDataset: true,
            );
            showSnackbar(context, 'Dataset downloaded succesfully!');
          case DownloadDatasetFailureState():
            showErrorSnackbar(context, 'Failed to download dataset!');
          case ExportDatasetProgressState():
            _showExportProgressDialog(presentationState.progress);
          case ExportDatasetSuccessState():
            context.loaderOverlay.hide();
          case ExportDatasetFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, 'Failed to export dataset');
          case ImportDatasetProgressState():
            context.loaderOverlay.show();
          case ImportDatasetSuccessState():
            context.loaderOverlay.hide();
            _needReviewRefreshKey.currentState?.show();
            showSnackbar(context, 'Datasets successfully imported!');
          case ImportDatasetFailureState():
            context.loaderOverlay.hide();
            switch (presentationState.failure.code as ImportDatasetErrorCode?) {
              case ImportDatasetErrorCode.canceled:
                break;
              case ImportDatasetErrorCode.unsupported:
                showErrorSnackbar(
                  context,
                  'The selected file is not supported. Only .shd files are supported.',
                );
              case ImportDatasetErrorCode.missingRequiredFiles:
                showErrorSnackbar(
                  context,
                  'The selected file is missing required files',
                );
              case null:
                showErrorSnackbar(context, 'Failed to import dataset');
            }
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final isSelectMode =
            ref.read(datasetsProvider).selectedDatasetIndexes.isNotEmpty;
        if (isSelectMode) {
          _notifier.clearSelections();
          return;
        }

        Navigator.pop(context);
      },
      child: Material(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              Consumer(
                builder: (context, ref, child) {
                  final selectedDatasetIndexes = ref.watch(
                    datasetsProvider
                        .select((value) => value.selectedDatasetIndexes),
                  );
                  final isSelectMode = selectedDatasetIndexes.isNotEmpty;

                  return SliverAppBar.medium(
                    title: const Text('Datasets'),
                    actions: [
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: () {
                          switch (_tabController.index) {
                            case 0:
                              _needReviewRefreshKey.currentState?.show();
                            case 1:
                              _reviewedRefreshKey.currentState?.show();
                          }
                        },
                        icon: const Icon(Symbols.refresh_rounded),
                      ),
                      if (isSelectMode && _tabController.index == 0) ...[
                        Consumer(
                          builder: (context, ref, child) {
                            final needReviewDatasets = ref.watch(
                              datasetsProvider
                                  .select((value) => value.needReviewDatasets),
                            );
                            if (selectedDatasetIndexes.length ==
                                needReviewDatasets.length) {
                              return const SizedBox();
                            }
                            return IconButton(
                              tooltip: 'Select all',
                              onPressed: () => _notifier.onSelectAllDatasets(),
                              icon: const Icon(Symbols.select_all_rounded),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: _showDeleteDatasetsDialog,
                          icon: const Icon(Symbols.delete_rounded),
                        ),
                        IconButton(
                          tooltip: 'Share & Export',
                          onPressed: () {
                            final datasets =
                                ref.read(datasetsProvider).needReviewDatasets;

                            _notifier.exportAndShareDatasets(
                              selectedDatasetIndexes
                                  .map((index) => datasets[index].path!)
                                  .toList(),
                            );
                          },
                          icon: const Icon(Symbols.share_rounded),
                        ),
                      ],
                      _buildMenu(),
                      const SizedBox(width: 12),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      isScrollable: data.size.width > 480,
                      tabs: const [
                        Tab(text: 'Local'),
                        Tab(text: 'Cloud'),
                      ],
                    ),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final isLoading = ref.watch(
                    datasetsProvider.select((state) => state.isLoading),
                  );
                  if (isLoading) {
                    return const SliverToBoxAdapter(
                      child: LinearProgressIndicator(),
                    );
                  }
                  return const SliverToBoxAdapter();
                },
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              NeedReviewDatasetBody(
                pagingController: _needReviewPagingController,
                refreshKey: _needReviewRefreshKey,
              ),
              ReviewedDatasetBody(
                pagingController: _reviewedPagingController,
                refreshKey: _reviewedRefreshKey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu() {
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
          leadingIcon: const Icon(Symbols.upload_rounded),
          onPressed: () async {
            await _notifier.importDatasets();
          },
          child: const Text('Import datasets'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
