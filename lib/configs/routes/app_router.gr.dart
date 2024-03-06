// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i11;
import 'package:flutter/foundation.dart' as _i14;
import 'package:flutter/material.dart' as _i13;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as _i12;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_device_screen.dart'
    as _i1;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_with_xiaomi_account_screen.dart'
    as _i2;
import 'package:flutter_sholat_ml/core/splash/views/splash_screen.dart' as _i10;
import 'package:flutter_sholat_ml/features/datasets/views/datasets_page.dart'
    as _i3;
import 'package:flutter_sholat_ml/features/discover_devices/views/discover_device_screen.dart'
    as _i4;
import 'package:flutter_sholat_ml/features/home/views/home_screen.dart' as _i5;
import 'package:flutter_sholat_ml/features/labs/views/labs_page.dart' as _i6;
import 'package:flutter_sholat_ml/features/preprocess/views/preprocess_screen.dart'
    as _i7;
import 'package:flutter_sholat_ml/features/record/views/record_screen.dart'
    as _i8;
import 'package:flutter_sholat_ml/features/saved_devices/views/saved_devices_page.dart'
    as _i9;

abstract class $AppRouter extends _i11.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i11.PageFactory> pagesMap = {
    AuthDeviceRoute.name: (routeData) {
      final args = routeData.argsAs<AuthDeviceRouteArgs>();
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.AuthDeviceScreen(
          device: args.device,
          services: args.services,
          key: args.key,
        ),
      );
    },
    AuthWithXiaomiAccountRoute.name: (routeData) {
      final args = routeData.argsAs<AuthWithXiaomiAccountRouteArgs>();
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.AuthWithXiaomiAccountScreen(
          uri: args.uri,
          onAuthenticated: args.onAuthenticated,
          key: args.key,
        ),
      );
    },
    DatasetsPage.name: (routeData) {
      final args = routeData.argsAs<DatasetsPageArgs>(
          orElse: () => const DatasetsPageArgs());
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.DatasetsPage(
          onInitialised: args.onInitialised,
          key: args.key,
        ),
      );
    },
    DiscoverDeviceRoute.name: (routeData) {
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.DiscoverDeviceScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.HomeScreen(
          initialNavigation: args.initialNavigation,
          key: args.key,
        ),
      );
    },
    LabsPage.name: (routeData) {
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.LabsPage(),
      );
    },
    PreprocessRoute.name: (routeData) {
      final args = routeData.argsAs<PreprocessRouteArgs>();
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.PreprocessScreen(
          path: args.path,
          key: args.key,
        ),
      );
    },
    RecordRoute.name: (routeData) {
      final args = routeData.argsAs<RecordRouteArgs>();
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i8.RecordScreen(
          device: args.device,
          services: args.services,
          onRecordSuccess: args.onRecordSuccess,
          key: args.key,
        ),
      );
    },
    SavedDevicesPage.name: (routeData) {
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.SavedDevicesPage(),
      );
    },
    SplashRoute.name: (routeData) {
      return _i11.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i10.SplashScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.AuthDeviceScreen]
class AuthDeviceRoute extends _i11.PageRouteInfo<AuthDeviceRouteArgs> {
  AuthDeviceRoute({
    required _i12.BluetoothDevice device,
    required List<_i12.BluetoothService> services,
    _i13.Key? key,
    List<_i11.PageRouteInfo>? children,
  }) : super(
          AuthDeviceRoute.name,
          args: AuthDeviceRouteArgs(
            device: device,
            services: services,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'AuthDeviceRoute';

  static const _i11.PageInfo<AuthDeviceRouteArgs> page =
      _i11.PageInfo<AuthDeviceRouteArgs>(name);
}

class AuthDeviceRouteArgs {
  const AuthDeviceRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i12.BluetoothDevice device;

  final List<_i12.BluetoothService> services;

  final _i13.Key? key;

  @override
  String toString() {
    return 'AuthDeviceRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i2.AuthWithXiaomiAccountScreen]
class AuthWithXiaomiAccountRoute
    extends _i11.PageRouteInfo<AuthWithXiaomiAccountRouteArgs> {
  AuthWithXiaomiAccountRoute({
    required Uri uri,
    required void Function(String) onAuthenticated,
    _i13.Key? key,
    List<_i11.PageRouteInfo>? children,
  }) : super(
          AuthWithXiaomiAccountRoute.name,
          args: AuthWithXiaomiAccountRouteArgs(
            uri: uri,
            onAuthenticated: onAuthenticated,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'AuthWithXiaomiAccountRoute';

  static const _i11.PageInfo<AuthWithXiaomiAccountRouteArgs> page =
      _i11.PageInfo<AuthWithXiaomiAccountRouteArgs>(name);
}

class AuthWithXiaomiAccountRouteArgs {
  const AuthWithXiaomiAccountRouteArgs({
    required this.uri,
    required this.onAuthenticated,
    this.key,
  });

  final Uri uri;

  final void Function(String) onAuthenticated;

  final _i13.Key? key;

  @override
  String toString() {
    return 'AuthWithXiaomiAccountRouteArgs{uri: $uri, onAuthenticated: $onAuthenticated, key: $key}';
  }
}

/// generated route for
/// [_i3.DatasetsPage]
class DatasetsPage extends _i11.PageRouteInfo<DatasetsPageArgs> {
  DatasetsPage({
    void Function(
      _i13.GlobalKey<_i13.RefreshIndicatorState>,
      _i13.GlobalKey<_i13.RefreshIndicatorState>,
    )? onInitialised,
    _i13.Key? key,
    List<_i11.PageRouteInfo>? children,
  }) : super(
          DatasetsPage.name,
          args: DatasetsPageArgs(
            onInitialised: onInitialised,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'DatasetsPage';

  static const _i11.PageInfo<DatasetsPageArgs> page =
      _i11.PageInfo<DatasetsPageArgs>(name);
}

class DatasetsPageArgs {
  const DatasetsPageArgs({
    this.onInitialised,
    this.key,
  });

  final void Function(
    _i13.GlobalKey<_i13.RefreshIndicatorState>,
    _i13.GlobalKey<_i13.RefreshIndicatorState>,
  )? onInitialised;

  final _i13.Key? key;

  @override
  String toString() {
    return 'DatasetsPageArgs{onInitialised: $onInitialised, key: $key}';
  }
}

/// generated route for
/// [_i4.DiscoverDeviceScreen]
class DiscoverDeviceRoute extends _i11.PageRouteInfo<void> {
  const DiscoverDeviceRoute({List<_i11.PageRouteInfo>? children})
      : super(
          DiscoverDeviceRoute.name,
          initialChildren: children,
        );

  static const String name = 'DiscoverDeviceRoute';

  static const _i11.PageInfo<void> page = _i11.PageInfo<void>(name);
}

/// generated route for
/// [_i5.HomeScreen]
class HomeRoute extends _i11.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i5.HomeScreenNavigation initialNavigation =
        _i5.HomeScreenNavigation.savedDevice,
    _i13.Key? key,
    List<_i11.PageRouteInfo>? children,
  }) : super(
          HomeRoute.name,
          args: HomeRouteArgs(
            initialNavigation: initialNavigation,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i11.PageInfo<HomeRouteArgs> page =
      _i11.PageInfo<HomeRouteArgs>(name);
}

class HomeRouteArgs {
  const HomeRouteArgs({
    this.initialNavigation = _i5.HomeScreenNavigation.savedDevice,
    this.key,
  });

  final _i5.HomeScreenNavigation initialNavigation;

  final _i13.Key? key;

  @override
  String toString() {
    return 'HomeRouteArgs{initialNavigation: $initialNavigation, key: $key}';
  }
}

/// generated route for
/// [_i6.LabsPage]
class LabsPage extends _i11.PageRouteInfo<void> {
  const LabsPage({List<_i11.PageRouteInfo>? children})
      : super(
          LabsPage.name,
          initialChildren: children,
        );

  static const String name = 'LabsPage';

  static const _i11.PageInfo<void> page = _i11.PageInfo<void>(name);
}

/// generated route for
/// [_i7.PreprocessScreen]
class PreprocessRoute extends _i11.PageRouteInfo<PreprocessRouteArgs> {
  PreprocessRoute({
    required String path,
    _i14.Key? key,
    List<_i11.PageRouteInfo>? children,
  }) : super(
          PreprocessRoute.name,
          args: PreprocessRouteArgs(
            path: path,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'PreprocessRoute';

  static const _i11.PageInfo<PreprocessRouteArgs> page =
      _i11.PageInfo<PreprocessRouteArgs>(name);
}

class PreprocessRouteArgs {
  const PreprocessRouteArgs({
    required this.path,
    this.key,
  });

  final String path;

  final _i14.Key? key;

  @override
  String toString() {
    return 'PreprocessRouteArgs{path: $path, key: $key}';
  }
}

/// generated route for
/// [_i8.RecordScreen]
class RecordRoute extends _i11.PageRouteInfo<RecordRouteArgs> {
  RecordRoute({
    required _i12.BluetoothDevice device,
    required List<_i12.BluetoothService> services,
    required void Function() onRecordSuccess,
    _i13.Key? key,
    List<_i11.PageRouteInfo>? children,
  }) : super(
          RecordRoute.name,
          args: RecordRouteArgs(
            device: device,
            services: services,
            onRecordSuccess: onRecordSuccess,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'RecordRoute';

  static const _i11.PageInfo<RecordRouteArgs> page =
      _i11.PageInfo<RecordRouteArgs>(name);
}

class RecordRouteArgs {
  const RecordRouteArgs({
    required this.device,
    required this.services,
    required this.onRecordSuccess,
    this.key,
  });

  final _i12.BluetoothDevice device;

  final List<_i12.BluetoothService> services;

  final void Function() onRecordSuccess;

  final _i13.Key? key;

  @override
  String toString() {
    return 'RecordRouteArgs{device: $device, services: $services, onRecordSuccess: $onRecordSuccess, key: $key}';
  }
}

/// generated route for
/// [_i9.SavedDevicesPage]
class SavedDevicesPage extends _i11.PageRouteInfo<void> {
  const SavedDevicesPage({List<_i11.PageRouteInfo>? children})
      : super(
          SavedDevicesPage.name,
          initialChildren: children,
        );

  static const String name = 'SavedDevicesPage';

  static const _i11.PageInfo<void> page = _i11.PageInfo<void>(name);
}

/// generated route for
/// [_i10.SplashScreen]
class SplashRoute extends _i11.PageRouteInfo<void> {
  const SplashRoute({List<_i11.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i11.PageInfo<void> page = _i11.PageInfo<void>(name);
}
