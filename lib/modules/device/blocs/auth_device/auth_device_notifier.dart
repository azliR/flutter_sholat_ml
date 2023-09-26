import 'dart:async';
import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_responses.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/modules/device/models/device/device.dart';
import 'package:flutter_sholat_ml/modules/device/repository/device_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

part 'auth_device_state.dart';

final authDeviceProvider =
    StateNotifierProvider<AuthDeviceNotifier, AuthDeviceState>(
  (ref) => AuthDeviceNotifier(),
);

class AuthDeviceNotifier extends StateNotifier<AuthDeviceState> {
  AuthDeviceNotifier()
      : _deviceRepository = DeviceRepository(),
        super(AuthDeviceState.initial());

  final DeviceRepository _deviceRepository;

  BluetoothDevice? bluetoothDevice;
  List<BluetoothService>? services;

  BluetoothService? _authService;
  BluetoothCharacteristic? _authChar;

  StreamSubscription<List<int>>? _authSubscription;
  StreamSubscription<List<Device>>? _savedDevicesSubscription;

  Future<Device?> getPrimaryDevice() async {
    final (failure, device) = await _deviceRepository.getPrimaryDevice();
    if (failure != null) {
      state = state.copyWith(
        presentationState: GetPrimaryDeviceFailure(failure),
      );
      return null;
    }
    return device;
  }

  Future<bool> removeSavedDevice(Device device) async {
    if (!state.savedDevices.contains(device)) return false;

    await disconnectCurrentDevice();

    final (removeFailure, _) = await _deviceRepository.removeDevice(device);
    if (removeFailure != null) {
      state = state.copyWith(
        presentationState: RemoveDeviceFailure(removeFailure),
      );
      return false;
    }

    state = state.copyWith(currentDevice: () => null);
    return true;
  }

  Future<void> connectToSavedDevice(Device savedDevice) async {
    final device = BluetoothDevice(
      remoteId: DeviceIdentifier(savedDevice.deviceId),
      localName: savedDevice.deviceName,
      type: BluetoothDeviceType.le,
    );

    final success = await connectDevice(device);
    if (!success) return;
    final services = await selectDevice(device);
    if (services == null) return;

    await auth(savedDevice.authKey, device, services);
  }

  Future<void> initialise(
    String authKey,
    BluetoothDevice bluetoothDevice,
    List<BluetoothService> services,
  ) async {
    this.bluetoothDevice = bluetoothDevice;
    this.services = services;

    _authService = services.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.serviceMiBand2),
    );
    _authChar = _authService!.characteristics.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.charAuth),
    );

    final authChar = _authChar!;

    await authChar.setNotifyValue(true);

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
        final currentDevice = Device(
          authKey: authKey,
          deviceId: bluetoothDevice.remoteId.str,
          deviceName: bluetoothDevice.localName,
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

    _savedDevicesSubscription ??=
        _deviceRepository.savedDevicesStream.listen((savedDevices) {
      state = state.copyWith(savedDevices: savedDevices);
    });

    // _connectionSubscription ??= device.connectionState.listen((state) async {
    //   if (state == BluetoothConnectionState.disconnected) {
    //     await _authSubscription?.cancel();
    //   }
    // });
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

  Future<void> auth(
    String authKey,
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    state = state.copyWith(
      presentationState: const AuthDeviceLoadingState(),
    );

    await initialise(authKey, device, services);

    final (failure, _) =
        await _deviceRepository.requestRandomNumber(_authChar!);
    if (failure != null) {
      state = state.copyWith(
        presentationState: AuthDeviceFailureState(failure),
      );
      return;
    }
  }

  Future<bool> disconnectCurrentDevice() async {
    if (bluetoothDevice == null) return false;

    final (disconnectFailure, _) =
        await _deviceRepository.disconnectDevice(bluetoothDevice!);
    if (disconnectFailure != null) {
      state = state.copyWith(
        presentationState: DisconnectDeviceFailure(disconnectFailure),
      );
      return false;
    }

    bluetoothDevice = null;
    services = null;
    _authChar = null;
    _authService = null;
    await _authSubscription?.cancel();

    return true;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _savedDevicesSubscription?.cancel();
    super.dispose();
  }
}
