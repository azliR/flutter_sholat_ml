import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
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
  late final AuthDeviceNotifier _authDeviceNotifier;
  late final TabController _tabController;

  final _needReviewRefreshKey = GlobalKey<RefreshIndicatorState>();
  final _reviewedRefreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _showDeleteDialog({required void Function() action}) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete dataset(s)?'),
        content: const Text(
          'These datasets will be deleted and cannot be recover.',
        ),
        icon: const Icon(Symbols.delete_rounded, weight: 600),
        iconColor: colorScheme.error,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: action,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    _tabController = TabController(length: 2, vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(datasetsProvider, (previous, next) {
      if (previous?.presentationState != next.presentationState) {
        final presentationState = next.presentationState;
        switch (presentationState) {
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
          case DatasetsInitial():
            break;
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
                leading: IconButton(
                  onPressed: () {
                    if (isSelectMode) {
                      _notifier.clearSelections();
                    } else {
                      Scaffold.of(context).openDrawer();
                    }
                  },
                  icon: isSelectMode
                      ? const Icon(Symbols.clear_rounded)
                      : const Icon(Symbols.menu_rounded),
                ),
                actions: _buildAppBarActions(isSelectMode),
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      child: Text('Need review'),
                    ),
                    Tab(
                      child: Text('Reviewed'),
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

  List<Widget> _buildAppBarActions(bool isSelectMode) {
    return [
      if (!isSelectMode)
        MenuAnchor(
          builder: (context, controller, child) {
            return IconButton(
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
              leadingIcon: const Icon(Symbols.delete_rounded),
              onPressed: () async {
                final savedDevices = ref.read(authDeviceProvider).savedDevices;
                final device = savedDevices.firstWhere(
                  (savedDevice) =>
                      savedDevice.deviceId ==
                      _authDeviceNotifier.bluetoothDevice?.remoteId.str,
                );
                final success =
                    await _authDeviceNotifier.removeSavedDevice(device);
                if (success) {
                  if (!context.mounted) return;
                  if (savedDevices.isEmpty) {
                    await context.router.push(const DiscoverDeviceRoute());
                  } else {
                    await context.router.push(const SavedDevicesPage());
                  }
                }
              },
              child: const Text('Delete this device'),
            ),
          ],
          child: const Icon(Symbols.more_vert_rounded),
        )
      else ...[
        IconButton(
          onPressed: () => _showDeleteDialog(
            action: () async {
              Navigator.pop(context);
              await _notifier.deleteSelectedDatasets();
              await _needReviewRefreshKey.currentState?.show();
              await _reviewedRefreshKey.currentState?.show();
            },
          ),
          icon: const Icon(Symbols.delete_rounded),
        ),
        IconButton(
          onPressed: () => _notifier.onSelectAllDatasets(),
          icon: const Icon(Symbols.select_all_rounded),
        ),
      ],
    ];
  }
}
