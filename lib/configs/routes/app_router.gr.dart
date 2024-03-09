// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i14;
import 'package:flutter/foundation.dart' as _i18;
import 'package:flutter/material.dart' as _i16;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as _i15;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_device_screen.dart'
    as _i1;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_with_xiaomi_account_screen.dart'
    as _i2;
import 'package:flutter_sholat_ml/core/settings/views/settings_screen.dart'
    as _i12;
import 'package:flutter_sholat_ml/core/splash/views/splash_screen.dart' as _i13;
import 'package:flutter_sholat_ml/features/datasets/views/datasets_page.dart'
    as _i3;
import 'package:flutter_sholat_ml/features/discover_devices/views/discover_device_screen.dart'
    as _i4;
import 'package:flutter_sholat_ml/features/home/views/home_screen.dart' as _i5;
import 'package:flutter_sholat_ml/features/lab/views/lab_screen.dart' as _i6;
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart'
    as _i17;
import 'package:flutter_sholat_ml/features/labs/views/labs_page.dart' as _i7;
import 'package:flutter_sholat_ml/features/manual_device_connect/views/manual_device_connect_screen.dart'
    as _i8;
import 'package:flutter_sholat_ml/features/preprocess/views/preprocess_screen.dart'
    as _i9;
import 'package:flutter_sholat_ml/features/record/views/record_screen.dart'
    as _i10;
import 'package:flutter_sholat_ml/features/saved_devices/views/saved_devices_page.dart'
    as _i11;

abstract class $AppRouter extends _i14.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i14.PageFactory> pagesMap = {
    AuthDeviceRoute.name: (routeData) {
      final args = routeData.argsAs<AuthDeviceRouteArgs>();
      return _i14.AutoRoutePage<dynamic>(
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
      return _i14.AutoRoutePage<dynamic>(
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
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.DatasetsPage(
          onInitialised: args.onInitialised,
          key: args.key,
        ),
      );
    },
    DiscoverDeviceRoute.name: (routeData) {
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i4.DiscoverDeviceScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.HomeScreen(
          initialNavigation: args.initialNavigation,
          key: args.key,
        ),
      );
    },
    LabRoute.name: (routeData) {
      final args = routeData.argsAs<LabRouteArgs>();
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.LabScreen(
          model: args.model,
          device: args.device,
          services: args.services,
          onModelChanged: args.onModelChanged,
          key: args.key,
        ),
      );
    },
    LabsPage.name: (routeData) {
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i7.LabsPage(),
      );
    },
    ManualDeviceConnectRoute.name: (routeData) {
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i8.ManualDeviceConnectScreen(),
      );
    },
    PreprocessRoute.name: (routeData) {
      final args = routeData.argsAs<PreprocessRouteArgs>();
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i9.PreprocessScreen(
          path: args.path,
          key: args.key,
        ),
      );
    },
    RecordRoute.name: (routeData) {
      final args = routeData.argsAs<RecordRouteArgs>();
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i10.RecordScreen(
          device: args.device,
          services: args.services,
          onRecordSuccess: args.onRecordSuccess,
          key: args.key,
        ),
      );
    },
    SavedDevicesPage.name: (routeData) {
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i11.SavedDevicesPage(),
      );
    },
    SettingsRoute.name: (routeData) {
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i12.SettingsScreen(),
      );
    },
    SplashRoute.name: (routeData) {
      return _i14.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i13.SplashScreen(),
      );
    },
  };
}

/// generated route for
/// [_i1.AuthDeviceScreen]
class AuthDeviceRoute extends _i14.PageRouteInfo<AuthDeviceRouteArgs> {
  AuthDeviceRoute({
    required _i15.BluetoothDevice device,
    required List<_i15.BluetoothService> services,
    _i16.Key? key,
    List<_i14.PageRouteInfo>? children,
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

  static const _i14.PageInfo<AuthDeviceRouteArgs> page =
      _i14.PageInfo<AuthDeviceRouteArgs>(name);
}

class AuthDeviceRouteArgs {
  const AuthDeviceRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i15.BluetoothDevice device;

  final List<_i15.BluetoothService> services;

  final _i16.Key? key;

  @override
  String toString() {
    return 'AuthDeviceRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i2.AuthWithXiaomiAccountScreen]
class AuthWithXiaomiAccountRoute
    extends _i14.PageRouteInfo<AuthWithXiaomiAccountRouteArgs> {
  AuthWithXiaomiAccountRoute({
    required Uri uri,
    required void Function(String) onAuthenticated,
    _i16.Key? key,
    List<_i14.PageRouteInfo>? children,
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

  static const _i14.PageInfo<AuthWithXiaomiAccountRouteArgs> page =
      _i14.PageInfo<AuthWithXiaomiAccountRouteArgs>(name);
}

class AuthWithXiaomiAccountRouteArgs {
  const AuthWithXiaomiAccountRouteArgs({
    required this.uri,
    required this.onAuthenticated,
    this.key,
  });

  final Uri uri;

  final void Function(String) onAuthenticated;

  final _i16.Key? key;

  @override
  String toString() {
    return 'AuthWithXiaomiAccountRouteArgs{uri: $uri, onAuthenticated: $onAuthenticated, key: $key}';
  }
}

/// generated route for
/// [_i3.DatasetsPage]
class DatasetsPage extends _i14.PageRouteInfo<DatasetsPageArgs> {
  DatasetsPage({
    void Function(
      _i16.GlobalKey<_i16.RefreshIndicatorState>,
      _i16.GlobalKey<_i16.RefreshIndicatorState>,
    )? onInitialised,
    _i16.Key? key,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          DatasetsPage.name,
          args: DatasetsPageArgs(
            onInitialised: onInitialised,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'DatasetsPage';

  static const _i14.PageInfo<DatasetsPageArgs> page =
      _i14.PageInfo<DatasetsPageArgs>(name);
}

class DatasetsPageArgs {
  const DatasetsPageArgs({
    this.onInitialised,
    this.key,
  });

  final void Function(
    _i16.GlobalKey<_i16.RefreshIndicatorState>,
    _i16.GlobalKey<_i16.RefreshIndicatorState>,
  )? onInitialised;

  final _i16.Key? key;

  @override
  String toString() {
    return 'DatasetsPageArgs{onInitialised: $onInitialised, key: $key}';
  }
}

/// generated route for
/// [_i4.DiscoverDeviceScreen]
class DiscoverDeviceRoute extends _i14.PageRouteInfo<void> {
  const DiscoverDeviceRoute({List<_i14.PageRouteInfo>? children})
      : super(
          DiscoverDeviceRoute.name,
          initialChildren: children,
        );

  static const String name = 'DiscoverDeviceRoute';

  static const _i14.PageInfo<void> page = _i14.PageInfo<void>(name);
}

/// generated route for
/// [_i5.HomeScreen]
class HomeRoute extends _i14.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i5.HomeScreenNavigationTab initialNavigation =
        _i5.HomeScreenNavigationTab.savedDevice,
    _i16.Key? key,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          HomeRoute.name,
          args: HomeRouteArgs(
            initialNavigation: initialNavigation,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const _i14.PageInfo<HomeRouteArgs> page =
      _i14.PageInfo<HomeRouteArgs>(name);
}

class HomeRouteArgs {
  const HomeRouteArgs({
    this.initialNavigation = _i5.HomeScreenNavigationTab.savedDevice,
    this.key,
  });

  final _i5.HomeScreenNavigationTab initialNavigation;

  final _i16.Key? key;

  @override
  String toString() {
    return 'HomeRouteArgs{initialNavigation: $initialNavigation, key: $key}';
  }
}

/// generated route for
/// [_i6.LabScreen]
class LabRoute extends _i14.PageRouteInfo<LabRouteArgs> {
  LabRoute({
    required _i17.MlModel model,
    required _i15.BluetoothDevice? device,
    required List<_i15.BluetoothService>? services,
    required void Function(_i17.MlModel) onModelChanged,
    _i16.Key? key,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          LabRoute.name,
          args: LabRouteArgs(
            model: model,
            device: device,
            services: services,
            onModelChanged: onModelChanged,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'LabRoute';

  static const _i14.PageInfo<LabRouteArgs> page =
      _i14.PageInfo<LabRouteArgs>(name);
}

class LabRouteArgs {
  const LabRouteArgs({
    required this.model,
    required this.device,
    required this.services,
    required this.onModelChanged,
    this.key,
  });

  final _i17.MlModel model;

  final _i15.BluetoothDevice? device;

  final List<_i15.BluetoothService>? services;

  final void Function(_i17.MlModel) onModelChanged;

  final _i16.Key? key;

  @override
  String toString() {
    return 'LabRouteArgs{model: $model, device: $device, services: $services, onModelChanged: $onModelChanged, key: $key}';
  }
}

/// generated route for
/// [_i7.LabsPage]
class LabsPage extends _i14.PageRouteInfo<void> {
  const LabsPage({List<_i14.PageRouteInfo>? children})
      : super(
          LabsPage.name,
          initialChildren: children,
        );

  static const String name = 'LabsPage';

  static const _i14.PageInfo<void> page = _i14.PageInfo<void>(name);
}

/// generated route for
/// [_i8.ManualDeviceConnectScreen]
class ManualDeviceConnectRoute extends _i14.PageRouteInfo<void> {
  const ManualDeviceConnectRoute({List<_i14.PageRouteInfo>? children})
      : super(
          ManualDeviceConnectRoute.name,
          initialChildren: children,
        );

  static const String name = 'ManualDeviceConnectRoute';

  static const _i14.PageInfo<void> page = _i14.PageInfo<void>(name);
}

/// generated route for
/// [_i9.PreprocessScreen]
class PreprocessRoute extends _i14.PageRouteInfo<PreprocessRouteArgs> {
  PreprocessRoute({
    required String path,
    _i18.Key? key,
    List<_i14.PageRouteInfo>? children,
  }) : super(
          PreprocessRoute.name,
          args: PreprocessRouteArgs(
            path: path,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'PreprocessRoute';

  static const _i14.PageInfo<PreprocessRouteArgs> page =
      _i14.PageInfo<PreprocessRouteArgs>(name);
}

class PreprocessRouteArgs {
  const PreprocessRouteArgs({
    required this.path,
    this.key,
  });

  final String path;

  final _i18.Key? key;

  @override
  String toString() {
    return 'PreprocessRouteArgs{path: $path, key: $key}';
  }
}

/// generated route for
/// [_i10.RecordScreen]
class RecordRoute extends _i14.PageRouteInfo<RecordRouteArgs> {
  RecordRoute({
    required _i15.BluetoothDevice device,
    required List<_i15.BluetoothService> services,
    required void Function() onRecordSuccess,
    _i16.Key? key,
    List<_i14.PageRouteInfo>? children,
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

  static const _i14.PageInfo<RecordRouteArgs> page =
      _i14.PageInfo<RecordRouteArgs>(name);
}

class RecordRouteArgs {
  const RecordRouteArgs({
    required this.device,
    required this.services,
    required this.onRecordSuccess,
    this.key,
  });

  final _i15.BluetoothDevice device;

  final List<_i15.BluetoothService> services;

  final void Function() onRecordSuccess;

  final _i16.Key? key;

  @override
  String toString() {
    return 'RecordRouteArgs{device: $device, services: $services, onRecordSuccess: $onRecordSuccess, key: $key}';
  }
}

/// generated route for
/// [_i11.SavedDevicesPage]
class SavedDevicesPage extends _i14.PageRouteInfo<void> {
  const SavedDevicesPage({List<_i14.PageRouteInfo>? children})
      : super(
          SavedDevicesPage.name,
          initialChildren: children,
        );

  static const String name = 'SavedDevicesPage';

  static const _i14.PageInfo<void> page = _i14.PageInfo<void>(name);
}

/// generated route for
/// [_i12.SettingsScreen]
class SettingsRoute extends _i14.PageRouteInfo<void> {
  const SettingsRoute({List<_i14.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const _i14.PageInfo<void> page = _i14.PageInfo<void>(name);
}

/// generated route for
/// [_i13.SplashScreen]
class SplashRoute extends _i14.PageRouteInfo<void> {
  const SplashRoute({List<_i14.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const _i14.PageInfo<void> page = _i14.PageInfo<void>(name);
}
