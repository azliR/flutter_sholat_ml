import 'dart:async';
import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:dartx/dartx_io.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_responses.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/modules/device/models/device/device.dart';
import 'package:flutter_sholat_ml/modules/device/repository/device_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';

part 'auth_device_state.dart';

final authDeviceProvider =
    NotifierProvider<AuthDeviceNotifier, AuthDeviceState>(
  AuthDeviceNotifier.new,
);

class AuthDeviceNotifier extends Notifier<AuthDeviceState> {
  AuthDeviceNotifier() : _deviceRepository = DeviceRepository();

  final DeviceRepository _deviceRepository;

  BluetoothService? _authService;
  BluetoothService? _genericAccessService;
  BluetoothCharacteristic? _authChar;
  BluetoothCharacteristic? _deviceNameChar;

  StreamSubscription<List<int>>? _authSubscription;
  StreamSubscription<List<Device>>? _savedDevicesSubscription;

  @override
  AuthDeviceState build() {
    ref.onDispose(() {
      _authSubscription?.cancel();
      _savedDevicesSubscription?.cancel();
    });

    return AuthDeviceState.initial();
  }

  Future<Device?> getPrimaryDevice() async {
    return _deviceRepository.getPrimaryDevice();
  }

  Future<Device?> getSavedDevices() async {
    return _deviceRepository.getPrimaryDevice();
  }

  Future<bool> removeSavedDevice(Device device) async {
    if (!state.savedDevices.contains(device)) return false;

    await disconnectCurrentDevice();

    final (removeFailure, _) = await _deviceRepository.removeDevice(device);
    if (removeFailure != null) {
      state = state.copyWith(
        presentationState: RemoveDeviceFailureState(removeFailure),
      );
      return false;
    }

    state = state.copyWith(currentDevice: () => null);
    return true;
  }

  Future<void> connectToSavedDevice(Device savedDevice) async {
    final device = BluetoothDevice.fromId(savedDevice.deviceId);

    final success = await connectDevice(device);
    if (!success) return;
    final services = await selectDevice(device);
    if (services == null) return;
    await Future<void>.delayed(const Duration(seconds: 1));
    await auth(savedDevice.authKey, device, services);
  }

  Future<void> auth(
    String authKey,
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    state = state.copyWith(presentationState: const AuthDeviceLoadingState());

    await initialiseAuth(authKey, device, services);

    final (failure, _) =
        await _deviceRepository.requestRandomNumber(_authChar!);
    if (failure != null) {
      state = state.copyWith(
        presentationState: AuthDeviceFailureState(failure),
      );
      return;
    }
  }

  Future<void> initialiseAuth(
    String authKey,
    BluetoothDevice bluetoothDevice,
    List<BluetoothService> services,
  ) async {
    state = state.copyWith(
      currentBluetoothDevice: () => bluetoothDevice,
      currentServices: () => services,
    );

    _authService = services.firstWhere(
      (service) => service.uuid.str128 == DeviceUuids.serviceMiBand2,
    );
    _genericAccessService = services.firstWhere(
      (service) => service.uuid.str128 == DeviceUuids.serviceGenericAccess,
    );

    _authChar = _authService!.characteristics.firstWhere(
      (char) => char.uuid.str128 == DeviceUuids.charAuth,
    );
    _deviceNameChar = _genericAccessService!.characteristics.firstWhere(
      (char) => char.uuid.str128 == DeviceUuids.charDeviceName,
    );

    final authChar = _authChar!;
    final (failure, _) =
        await _deviceRepository.setNotifyChars([authChar], notify: true);
    if (failure != null) {
      state = state.copyWith(
        presentationState: AuthDeviceFailureState(failure),
      );
    }

    _authSubscription = authChar.onValueReceived.listen((value) async {
      log('Auth value: $value');

      final hexResponse = hex.encode(value.sublist(0, 3));
      if (hexResponse == DeviceResponses.randomKeyReceived) {
        final number = value.sublist(3);
        final (failure, _) =
            await _deviceRepository.sendEncRandom(authChar, authKey, number);

        if (failure != null) {
          state = state.copyWith(
            presentationState: AuthDeviceFailureState(failure),
          );
          return;
        }
      } else if (hexResponse == DeviceResponses.authSucceeded) {
        final savedDevice =
            _deviceRepository.getDeviceById(bluetoothDevice.remoteId.str);

        if (savedDevice != null) {
          state = state.copyWith(
            currentDevice: () => savedDevice,
            presentationState: const AuthDeviceSuccessState(),
          );
          return;
        }

        var platformName = bluetoothDevice.platformName;
        if (platformName.isNullOrEmpty) {
          state = state.copyWith(
            presentationState: const GetDeviceNameLoadingState(),
          );
          final (failure, deviceName) =
              await _deviceRepository.getDeviceName(_deviceNameChar!);
          if (failure != null) {
            state = state.copyWith(
              presentationState: GetDeviceNameFailureState(failure),
            );
            platformName = 'Unknown device';
          } else {
            platformName = deviceName!;
          }
        }

        final currentDevice = Device(
          authKey: authKey,
          deviceId: bluetoothDevice.remoteId.str,
          deviceName: platformName,
        );
        await _deviceRepository.saveDevice(currentDevice);

        state = state.copyWith(
          currentDevice: () => currentDevice,
          presentationState: const AuthDeviceSuccessState(),
        );
      } else {
        state = state.copyWith(
          presentationState: const AuthDeviceResponseFailureState(),
        );
      }
    });

    final savedDevices = _deviceRepository.getSavedDevices();
    state = state.copyWith(
      savedDevices: {...state.savedDevices, ...savedDevices}.toList(),
    );
    _savedDevicesSubscription ??=
        _deviceRepository.savedDevicesStream.listen((savedDevices) {
      state = state.copyWith(savedDevices: savedDevices);
    });
  }

  Future<bool> connectDevice(BluetoothDevice bluetoothDevice) async {
    state =
        state.copyWith(presentationState: const ConnectDeviceLoadingState());

    await disconnectCurrentDevice();

    state = state.copyWith(currentDevice: () => null);

    final (connectFailure, _) =
        await _deviceRepository.connectDevice(bluetoothDevice);

    if (connectFailure != null) {
      state = state.copyWith(
        presentationState: ConnectDeviceFailureState(connectFailure),
      );
      return false;
    }
    state = state.copyWith(
      presentationState: ConnectDeviceSuccessState(bluetoothDevice),
    );
    return true;
  }

  Future<List<BluetoothService>?> selectDevice(BluetoothDevice device) async {
    state = state.copyWith(presentationState: const SelectDeviceLoadingState());

    final (failure, services) =
        await _deviceRepository.discoverServices(device);
    if (failure != null) {
      state =
          state.copyWith(presentationState: SelectDeviceFailureState(failure));
      return null;
    }

    state = state.copyWith(
      presentationState: SelectDeviceSuccessState(device, services),
    );

    return services;
  }

  Future<void> authWithXiaomiAccount(String accessToken) async {
    state = state.copyWith(
      presentationState: const AuthWithXiaomiAccountLoadingState(),
    );

    final (failure, wearables) =
        await _deviceRepository.loginWithXiaomiAccount(accessToken);
    log(wearables.toString());
    if (failure != null) {
      state = state.copyWith(
        presentationState: AuthWithXiaomiAccountFailureState(failure),
      );
      return;
    }
    state = state.copyWith(
      presentationState: const AuthWithXiaomiAccountSuccessState(),
    );
  }

  Future<bool> disconnectCurrentDevice() async {
    final bluetoothDevice = state.currentBluetoothDevice;
    if (bluetoothDevice == null) return false;

    final (disconnectFailure, _) =
        await _deviceRepository.disconnectDevice(bluetoothDevice);
    if (disconnectFailure != null) {
      state = state.copyWith(
        presentationState: DisconnectDeviceFailureState(disconnectFailure),
      );
      return false;
    }

    state = state.copyWith(
      currentBluetoothDevice: () => null,
      currentServices: () => null,
    );

    _authChar = null;
    _authService = null;
    await _authSubscription?.cancel();

    return true;
  }
}
