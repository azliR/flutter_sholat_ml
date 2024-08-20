// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i15;
import 'package:flutter/foundation.dart' as _i19;
import 'package:flutter/material.dart' as _i17;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as _i16;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_device_screen.dart'
    as _i1;
import 'package:flutter_sholat_ml/core/auth_device/views/auth_with_xiaomi_account_screen.dart'
    as _i2;
import 'package:flutter_sholat_ml/core/settings/views/settings_screen.dart'
    as _i13;
import 'package:flutter_sholat_ml/core/splash/views/splash_screen.dart' as _i14;
import 'package:flutter_sholat_ml/features/datasets/views/datasets_page.dart'
    as _i3;
import 'package:flutter_sholat_ml/features/discover_devices/views/discover_device_screen.dart'
    as _i4;
import 'package:flutter_sholat_ml/features/home/views/home_screen.dart' as _i5;
import 'package:flutter_sholat_ml/features/manual_device_connect/views/manual_device_connect_screen.dart'
    as _i6;
import 'package:flutter_sholat_ml/features/ml_model/views/ml_model_screen.dart'
    as _i7;
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart'
    as _i18;
import 'package:flutter_sholat_ml/features/ml_models/views/ml_models_page.dart'
    as _i8;
import 'package:flutter_sholat_ml/features/model_picker/views/model_picker_screen.dart'
    as _i9;
import 'package:flutter_sholat_ml/features/preprocess/views/preprocess_screen.dart'
    as _i10;
import 'package:flutter_sholat_ml/features/record/views/record_screen.dart'
    as _i11;
import 'package:flutter_sholat_ml/features/saved_devices/views/saved_devices_page.dart'
    as _i12;

/// generated route for
/// [_i1.AuthDeviceScreen]
class AuthDeviceRoute extends _i15.PageRouteInfo<AuthDeviceRouteArgs> {
  AuthDeviceRoute({
    required _i16.BluetoothDevice device,
    required List<_i16.BluetoothService> services,
    _i17.Key? key,
    List<_i15.PageRouteInfo>? children,
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

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AuthDeviceRouteArgs>();
      return _i1.AuthDeviceScreen(
        device: args.device,
        services: args.services,
        key: args.key,
      );
    },
  );
}

class AuthDeviceRouteArgs {
  const AuthDeviceRouteArgs({
    required this.device,
    required this.services,
    this.key,
  });

  final _i16.BluetoothDevice device;

  final List<_i16.BluetoothService> services;

  final _i17.Key? key;

  @override
  String toString() {
    return 'AuthDeviceRouteArgs{device: $device, services: $services, key: $key}';
  }
}

/// generated route for
/// [_i2.AuthWithXiaomiAccountScreen]
class AuthWithXiaomiAccountRoute
    extends _i15.PageRouteInfo<AuthWithXiaomiAccountRouteArgs> {
  AuthWithXiaomiAccountRoute({
    required Uri uri,
    required void Function(String) onAuthenticated,
    _i17.Key? key,
    List<_i15.PageRouteInfo>? children,
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

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AuthWithXiaomiAccountRouteArgs>();
      return _i2.AuthWithXiaomiAccountScreen(
        uri: args.uri,
        onAuthenticated: args.onAuthenticated,
        key: args.key,
      );
    },
  );
}

class AuthWithXiaomiAccountRouteArgs {
  const AuthWithXiaomiAccountRouteArgs({
    required this.uri,
    required this.onAuthenticated,
    this.key,
  });

  final Uri uri;

  final void Function(String) onAuthenticated;

  final _i17.Key? key;

  @override
  String toString() {
    return 'AuthWithXiaomiAccountRouteArgs{uri: $uri, onAuthenticated: $onAuthenticated, key: $key}';
  }
}

/// generated route for
/// [_i3.DatasetsPage]
class DatasetsPage extends _i15.PageRouteInfo<DatasetsPageArgs> {
  DatasetsPage({
    void Function(
      _i17.GlobalKey<_i17.RefreshIndicatorState>,
      _i17.GlobalKey<_i17.RefreshIndicatorState>,
    )? onInitialised,
    _i17.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          DatasetsPage.name,
          args: DatasetsPageArgs(
            onInitialised: onInitialised,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'DatasetsPage';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args =
          data.argsAs<DatasetsPageArgs>(orElse: () => const DatasetsPageArgs());
      return _i3.DatasetsPage(
        onInitialised: args.onInitialised,
        key: args.key,
      );
    },
  );
}

class DatasetsPageArgs {
  const DatasetsPageArgs({
    this.onInitialised,
    this.key,
  });

  final void Function(
    _i17.GlobalKey<_i17.RefreshIndicatorState>,
    _i17.GlobalKey<_i17.RefreshIndicatorState>,
  )? onInitialised;

  final _i17.Key? key;

  @override
  String toString() {
    return 'DatasetsPageArgs{onInitialised: $onInitialised, key: $key}';
  }
}

/// generated route for
/// [_i4.DiscoverDeviceScreen]
class DiscoverDeviceRoute extends _i15.PageRouteInfo<void> {
  const DiscoverDeviceRoute({List<_i15.PageRouteInfo>? children})
      : super(
          DiscoverDeviceRoute.name,
          initialChildren: children,
        );

  static const String name = 'DiscoverDeviceRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i4.DiscoverDeviceScreen();
    },
  );
}

/// generated route for
/// [_i5.HomeScreen]
class HomeRoute extends _i15.PageRouteInfo<HomeRouteArgs> {
  HomeRoute({
    _i5.HomeScreenNavigationTab initialNavigation =
        _i5.HomeScreenNavigationTab.savedDevice,
    _i17.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          HomeRoute.name,
          args: HomeRouteArgs(
            initialNavigation: initialNavigation,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args =
          data.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i5.HomeScreen(
        initialNavigation: args.initialNavigation,
        key: args.key,
      );
    },
  );
}

class HomeRouteArgs {
  const HomeRouteArgs({
    this.initialNavigation = _i5.HomeScreenNavigationTab.savedDevice,
    this.key,
  });

  final _i5.HomeScreenNavigationTab initialNavigation;

  final _i17.Key? key;

  @override
  String toString() {
    return 'HomeRouteArgs{initialNavigation: $initialNavigation, key: $key}';
  }
}

/// generated route for
/// [_i6.ManualDeviceConnectScreen]
class ManualDeviceConnectRoute extends _i15.PageRouteInfo<void> {
  const ManualDeviceConnectRoute({List<_i15.PageRouteInfo>? children})
      : super(
          ManualDeviceConnectRoute.name,
          initialChildren: children,
        );

  static const String name = 'ManualDeviceConnectRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i6.ManualDeviceConnectScreen();
    },
  );
}

/// generated route for
/// [_i7.MlModelScreen]
class MlModelRoute extends _i15.PageRouteInfo<MlModelRouteArgs> {
  MlModelRoute({
    required _i18.MlModel model,
    required _i16.BluetoothDevice? device,
    required List<_i16.BluetoothService>? services,
    required void Function(_i18.MlModel)? onModelChanged,
    _i17.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          MlModelRoute.name,
          args: MlModelRouteArgs(
            model: model,
            device: device,
            services: services,
            onModelChanged: onModelChanged,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'MlModelRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MlModelRouteArgs>();
      return _i7.MlModelScreen(
        model: args.model,
        device: args.device,
        services: args.services,
        onModelChanged: args.onModelChanged,
        key: args.key,
      );
    },
  );
}

class MlModelRouteArgs {
  const MlModelRouteArgs({
    required this.model,
    required this.device,
    required this.services,
    required this.onModelChanged,
    this.key,
  });

  final _i18.MlModel model;

  final _i16.BluetoothDevice? device;

  final List<_i16.BluetoothService>? services;

  final void Function(_i18.MlModel)? onModelChanged;

  final _i17.Key? key;

  @override
  String toString() {
    return 'MlModelRouteArgs{model: $model, device: $device, services: $services, onModelChanged: $onModelChanged, key: $key}';
  }
}

/// generated route for
/// [_i8.MlModelsPage]
class MlModelsPage extends _i15.PageRouteInfo<void> {
  const MlModelsPage({List<_i15.PageRouteInfo>? children})
      : super(
          MlModelsPage.name,
          initialChildren: children,
        );

  static const String name = 'MlModelsPage';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i8.MlModelsPage();
    },
  );
}

/// generated route for
/// [_i9.ModelPickerScreen]
class ModelPickerRoute extends _i15.PageRouteInfo<void> {
  const ModelPickerRoute({List<_i15.PageRouteInfo>? children})
      : super(
          ModelPickerRoute.name,
          initialChildren: children,
        );

  static const String name = 'ModelPickerRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i9.ModelPickerScreen();
    },
  );
}

/// generated route for
/// [_i10.PreprocessScreen]
class PreprocessRoute extends _i15.PageRouteInfo<PreprocessRouteArgs> {
  PreprocessRoute({
    required String path,
    _i19.Key? key,
    List<_i15.PageRouteInfo>? children,
  }) : super(
          PreprocessRoute.name,
          args: PreprocessRouteArgs(
            path: path,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'PreprocessRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PreprocessRouteArgs>();
      return _i10.PreprocessScreen(
        path: args.path,
        key: args.key,
      );
    },
  );
}

class PreprocessRouteArgs {
  const PreprocessRouteArgs({
    required this.path,
    this.key,
  });

  final String path;

  final _i19.Key? key;

  @override
  String toString() {
    return 'PreprocessRouteArgs{path: $path, key: $key}';
  }
}

/// generated route for
/// [_i11.RecordScreen]
class RecordRoute extends _i15.PageRouteInfo<RecordRouteArgs> {
  RecordRoute({
    required _i16.BluetoothDevice device,
    required List<_i16.BluetoothService> services,
    required void Function() onRecordSuccess,
    _i17.Key? key,
    List<_i15.PageRouteInfo>? children,
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

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<RecordRouteArgs>();
      return _i11.RecordScreen(
        device: args.device,
        services: args.services,
        onRecordSuccess: args.onRecordSuccess,
        key: args.key,
      );
    },
  );
}

class RecordRouteArgs {
  const RecordRouteArgs({
    required this.device,
    required this.services,
    required this.onRecordSuccess,
    this.key,
  });

  final _i16.BluetoothDevice device;

  final List<_i16.BluetoothService> services;

  final void Function() onRecordSuccess;

  final _i17.Key? key;

  @override
  String toString() {
    return 'RecordRouteArgs{device: $device, services: $services, onRecordSuccess: $onRecordSuccess, key: $key}';
  }
}

/// generated route for
/// [_i12.SavedDevicesPage]
class SavedDevicesPage extends _i15.PageRouteInfo<void> {
  const SavedDevicesPage({List<_i15.PageRouteInfo>? children})
      : super(
          SavedDevicesPage.name,
          initialChildren: children,
        );

  static const String name = 'SavedDevicesPage';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i12.SavedDevicesPage();
    },
  );
}

/// generated route for
/// [_i13.SettingsScreen]
class SettingsRoute extends _i15.PageRouteInfo<void> {
  const SettingsRoute({List<_i15.PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i13.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i14.SplashScreen]
class SplashRoute extends _i15.PageRouteInfo<void> {
  const SplashRoute({List<_i15.PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static _i15.PageInfo page = _i15.PageInfo(
    name,
    builder: (data) {
      return const _i14.SplashScreen();
    },
  );
}
