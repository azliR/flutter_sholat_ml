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

  late BluetoothDevice device;
  late List<BluetoothService> services;

  late BluetoothService _authService;
  late BluetoothCharacteristic _authChar;

  late String _authKey;

  StreamSubscription<List<int>>? _authSubscription;
  StreamSubscription<List<Device>>? _savedDevicesSubscription;

  Future<Device?> getPrimaryDevice() {
    return _deviceRepository.getPrimaryDevice();
  }

  Future<void> connectToSavedDevice(Device savedDevice) async {
    state = state.copyWith(
      presentationState: const AuthDeviceLoadingState(),
    );

    final device = BluetoothDevice(
      remoteId: DeviceIdentifier(savedDevice.deviceId),
      localName: savedDevice.deviceName,
      type: BluetoothDeviceType.le,
    );

    final (connectFailure, _) = await _deviceRepository.connectDevice(device);
    if (connectFailure != null) {
      state = state.copyWith(
        presentationState: AuthDeviceFailureState(connectFailure),
      );
      return;
    }

    final (discoverFailure, services) =
        await _deviceRepository.discoverServices(device);
    if (discoverFailure != null) {
      state = state.copyWith(
        presentationState: AuthDeviceFailureState(discoverFailure),
      );
      return;
    }

    await initialise(savedDevice.authKey, device, services);

    await auth(savedDevice.authKey, device, services);
  }

  Future<void> initialise(
    String authKey,
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    await _authSubscription?.cancel();

    _authKey = authKey;
    this.device = device;
    this.services = services;

    _authService = services.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.serviceMiBand2),
    );
    _authChar = _authService.characteristics.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.charAuth),
    );

    await _authChar.setNotifyValue(true);

    _authSubscription = _authChar.onValueReceived.listen((value) async {
      log('Auth value: $value');

      final hexResponse = hex.encode(value.sublist(0, 3));
      if (hexResponse == DeviceResponses.randomKeyReceived) {
        final number = value.sublist(3);
        final (failure, _) =
            await _deviceRepository.sendEncRandom(_authChar, _authKey, number);

        if (failure != null) {
          state = state.copyWith(
            presentationState: AuthDeviceFailureState(failure),
          );
          return;
        }
      } else if (hexResponse == DeviceResponses.authSucceeded) {
        await _deviceRepository.saveDevice(
          Device(
            authKey: _authKey,
            deviceId: device.remoteId.str,
            deviceName: device.localName,
          ),
        );

        state = state.copyWith(
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

  Future<void> auth(
    String authKey,
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    state = state.copyWith(
      presentationState: const AuthDeviceLoadingState(),
    );

    await initialise(authKey, device, services);

    final (failure, _) = await _deviceRepository.requestRandomNumber(_authChar);
    if (failure != null) {
      state = state.copyWith(
        presentationState: AuthDeviceFailureState(failure),
      );
      return;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _savedDevicesSubscription?.cancel();
    super.dispose();
  }
}
