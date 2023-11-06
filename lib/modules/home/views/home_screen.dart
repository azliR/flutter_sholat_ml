import 'dart:async';

import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';

enum HomeScreenNavigation { savedDevice, datasets }

enum NavigationType { bottom, rail, drawer }

class AdaptiveScaffoldDestination {
  const AdaptiveScaffoldDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
  final String label;
  final Icon icon;
  final Icon selectedIcon;
}

@RoutePage()
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final AuthDeviceNotifier _authDeviceNotifier;

  final _tabsRouterCompleter = Completer<TabsRouter>();

  var _currentPage = 0;

  List<PageRouteInfo<void>> get _routes =>
      HomeScreenNavigation.values.map((section) {
        return switch (section) {
          HomeScreenNavigation.savedDevice => const SavedDevicesPage(),
          HomeScreenNavigation.datasets => const DatasetsPage(),
        };
      }).toList();

  List<AdaptiveScaffoldDestination> get _destinations {
    return HomeScreenNavigation.values.map((section) {
      switch (section) {
        case HomeScreenNavigation.savedDevice:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.watch),
            selectedIcon: Icon(Symbols.watch, fill: 1),
            label: 'Devices',
          );
        case HomeScreenNavigation.datasets:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.dataset),
            selectedIcon: Icon(Symbols.dataset, fill: 1),
            label: 'Datasets',
          );
      }
    }).toList();
  }

  void _onNavigationChanged(TabsRouter tabsRouter, int index) {
    if (index != tabsRouter.activeIndex) {
      tabsRouter.setActiveIndex(index);
    } else {
      tabsRouter.stackRouterOfIndex(index)?.popUntilRoot();
    }
  }

  Future<void> _onRecordPressed() async {
    final connectedDevice = _authDeviceNotifier.bluetoothDevice;
    if (connectedDevice == null) {
      showSnackbar(context, 'No connected device found');
      final tabRouter = await _tabsRouterCompleter.future;
      tabRouter.setActiveIndex(HomeScreenNavigation.savedDevice.index);
      return;
    }
    await context.router.push(
      RecordRoute(
        device: connectedDevice,
        services: _authDeviceNotifier.services!,
        onRecordSuccess: () {
          // _datasetNotifier.loadDatasetsFromDisk();
        },
      ),
    );
  }

  @override
  void initState() {
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    _tabsRouterCompleter.future.then((value) {
      value.addListener(() {
        if (!context.mounted) return;
        setState(() {
          _currentPage = value.activeIndex;
        });
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final data = MediaQuery.of(context);

    final NavigationType navigationType;
    if (data.size.width < 600) {
      if (data.orientation == Orientation.portrait) {
        navigationType = NavigationType.bottom;
      } else {
        navigationType = NavigationType.rail;
      }
    } else if (data.size.width < 1280) {
      navigationType = NavigationType.rail;
    } else {
      navigationType = NavigationType.drawer;
    }

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
        final tabsRouter = context.tabsRouter;
        if (!_tabsRouterCompleter.isCompleted) {
          _tabsRouterCompleter.complete(tabsRouter);
        }
        _currentPage = tabsRouter.activeIndex;
        return Scaffold(
          backgroundColor: ElevationOverlay.applySurfaceTint(
            colorScheme.surface,
            colorScheme.surfaceTint,
            2,
          ),
          bottomNavigationBar: navigationType == NavigationType.bottom
              ? NavigationBar(
                  selectedIndex: tabsRouter.activeIndex,
                  onDestinationSelected: (index) =>
                      _onNavigationChanged(tabsRouter, index),
                  destinations: _destinations
                      .map(
                        (destination) => NavigationDestination(
                          label: destination.label,
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                        ),
                      )
                      .toList(),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: navigationType == NavigationType.bottom
              ? FloatingActionButton.large(
                  tooltip: 'Record',
                  onPressed: _onRecordPressed,
                  child: const Icon(Symbols.videocam_rounded),
                )
              : null,
          body: Row(
            children: [
              if (navigationType == NavigationType.drawer)
                NavigationDrawer(
                  selectedIndex: tabsRouter.activeIndex,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onDestinationSelected: (index) =>
                      _onNavigationChanged(tabsRouter, index),
                  children: [
                    SizedBox(height: data.padding.top + 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Sholat-ML',
                        style: textTheme.titleMedium,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: FloatingActionButton.extended(
                          elevation: 2,
                          tooltip: 'Record',
                          onPressed: _onRecordPressed,
                          label: const Text('Record'),
                          icon: const Icon(Symbols.videocam_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._destinations.map(
                      (destination) => NavigationDrawerDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ),
                    ),
                  ],
                )
              else if (navigationType == NavigationType.rail)
                NavigationRail(
                  selectedIndex: _currentPage,
                  backgroundColor: Colors.transparent,
                  leading: FloatingActionButton(
                    elevation: 2,
                    tooltip: 'Record',
                    onPressed: _onRecordPressed,
                    child: const Icon(Symbols.videocam_rounded),
                  ),
                  labelType: NavigationRailLabelType.all,
                  groupAlignment: -0.2,
                  onDestinationSelected: (index) =>
                      _onNavigationChanged(tabsRouter, index),
                  destinations: _destinations
                      .map(
                        (destination) => NavigationRailDestination(
                          label: Text(destination.label),
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                        ),
                      )
                      .toList(),
                ),
              if (navigationType != NavigationType.bottom)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    ),
                  ),
                )
              else
                Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}
