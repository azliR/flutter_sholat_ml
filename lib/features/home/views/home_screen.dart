import 'dart:async';

import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/features/labs/blocs/labs/labs_notifer.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';

enum HomeScreenNavigationTab { savedDevice, datasets, labs }

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
    this.initialNavigation = HomeScreenNavigationTab.savedDevice,
    super.key,
  });

  final HomeScreenNavigationTab initialNavigation;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _tabsRouterCompleter = Completer<TabsRouter>();
  final _needReviewRefreshKeyCompleter =
      Completer<GlobalKey<RefreshIndicatorState>>();

  var _currentPage = 0;

  List<PageRouteInfo<dynamic>> get _routes =>
      HomeScreenNavigationTab.values.map((section) {
        return switch (section) {
          HomeScreenNavigationTab.savedDevice => const SavedDevicesPage(),
          HomeScreenNavigationTab.datasets => DatasetsPage(
              onInitialised: (
                needReviewRefreshKey,
                reviewedRefreshKey,
              ) {
                _needReviewRefreshKeyCompleter.complete(reviewedRefreshKey);
              },
            ),
          HomeScreenNavigationTab.labs => const LabsPage(),
        } as PageRouteInfo<dynamic>;
      }).toList();

  List<AdaptiveScaffoldDestination> get _destinations {
    return HomeScreenNavigationTab.values.map((section) {
      switch (section) {
        case HomeScreenNavigationTab.savedDevice:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.watch_rounded),
            selectedIcon: Icon(Symbols.watch_rounded, fill: 1),
            label: 'Devices',
          );
        case HomeScreenNavigationTab.datasets:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.dataset_rounded),
            selectedIcon: Icon(Symbols.dataset_rounded, fill: 1),
            label: 'Datasets',
          );
        case HomeScreenNavigationTab.labs:
          return const AdaptiveScaffoldDestination(
            icon: Icon(Symbols.model_training_rounded),
            selectedIcon: Icon(Symbols.model_training_rounded, fill: 1),
            label: 'Models',
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

  Future<void> _onAddDevicePressed() async {
    await context.router.push(const DiscoverDeviceRoute());
  }

  Future<void> _onRecordPressed() async {
    final currentBluetoothDevice =
        ref.read(authDeviceProvider).currentBluetoothDevice;
    final currentServices = ref.read(authDeviceProvider).currentServices;

    if (currentBluetoothDevice == null || currentServices == null) {
      showSnackbar(context, 'No connected device found');
      final tabRouter = await _tabsRouterCompleter.future;
      tabRouter.setActiveIndex(HomeScreenNavigationTab.savedDevice.index);
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

  Future<void> _onAddModelPressed() async {
    await ref.read(labsProvider.notifier).pickModel();
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
    final size = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final padding = MediaQuery.paddingOf(context);

    final NavigationType navigationType;
    if (size.width < 600) {
      if (orientation == Orientation.portrait) {
        navigationType = NavigationType.bottom;
      } else {
        navigationType = NavigationType.rail;
      }
    } else if (size.width < 1280) {
      navigationType = NavigationType.rail;
    } else {
      navigationType = NavigationType.drawer;
    }
    final navigationTab = HomeScreenNavigationTab.values[_currentPage];

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
        fillColor: colorScheme.background,
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
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButton: () {
            if (navigationType != NavigationType.bottom) return null;

            return _buildLargeFAB(navigationTab);
          }(),
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
                    SizedBox(height: padding.top + 16),
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
                        child: _buildExtendedFAB(navigationTab),
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
                  leading: _buildFAB(navigationTab),
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

  Widget _buildLargeFAB(HomeScreenNavigationTab navigationTab) {
    return switch (navigationTab) {
      HomeScreenNavigationTab.savedDevice => FloatingActionButton.large(
          key: const ValueKey('add_device'),
          tooltip: 'Record',
          onPressed: _onAddDevicePressed,
          child: const Icon(Symbols.add_rounded),
        ),
      HomeScreenNavigationTab.datasets => FloatingActionButton.large(
          key: const ValueKey('record'),
          tooltip: 'Record',
          onPressed: _onRecordPressed,
          child: const Icon(Symbols.videocam_rounded),
        ),
      HomeScreenNavigationTab.labs => FloatingActionButton.large(
          key: const ValueKey('add_model'),
          tooltip: 'Add model',
          onPressed: _onAddModelPressed,
          child: const Icon(Symbols.add_rounded),
        ),
    };
  }

  Widget _buildFAB(HomeScreenNavigationTab navigationTab) {
    return AnimatedSwitcher(
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      duration: const Duration(milliseconds: 250),
      child: switch (navigationTab) {
        HomeScreenNavigationTab.savedDevice => FloatingActionButton(
            key: const ValueKey('add_device'),
            tooltip: 'Record',
            elevation: 2,
            onPressed: _onAddDevicePressed,
            child: const Icon(Symbols.add_rounded),
          ),
        HomeScreenNavigationTab.datasets => FloatingActionButton(
            key: const ValueKey('record'),
            tooltip: 'Record',
            elevation: 2,
            onPressed: _onRecordPressed,
            child: const Icon(Symbols.videocam_rounded),
          ),
        HomeScreenNavigationTab.labs => FloatingActionButton(
            key: const ValueKey('add_model'),
            tooltip: 'Add model',
            elevation: 2,
            onPressed: _onAddModelPressed,
            child: const Icon(Symbols.add_rounded),
          ),
      },
    );
  }

  Widget _buildExtendedFAB(HomeScreenNavigationTab navigationTab) {
    return AnimatedSwitcher(
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      duration: const Duration(milliseconds: 250),
      child: switch (navigationTab) {
        HomeScreenNavigationTab.savedDevice => FloatingActionButton.extended(
            key: const ValueKey('add_device'),
            tooltip: 'Record',
            elevation: 2,
            onPressed: _onAddDevicePressed,
            icon: const Icon(Symbols.add_rounded),
            label: const Text('Add device'),
          ),
        HomeScreenNavigationTab.datasets => FloatingActionButton.extended(
            key: const ValueKey('record'),
            tooltip: 'Record',
            elevation: 2,
            onPressed: _onRecordPressed,
            icon: const Icon(Symbols.videocam_rounded),
            label: const Text('Record'),
          ),
        HomeScreenNavigationTab.labs => FloatingActionButton.extended(
            key: const ValueKey('add_model'),
            tooltip: 'Add model',
            elevation: 2,
            onPressed: _onAddModelPressed,
            icon: const Icon(Symbols.add_rounded),
            label: const Text('Add model'),
          ),
      },
    );
  }
}
