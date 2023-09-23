// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i5;
import 'package:flutter/material.dart' as _i7;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as _i6;
import 'package:flutter_sholat_ml/core/splash_page.dart' as _i4;
import 'package:flutter_sholat_ml/modules/device/views/auth_device_page.dart'
    as _i1;
import 'package:flutter_sholat_ml/modules/device/views/device_list_page.dart'
    as _i2;
import 'package:flutter_sholat_ml/modules/home/views/record_page.dart' as _i3;

abstract class $AppRouter extends _i5.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i5.PageFactory> pagesMap = {
    AuthDeviceRoute.name: (routeData) {
      final args = routeData.argsAs<AuthDeviceRouteArgs>();
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.AuthDevicePage(
          device: args.device,
          services: args.services,
          key: args.key,
        ),
      );
    },
    DeviceListRoute.name: (routeData) {
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.DeviceListPage(),
      );
    },
    RecordRoute.name: (routeData) {
      final args = routeData.argsAs<RecordRouteArgs>();
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.RecordPage(
          device: args.device,
          services: args.services,
          key: args.key,
        ),
      );
    },
    SplashRoute.name: (routeData) {
      return _i5.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.SplashPage(),
      );
    },
  };
}

/// generated route for
/// [_i1.AuthDevicePage]
class AuthDeviceRoute extends _i5.PageRouteInfo<AuthDeviceRouteArgs> {
  AuthDeviceRoute({
    required _i6.BluetoothDevice device,
    required List<_i6.BluetoothService> services,
    _i7.Key? key,
    List<_i5.PageRouteInfo>? children,
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

  static const _i5.PageInfo<AuthDeviceRouteArgs> page =
      _i5.PageInfo<AuthDeviceRouteArgs>(name);
}

class AuthDeviceRouteArgs {
  const AuthDeviceRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i6.BluetoothDevice device;

  final List<_i6.BluetoothService> services;

  final _i7.Key? key;

  @override
  String toString() {
    return 'AuthDeviceRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i2.DeviceListPage]
class DeviceListRoute extends _i5.PageRouteInfo<void> {
  const DeviceListRoute({List<_i5.PageRouteInfo>? children})
      : super(
          DeviceListRoute.name,
          initialChildren: children,
        );

  static const String name = 'DeviceListRoute';

  static const _i5.PageInfo<void> page = _i5.PageInfo<void>(name);
}

/// generated route for
/// [_i3.RecordPage]
class RecordRoute extends _i5.PageRouteInfo<RecordRouteArgs> {
  RecordRoute({
    required _i6.BluetoothDevice device,
    required List<_i6.BluetoothService> services,
    _i7.Key? key,
    List<_i5.PageRouteInfo>? children,
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

  static const _i5.PageInfo<RecordRouteArgs> page =
      _i5.PageInfo<RecordRouteArgs>(name);
}

class RecordRouteArgs {
  const RecordRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i6.BluetoothDevice device;

  final List<_i6.BluetoothService> services;

  final _i7.Key? key;

  @override
  String toString() {
    return 'RecordRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i4.SplashPage]
class SplashRoute extends _i5.PageRouteInfo<void> {
  const SplashRoute({List<_i5.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i5.PageInfo<void> page = _i5.PageInfo<void>(name);
}
