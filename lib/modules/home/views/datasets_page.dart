import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/home/home_notifier.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class DatasetsPage extends ConsumerStatefulWidget {
  const DatasetsPage({super.key});

  @override
  ConsumerState<DatasetsPage> createState() => _DatasetsPageState();
}

class _DatasetsPageState extends ConsumerState<DatasetsPage> {
  late final HomeNotifier _notifier;
  late final AuthDeviceNotifier _authDeviceNotifier;

  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    _notifier = ref.read(homeProvider.notifier);
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.loadDatasetsFromDisk();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(homeProvider.select((state) => state.isLoading));
    final datasetPaths =
        ref.watch(homeProvider.select((state) => state.datasetPaths));

    final savedDevices =
        ref.watch(authDeviceProvider.select((state) => state.savedDevices));

    return Material(
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Datasets'),
            actions: [
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
                          await context.router
                              .push(const DiscoverDeviceRoute());
                        } else {
                          await context.router.push(const SavedDevicesRoute());
                        }
                      }
                    },
                    child: const Text('Delete this device'),
                  ),
                ],
                child: const Icon(Symbols.more_vert_rounded),
              ),
            ],
          ),
          if (isLoading)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(),
            ),
          if (datasetPaths.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No datasets found'),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final datasetPath = datasetPaths[index];
                final datasetName = datasetPath.split('/').last;

                return RoundedListTile(
                  title: Text(
                    datasetName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                          await _notifier.deleteDataset(datasetPath);
                          await _refreshKey.currentState?.show();
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                    child: const Icon(Symbols.more_vert_rounded),
                  ),
                  onTap: () {},
                );
              },
              childCount: datasetPaths.length,
            ),
          ),
        ],
      ),
    );
  }
}
