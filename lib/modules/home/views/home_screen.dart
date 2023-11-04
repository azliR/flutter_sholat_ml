import 'dart:async';

import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';

enum HomeScreenNavigation { savedDevice, datasets }

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AuthDeviceNotifier _authDeviceNotifier;
  late final DatasetsNotifier _datasetNotifier;

  final _tabsRouterCompleter = Completer<TabsRouter>();

  var _currentPage = 0;

  List<PageRouteInfo<void>> get _routes =>
      HomeScreenNavigation.values.map((section) {
        return switch (section) {
          HomeScreenNavigation.savedDevice => const SavedDevicesPage(),
          HomeScreenNavigation.datasets => const DatasetsPage(),
        };
      }).toList();

  void _onNavigationChanged(TabsRouter tabsRouter, int index) {
    if (index != tabsRouter.activeIndex) {
      tabsRouter.setActiveIndex(index);
    } else {
      tabsRouter.stackRouterOfIndex(index)?.popUntilRoot();
    }
  }

  @override
  void initState() {
    _tabsRouterCompleter.future.then((value) {
      value.addListener(() {
        if (!context.mounted) return;
        setState(() {
          _currentPage = value.activeIndex;
        });
      });
    });
    _datasetNotifier = ref.read(datasetsProvider.notifier);
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    ref.listen(
      authDeviceProvider,
      (previous, next) => handleAuthDeviceState(
        context,
        previous,
        next,
        onAuthDeviceSuccessState: () async {
          _onNavigationChanged(await _tabsRouterCompleter.future, 1);
          if (!context.mounted) return;
          context.loaderOverlay.hide();
        },
      ),
    );

    final currentDevice =
        ref.watch(authDeviceProvider.select((state) => state.currentDevice));
    final savedDevices =
        ref.watch(authDeviceProvider.select((state) => state.savedDevices));

    return AutoTabsRouter(
      curve: Curves.easeInOut,
      routes: _routes,
      transitionBuilder: (context, child, animation) => FadeThroughTransition(
        animation: animation,
        secondaryAnimation: ReverseAnimation(animation),
        fillColor: Theme.of(context).canvasColor,
        child: child,
      ),
      builder: (context, child) {
        final tabRouter = context.tabsRouter;
        if (!_tabsRouterCompleter.isCompleted) {
          _tabsRouterCompleter.complete(tabRouter);
        }
        _currentPage = tabRouter.activeIndex;

        return Scaffold(
          drawer: NavigationDrawer(
            selectedIndex: tabRouter.activeIndex,
            onDestinationSelected: (index) async {
              if (index == 0) {
                _onNavigationChanged(tabRouter, index);
                Navigator.pop(context);
              } else if (index - 1 < savedDevices.length) {
                final deviceIndex = index - 1;
                final device = savedDevices[deviceIndex];

                if (device == currentDevice) {
                  _onNavigationChanged(tabRouter, index);
                  Navigator.pop(context);
                  return;
                }
                await _authDeviceNotifier.connectToSavedDevice(device);
              } else if (index - 1 == savedDevices.length) {
                await context.router.push(const DiscoverDeviceRoute());
              }
            },
            children: [
              const SizedBox(height: 16),
              NavigationDrawerDestination(
                icon: tabRouter.activeIndex == 0
                    ? const Icon(Symbols.home_rounded, fill: 1)
                    : const Icon(Symbols.home_rounded),
                label: const Text('Home'),
              ),
              const Divider(),
              ...savedDevices.map((device) {
                return NavigationDrawerDestination(
                  icon: const Icon(Symbols.bluetooth_rounded),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(device.deviceName),
                      GestureDetector(
                        onLongPress: () async {
                          Navigator.pop(context);
                          await Clipboard.setData(
                            ClipboardData(text: device.deviceId),
                          );

                          if (!context.mounted) return;
                          showSnackbar(context, 'Device ID Copied!');
                        },
                        child:
                            Text(device.deviceId, style: textTheme.bodySmall),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              const NavigationDrawerDestination(
                icon: Icon(Symbols.add_rounded),
                label: Text('Add device'),
              ),
            ],
          ),
          body: child,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: HomeScreenNavigation.values[_currentPage] !=
                  HomeScreenNavigation.datasets
              ? null
              : FloatingActionButton.large(
                  onPressed: () async {
                    await context.router.push(
                      RecordRoute(
                        device: _authDeviceNotifier.bluetoothDevice!,
                        services: _authDeviceNotifier.services!,
                        onRecordSuccess: () {
                          // _datasetNotifier.loadDatasetsFromDisk();
                        },
                      ),
                    );
                  },
                  child: const Icon(
                    Symbols.videocam_rounded,
                  ),
                ),
        );
      },
    );
  }
}
