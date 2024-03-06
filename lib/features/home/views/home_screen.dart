import 'dart:async';

import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';

enum HomeScreenNavigation { savedDevice, datasets, labs }

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
  const HomeScreen({
    this.initialNavigation = HomeScreenNavigation.savedDevice,
    super.key,
  });

  final HomeScreenNavigation initialNavigation;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _tabsRouterCompleter = Completer<TabsRouter>();
  final _needReviewRefreshKeyCompleter =
      Completer<GlobalKey<RefreshIndicatorState>>();

  var _currentPage = 0;

  List<PageRouteInfo<dynamic>> get _routes =>
      HomeScreenNavigation.values.map((section) {
        return switch (section) {
          HomeScreenNavigation.savedDevice => const SavedDevicesPage(),
          HomeScreenNavigation.datasets => DatasetsPage(
              onInitialised: (
                needReviewRefreshKey,
                reviewedRefreshKey,
              ) {
                _needReviewRefreshKeyCompleter.complete(reviewedRefreshKey);
              },
            ),
          HomeScreenNavigation.labs => const LabsPage(),
        } as PageRouteInfo<dynamic>;
      }).toList();

  List<AdaptiveScaffoldDestination> get _destinations {
    return HomeScreenNavigation.values.map((section) {
      switch (section) {
        case HomeScreenNavigation.savedDevice:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.watch_rounded),
            selectedIcon: Icon(Symbols.watch_rounded, fill: 1),
            label: 'Devices',
          );
        case HomeScreenNavigation.datasets:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.dataset_rounded),
            selectedIcon: Icon(Symbols.dataset_rounded, fill: 1),
            label: 'Datasets',
          );
        case HomeScreenNavigation.labs:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.experiment_rounded),
            selectedIcon: Icon(Symbols.experiment_rounded, fill: 1),
            label: 'Labs',
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
    final currentBluetoothDevice =
        ref.read(authDeviceProvider).currentBluetoothDevice;
    final currentServices = ref.read(authDeviceProvider).currentServices;

    if (currentBluetoothDevice == null || currentServices == null) {
      showSnackbar(context, 'No connected device found');
      final tabRouter = await _tabsRouterCompleter.future;
      tabRouter.setActiveIndex(HomeScreenNavigation.savedDevice.index);
      return;
    }
    await context.router.push(
      RecordRoute(
        device: currentBluetoothDevice,
        services: currentServices,
        onRecordSuccess: () async {
          if (!_needReviewRefreshKeyCompleter.isCompleted) return;
          final needReviewRefreshKey =
              await _needReviewRefreshKeyCompleter.future;
          await needReviewRefreshKey.currentState?.show();
        },
      ),
    );
  }

  @override
  void initState() {
    _tabsRouterCompleter.future.then((tabsController) {
      tabsController
        ..setActiveIndex(widget.initialNavigation.index)
        ..addListener(() {
          if (!context.mounted) return;
          setState(() {
            _currentPage = tabsController.activeIndex;
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
        onAuthDeviceSuccess: () async {
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
              Expanded(
                child: Padding(
                  padding: navigationType != NavigationType.bottom
                      ? const EdgeInsets.all(16)
                      : EdgeInsets.zero,
                  child: ClipRRect(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    borderRadius: navigationType != NavigationType.bottom
                        ? const BorderRadius.all(Radius.circular(24))
                        : BorderRadius.zero,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
