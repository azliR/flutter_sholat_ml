import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:material_symbols_icons/symbols.dart';

enum HomePageNavigation { home, device }

@RoutePage()
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final AuthDeviceNotifier _authDeviceNotifier;

  late TabsRouter _tabsRouter;

  final _refreshKey = GlobalKey<RefreshIndicatorState>();

  void _onNavigationChanged(TabsRouter tabsRouter, int index) {
    if (index != tabsRouter.activeIndex) {
      tabsRouter.setActiveIndex(index);
    } else {
      tabsRouter.stackRouterOfIndex(index)?.popUntilRoot();
    }
  }

  @override
  void initState() {
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      authDeviceProvider,
      (previous, next) => handleAuthDeviceState(
        context,
        previous,
        next,
        onAuthDeviceSuccessState: () {
          _onNavigationChanged(_tabsRouter, 1);
          Navigator.pop(context);
        },
      ),
    );

    final currentDevice =
        ref.watch(authDeviceProvider.select((state) => state.currentDevice));
    final savedDevices =
        ref.watch(authDeviceProvider.select((state) => state.savedDevices));

    return AutoTabsRouter(
      curve: Curves.easeIn,
      routes: HomePageNavigation.values.map((section) {
        return switch (section) {
          HomePageNavigation.home => const SavedDevicesRoute(),
          HomePageNavigation.device => const DatasetsRoute(),
        };
      }).toList(),
      transitionBuilder: (context, child, animation) => FadeThroughTransition(
        animation: animation,
        secondaryAnimation: ReverseAnimation(animation),
        fillColor: Theme.of(context).canvasColor,
        child: child,
      ),
      builder: (context, child) {
        _tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          drawer: NavigationDrawer(
            selectedIndex: _tabsRouter.activeIndex,
            onDestinationSelected: (index) async {
              if (index == 0) {
                _onNavigationChanged(_tabsRouter, index);
                Navigator.pop(context);
              } else if (index - 1 < savedDevices.length) {
                final deviceIndex = index - 1;
                final device = savedDevices[deviceIndex];
                if (device == currentDevice) {
                  _onNavigationChanged(_tabsRouter, index);
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
                icon: _tabsRouter.activeIndex == 0
                    ? const Icon(Symbols.home_rounded, fill: 1)
                    : const Icon(Symbols.home_rounded),
                label: const Text('Home'),
              ),
              const Divider(),
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
          body: child,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.large(
            onPressed: () async {
              await context.router.push(
                RecordRoute(
                  device: _authDeviceNotifier.bluetoothDevice!,
                  services: _authDeviceNotifier.services!,
                ),
              );
              await _refreshKey.currentState?.show();
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
