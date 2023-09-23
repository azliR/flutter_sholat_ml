import 'dart:async';
import 'dart:developer';

import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_responses.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/modules/device/repository/device_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:meta/meta.dart';

part 'auth_device_state.dart';

final authDeviceProvider =
    StateNotifierProvider.autoDispose<AuthDeviceNotifier, AuthDeviceState>(
  (ref) => AuthDeviceNotifier(),
);

class AuthDeviceNotifier extends StateNotifier<AuthDeviceState> {
  AuthDeviceNotifier()
      : _deviceRepository = DeviceRepository(),
        super(AuthDeviceState.initial());

  final DeviceRepository _deviceRepository;

  late final BluetoothService _authService;
  late final BluetoothCharacteristic _authChar;

  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  void initialise(BluetoothDevice device, List<BluetoothService> services) {
    if (state.isInitialised) return;

    _authService = services.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.serviceMiBand2),
    );
    _authChar = _authService.characteristics.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.charAuth),
    );

    _authChar.setNotifyValue(true);

    _valueSubscription ??= _authChar.onValueReceived.listen((value) async {
      log('Auth value: $value');

      final hexResponse = hex.encode(value.sublist(0, 3));
      if (hexResponse == DeviceResponses.randomKeyReceived) {
        final number = value.sublist(3);
        final (failure, _) = await _deviceRepository.sendEncRandom(
          _authChar,
          state.authKey,
          number,
        );

        if (failure != null) {
          state = state.copyWith(
            presentationState: AuthDeviceFailureState(failure),
          );
          return;
        }
      } else if (hexResponse == DeviceResponses.authSucceeded) {
        state = state.copyWith(
          presentationState: const AuthDeviceSuccessState(),
        );
      } else {
        state = state.copyWith(
          presentationState: const AuthDeviceResponseFailureState(),
        );
      }
    });

    _connectionSubscription ??= device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.disconnected) {
        await _valueSubscription?.cancel();
      }
    });

    state = state.copyWith(isInitialised: true);
  }

  Future<void> auth() async {
    state = state.copyWith(
      presentationState: const AuthDeviceLoadingState(),
    );

    final (failure, _) = await _deviceRepository.requestRandomNumber(_authChar);
    if (failure != null) {
      state = state.copyWith(
        presentationState: AuthDeviceFailureState(failure),
      );
      return;
    }
  }

  void onAuthKeyChanged(String authKey) {
    state = state.copyWith(authKey: authKey);
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
