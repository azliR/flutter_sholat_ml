import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/home/home_notifier.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
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

    return Scaffold(
      drawer: NavigationDrawer(
        onDestinationSelected: (index) {
          if (index == savedDevices.length) {
            context.router.push(const DeviceListRoute());
          }
        },
        children: [
          const SizedBox(height: 16),
          ...savedDevices.map((device) {
            return NavigationDrawerDestination(
              icon: const Icon(Symbols.bluetooth_rounded),
              label: Text(device.deviceName),
            );
          }),
          const Divider(),
          const NavigationDrawerDestination(
            icon: Icon(Symbols.add_rounded),
            label: Text('Add device'),
          ),
          const Divider(),
          const NavigationDrawerDestination(
            icon: Icon(Symbols.settings_rounded),
            label: Text('Settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: () {
          return _notifier.loadDatasetsFromDisk();
        },
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(title: Text('Home')),
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
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          await context.router.push(
            RecordRoute(
              device: _authDeviceNotifier.device,
              services: _authDeviceNotifier.services,
            ),
          );
          await _refreshKey.currentState?.show();
        },
        child: const Icon(
          Symbols.videocam_rounded,
        ),
      ),
    );
  }
}
