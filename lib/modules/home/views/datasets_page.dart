import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/dialogs.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:intl/intl.dart';
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

  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _showDeleteDialog({required void Function() action}) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
  }

  Future<void> _tabListener() async {
    final index = _tabController.index;
    if (!mounted) return;

    if (index == 0 || index == 1) {
      final reviewedDatasetPaths =
          ref.read(datasetsProvider).reviewedDatasetPaths;
      if (reviewedDatasetPaths == null) {
        await _refreshKey.currentState?.show();
      }
    }
  }

  @override
  void initState() {
    _notifier = ref.read(datasetsProvider.notifier);
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_tabListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
    });

    super.initState();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_tabListener)
      ..dispose();
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
            showLoadingDialog(context);
          case DeleteDatasetSuccessState():
            Navigator.pop(context);
            _refreshKey.currentState?.show();
          case DeleteDatasetFailureState():
            Navigator.pop(context);
            _refreshKey.currentState?.show();
            showErrorSnackbar(context, 'Failed to delete dataset');
          case DatasetsInitial():
            break;
        }
      }
    });

    final needReviewDatasetPaths = ref.watch(
        datasetsProvider.select((state) => state.needReviewDatasetPaths));
    final reviewedDatasetPaths = ref
        .watch(datasetsProvider.select((state) => state.reviewedDatasetPaths));
    final isSelectMode = ref.watch(
      datasetsProvider.select((value) => value.selectedDatasetPaths.isNotEmpty),
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
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: () {
            return _notifier.loadDatasetsFromDisk(
              _tabController.index == 0
                  ? Directories.needReviewDir
                  : Directories.reviewedDir,
            );
          },
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
                _DatasetsBody(
                  datasetPaths: needReviewDatasetPaths ?? [],
                  refreshKey: _refreshKey,
                  isSelectMode: isSelectMode,
                ),
                _DatasetsBody(
                  datasetPaths: reviewedDatasetPaths ?? [],
                  refreshKey: _refreshKey,
                  isSelectMode: isSelectMode,
                ),
              ],
            ),
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
              await _refreshKey.currentState?.show();
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

class _DatasetsBody extends ConsumerWidget {
  const _DatasetsBody({
    required this.datasetPaths,
    required this.refreshKey,
    required this.isSelectMode,
    super.key,
  });

  final List<String> datasetPaths;
  final GlobalKey<RefreshIndicatorState> refreshKey;
  final bool isSelectMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(datasetsProvider.notifier);

    if (datasetPaths.isEmpty) {
      return const Center(
        child: Text('No datasets'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, kBottomNavigationBarHeight),
      itemCount: datasetPaths.length,
      itemBuilder: (context, index) {
        final datasetPath = datasetPaths[index];
        final datasetName = datasetPath.split('/').last;
        final dateTime = DateTime.tryParse(datasetName);
        final formattedDatasetName = dateTime == null
            ? datasetName
            : DateFormat("EEEE 'at' HH:mm - MMM yyy").format(dateTime);

        final isSelected = ref.watch(
          datasetsProvider.select(
            (value) => value.selectedDatasetPaths.contains(datasetPath),
          ),
        );

        return RoundedListTile(
          title: Text(
            formattedDatasetName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          selected: isSelected,
          leading: const Icon(Symbols.csv_rounded),
          trailing: MenuAnchor(
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
                  await notifier.deleteDataset(datasetPath);
                  await refreshKey.currentState?.show();
                },
                child: const Text('Delete'),
              ),
            ],
            child: const Icon(Symbols.more_vert_rounded),
          ),
          onTap: () {
            if (isSelectMode) {
              notifier.onSelectedDataset(datasetPath);
            } else {
              context.router.push(PreprocessRoute(path: datasetPath));
            }
          },
          onLongPress: () => notifier.onSelectedDataset(datasetPath),
        );
      },
    );
  }
}
