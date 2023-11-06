import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/components/need_review_datasets_body_component.dart';
import 'package:flutter_sholat_ml/modules/home/components/reviewed_dataset_body_component.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class DatasetsPage extends ConsumerStatefulWidget {
  const DatasetsPage({super.key});

  @override
  ConsumerState<DatasetsPage> createState() => _DatasetsPageState();
}

class _DatasetsPageState extends ConsumerState<DatasetsPage>
    with SingleTickerProviderStateMixin {
  late final DatasetsNotifier _notifier;
  late final TabController _tabController;

  final _needReviewRefreshKey = GlobalKey<RefreshIndicatorState>();
  final _reviewedRefreshKey = GlobalKey<RefreshIndicatorState>();

  void _showDownloadProgressDialog(double? csvProgress, double? videoProgress) {
    final textTheme = Theme.of(context).textTheme;

    context.loaderOverlay.show(
      widget: Center(
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
      ),
    );
  }

  void _showExportProgressDialog(double progress) {
    final textTheme = Theme.of(context).textTheme;

    context.loaderOverlay.show(
      widget: Center(
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
      ),
    );
  }

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);

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
          case DeleteDatasetSuccessState():
            context.loaderOverlay.hide();
            Future.wait(
              presentationState.paths.map((path) async {
                await _notifier.refreshDatasetDownloadStatus(path);
              }),
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
            _notifier
                .refreshDatasetDownloadStatus(presentationState.dataset.path!);
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
            showSnackbar(context, 'Datasets successfully imported!');
          case ImportDatasetFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, 'Failed to import datasets');
        }
      }
    });

    final isSelectMode = ref.watch(
      datasetsProvider.select((value) => value.selectedDatasets.isNotEmpty),
    );

    return WillPopScope(
      onWillPop: () async {
        if (isSelectMode) {
          _notifier.clearSelections();
          return false;
        }
        return true;
      },
      child: Material(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar.medium(
                title: const Text('Datasets'),
                actions: [
                  _buildMenu(),
                ],
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: data.size.width > 480,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      child: Text('Local'),
                    ),
                    Tab(
                      child: Text('Uploaded'),
                    ),
                  ],
                ),
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
                refreshKey: _needReviewRefreshKey,
                isSelectMode: isSelectMode,
              ),
              ReviewedDatasetBody(
                refreshKey: _reviewedRefreshKey,
                isSelectMode: isSelectMode,
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
          child: const Text('Import dataset'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
