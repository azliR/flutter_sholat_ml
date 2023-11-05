import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/components/need_review_datasets_body_component.dart';
import 'package:flutter_sholat_ml/modules/home/components/reviewed_dataset_body_component.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
            _needReviewRefreshKey.currentState?.show();
            _reviewedRefreshKey.currentState?.show();
          case DeleteDatasetFailureState():
            context.loaderOverlay.hide();
            _needReviewRefreshKey.currentState?.show();
            _reviewedRefreshKey.currentState?.show();
            showErrorSnackbar(context, 'Failed to delete dataset');
          case DownloadDatasetProgressState():
            final csvProgress = presentationState.csvProgress;
            final videoProgress = presentationState.videoProgress;
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
                            ],
                            if (videoProgress != null) ...[
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: videoProgress,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Downloading video at ${(videoProgress * 100).toStringAsFixed(0)}%',
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          case DownloadDatasetSuccessState():
            context.loaderOverlay.hide();
            _notifier.loadDatasetFromDisk(
              dataset: presentationState.dataset,
              isReviewedDataset: true,
            );
            showSnackbar(context, 'Dataset downloaded succesfully!');
          case DownloadDatasetFailureState():
            showErrorSnackbar(context, 'Failed to download dataset!');
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
}
