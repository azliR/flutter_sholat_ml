// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i10;
import 'package:flutter/foundation.dart' as _i13;
import 'package:flutter/material.dart' as _i12;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as _i11;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_device_screen.dart'
    as _i1;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_with_xiaomi_account_screen.dart'
    as _i2;
import 'package:flutter_sholat_ml/core/splash/views/splash_screen.dart' as _i9;
import 'package:flutter_sholat_ml/features/discover_devices/views/discover_device_screen.dart'
    as _i4;
import 'package:flutter_sholat_ml/features/home/views/datasets_page.dart'
    as _i3;
import 'package:flutter_sholat_ml/features/home/views/home_screen.dart' as _i5;
import 'package:flutter_sholat_ml/features/home/views/saved_devices_page.dart'
    as _i8;
import 'package:flutter_sholat_ml/features/preprocess/views/preprocess_screen.dart'
    as _i6;
import 'package:flutter_sholat_ml/features/record/views/record_screen.dart'
    as _i7;

abstract class $AppRouter extends _i10.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i10.PageFactory> pagesMap = {
    AuthDeviceRoute.name: (routeData) {
      final args = routeData.argsAs<AuthDeviceRouteArgs>();
      return _i10.AutoRoutePage<dynamic>(
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
      return _i10.AutoRoutePage<dynamic>(
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
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.DatasetsPage(
          onInitialised: args.onInitialised,
          key: args.key,
        ),
      );
    },
    DiscoverDeviceRoute.name: (routeData) {
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.DiscoverDeviceScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.HomeScreen(
          initialNavigation: args.initialNavigation,
          key: args.key,
        ),
      );
    },
    PreprocessRoute.name: (routeData) {
      final args = routeData.argsAs<PreprocessRouteArgs>();
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.PreprocessScreen(
          path: args.path,
          key: args.key,
        ),
      );
    },
    RecordRoute.name: (routeData) {
      final args = routeData.argsAs<RecordRouteArgs>();
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.RecordScreen(
          device: args.device,
          services: args.services,
          onRecordSuccess: args.onRecordSuccess,
          key: args.key,
        ),
      );
    },
    SavedDevicesPage.name: (routeData) {
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.SavedDevicesPage(),
      );
    },
    SplashRoute.name: (routeData) {
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i9.SplashScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.AuthDeviceScreen]
class AuthDeviceRoute extends _i10.PageRouteInfo<AuthDeviceRouteArgs> {
  AuthDeviceRoute({
    required _i11.BluetoothDevice device,
    required List<_i11.BluetoothService> services,
    _i12.Key? key,
    List<_i10.PageRouteInfo>? children,
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

  static const _i10.PageInfo<AuthDeviceRouteArgs> page =
      _i10.PageInfo<AuthDeviceRouteArgs>(name);
}

class AuthDeviceRouteArgs {
  const AuthDeviceRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i11.BluetoothDevice device;

  final List<_i11.BluetoothService> services;

  final _i12.Key? key;

  @override
  String toString() {
    return 'AuthDeviceRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i2.AuthWithXiaomiAccountScreen]
class AuthWithXiaomiAccountRoute
    extends _i10.PageRouteInfo<AuthWithXiaomiAccountRouteArgs> {
  AuthWithXiaomiAccountRoute({
    required Uri uri,
    required void Function(String) onAuthenticated,
    _i12.Key? key,
    List<_i10.PageRouteInfo>? children,
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

  static const _i10.PageInfo<AuthWithXiaomiAccountRouteArgs> page =
      _i10.PageInfo<AuthWithXiaomiAccountRouteArgs>(name);
}

class AuthWithXiaomiAccountRouteArgs {
  const AuthWithXiaomiAccountRouteArgs({
    required this.uri,
    required this.onAuthenticated,
    this.key,
  });

  final Uri uri;

  final void Function(String) onAuthenticated;

  final _i12.Key? key;

  @override
  String toString() {
    return 'AuthWithXiaomiAccountRouteArgs{uri: $uri, onAuthenticated: $onAuthenticated, key: $key}';
  }
}

/// generated route for
/// [_i3.DatasetsPage]
class DatasetsPage extends _i10.PageRouteInfo<DatasetsPageArgs> {
  DatasetsPage({
    void Function(
      _i12.GlobalKey<_i12.RefreshIndicatorState>,
      _i12.GlobalKey<_i12.RefreshIndicatorState>,
    )? onInitialised,
    _i12.Key? key,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          DatasetsPage.name,
          args: DatasetsPageArgs(
            onInitialised: onInitialised,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'DatasetsPage';

  static const _i10.PageInfo<DatasetsPageArgs> page =
      _i10.PageInfo<DatasetsPageArgs>(name);
}

class DatasetsPageArgs {
  const DatasetsPageArgs({
    this.onInitialised,
    this.key,
  });

  final void Function(
    _i12.GlobalKey<_i12.RefreshIndicatorState>,
    _i12.GlobalKey<_i12.RefreshIndicatorState>,
  )? onInitialised;

  final _i12.Key? key;

  @override
  String toString() {
    return 'DatasetsPageArgs{onInitialised: $onInitialised, key: $key}';
  }
}

/// generated route for
/// [_i4.DiscoverDeviceScreen]
class DiscoverDeviceRoute extends _i10.PageRouteInfo<void> {
  const DiscoverDeviceRoute({List<_i10.PageRouteInfo>? children})
      : super(
          DiscoverDeviceRoute.name,
          initialChildren: children,
        );

  static const String name = 'DiscoverDeviceRoute';

  static const _i10.PageInfo<void> page = _i10.PageInfo<void>(name);
}

/// generated route for
/// [_i5.HomeScreen]
class HomeRoute extends _i10.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i5.HomeScreenNavigation initialNavigation =
        _i5.HomeScreenNavigation.savedDevice,
    _i12.Key? key,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          HomeRoute.name,
          args: HomeRouteArgs(
            initialNavigation: initialNavigation,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i10.PageInfo<HomeRouteArgs> page =
      _i10.PageInfo<HomeRouteArgs>(name);
}

class HomeRouteArgs {
  const HomeRouteArgs({
    this.initialNavigation = _i5.HomeScreenNavigation.savedDevice,
    this.key,
  });

  final _i5.HomeScreenNavigation initialNavigation;

  final _i12.Key? key;

  @override
  String toString() {
    return 'HomeRouteArgs{initialNavigation: $initialNavigation, key: $key}';
  }
}

/// generated route for
/// [_i6.PreprocessScreen]
class PreprocessRoute extends _i10.PageRouteInfo<PreprocessRouteArgs> {
  PreprocessRoute({
    required String path,
    _i13.Key? key,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          PreprocessRoute.name,
          args: PreprocessRouteArgs(
            path: path,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'PreprocessRoute';

  static const _i10.PageInfo<PreprocessRouteArgs> page =
      _i10.PageInfo<PreprocessRouteArgs>(name);
}

class PreprocessRouteArgs {
  const PreprocessRouteArgs({
    required this.path,
    this.key,
  });

  final String path;

  final _i13.Key? key;

  @override
  String toString() {
    return 'PreprocessRouteArgs{path: $path, key: $key}';
  }
}

/// generated route for
/// [_i7.RecordScreen]
class RecordRoute extends _i10.PageRouteInfo<RecordRouteArgs> {
  RecordRoute({
    required _i11.BluetoothDevice device,
    required List<_i11.BluetoothService> services,
    required void Function() onRecordSuccess,
    _i12.Key? key,
    List<_i10.PageRouteInfo>? children,
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

  static const _i10.PageInfo<RecordRouteArgs> page =
      _i10.PageInfo<RecordRouteArgs>(name);
}

class RecordRouteArgs {
  const RecordRouteArgs({
    required this.device,
    required this.services,
    required this.onRecordSuccess,
    this.key,
  });

  final _i11.BluetoothDevice device;

  final List<_i11.BluetoothService> services;

  final void Function() onRecordSuccess;

  final _i12.Key? key;

  @override
  String toString() {
    return 'RecordRouteArgs{device: $device, services: $services, onRecordSuccess: $onRecordSuccess, key: $key}';
  }
}

/// generated route for
/// [_i8.SavedDevicesPage]
class SavedDevicesPage extends _i10.PageRouteInfo<void> {
  const SavedDevicesPage({List<_i10.PageRouteInfo>? children})
      : super(
          SavedDevicesPage.name,
          initialChildren: children,
        );

  static const String name = 'SavedDevicesPage';

  static const _i10.PageInfo<void> page = _i10.PageInfo<void>(name);
}

/// generated route for
/// [_i9.SplashScreen]
class SplashRoute extends _i10.PageRouteInfo<void> {
  const SplashRoute({List<_i10.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i10.PageInfo<void> page = _i10.PageInfo<void>(name);
}
