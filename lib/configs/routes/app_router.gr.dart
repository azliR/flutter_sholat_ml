// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i8;
import 'package:flutter/material.dart' as _i10;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as _i9;
import 'package:flutter_sholat_ml/core/splash/views/splash_page.dart' as _i7;
import 'package:flutter_sholat_ml/modules/device/views/auth_device_page.dart'
    as _i1;
import 'package:flutter_sholat_ml/modules/device/views/discover_device_page.dart'
    as _i3;
import 'package:flutter_sholat_ml/modules/device/views/saved_devices_page.dart'
    as _i6;
import 'package:flutter_sholat_ml/modules/home/views/datasets_page.dart' as _i2;
import 'package:flutter_sholat_ml/modules/home/views/home_page.dart' as _i4;
import 'package:flutter_sholat_ml/modules/record/views/record_page.dart' as _i5;

abstract class $AppRouter extends _i8.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i8.PageFactory> pagesMap = {
    AuthDeviceRoute.name: (routeData) {
      final args = routeData.argsAs<AuthDeviceRouteArgs>();
      return _i8.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.AuthDevicePage(
          device: args.device,
          services: args.services,
          key: args.key,
        ),
      );
    },
    DatasetsRoute.name: (routeData) {
      return _i8.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.DatasetsPage(),
      );
    },
    DiscoverDeviceRoute.name: (routeData) {
      return _i8.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i3.DiscoverDevicePage(),
      );
    },
    HomeRoute.name: (routeData) {
      return _i8.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.HomePage(),
      );
    },
    RecordRoute.name: (routeData) {
      final args = routeData.argsAs<RecordRouteArgs>();
      return _i8.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.RecordPage(
          device: args.device,
          services: args.services,
          key: args.key,
        ),
      );
    },
    SavedDevicesRoute.name: (routeData) {
      return _i8.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i6.SavedDevicesPage(),
      );
    },
    SplashRoute.name: (routeData) {
      return _i8.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.SplashPage(),
      );
    },
  };
}

/// generated route for
/// [_i1.AuthDevicePage]
class AuthDeviceRoute extends _i8.PageRouteInfo<AuthDeviceRouteArgs> {
  AuthDeviceRoute({
    required _i9.BluetoothDevice device,
    required List<_i9.BluetoothService> services,
    _i10.Key? key,
    List<_i8.PageRouteInfo>? children,
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

  static const _i8.PageInfo<AuthDeviceRouteArgs> page =
      _i8.PageInfo<AuthDeviceRouteArgs>(name);
}

class AuthDeviceRouteArgs {
  const AuthDeviceRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i9.BluetoothDevice device;

  final List<_i9.BluetoothService> services;

  final _i10.Key? key;

  @override
  String toString() {
    return 'AuthDeviceRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i2.DatasetsPage]
class DatasetsRoute extends _i8.PageRouteInfo<void> {
  const DatasetsRoute({List<_i8.PageRouteInfo>? children})
      : super(
          DatasetsRoute.name,
          initialChildren: children,
        );

  static const String name = 'DatasetsRoute';

  static const _i8.PageInfo<void> page = _i8.PageInfo<void>(name);
}

/// generated route for
/// [_i3.DiscoverDevicePage]
class DiscoverDeviceRoute extends _i8.PageRouteInfo<void> {
  const DiscoverDeviceRoute({List<_i8.PageRouteInfo>? children})
      : super(
          DiscoverDeviceRoute.name,
          initialChildren: children,
        );

  static const String name = 'DiscoverDeviceRoute';

  static const _i8.PageInfo<void> page = _i8.PageInfo<void>(name);
}

/// generated route for
/// [_i4.HomePage]
class HomeRoute extends _i8.PageRouteInfo<void> {
  const HomeRoute({List<_i8.PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i8.PageInfo<void> page = _i8.PageInfo<void>(name);
}

/// generated route for
/// [_i5.RecordPage]
class RecordRoute extends _i8.PageRouteInfo<RecordRouteArgs> {
  RecordRoute({
    required _i9.BluetoothDevice device,
    required List<_i9.BluetoothService> services,
    _i10.Key? key,
    List<_i8.PageRouteInfo>? children,
  }) : super(
          RecordRoute.name,
          args: RecordRouteArgs(
            device: device,
            services: services,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'RecordRoute';

  static const _i8.PageInfo<RecordRouteArgs> page =
      _i8.PageInfo<RecordRouteArgs>(name);
}

class RecordRouteArgs {
  const RecordRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i9.BluetoothDevice device;

  final List<_i9.BluetoothService> services;

  final _i10.Key? key;

  @override
  String toString() {
    return 'RecordRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i6.SavedDevicesPage]
class SavedDevicesRoute extends _i8.PageRouteInfo<void> {
  const SavedDevicesRoute({List<_i8.PageRouteInfo>? children})
      : super(
          SavedDevicesRoute.name,
          initialChildren: children,
        );

  static const String name = 'SavedDevicesRoute';

  static const _i8.PageInfo<void> page = _i8.PageInfo<void>(name);
}

/// generated route for
/// [_i7.SplashPage]
class SplashRoute extends _i8.PageRouteInfo<void> {
  const SplashRoute({List<_i8.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i8.PageInfo<void> page = _i8.PageInfo<void>(name);
}
