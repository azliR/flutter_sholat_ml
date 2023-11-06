import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/device/repository/device_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

part 'discover_device_state.dart';

final discoverDeviceProvider = StateNotifierProvider.autoDispose<
    DiscoverDeviceNotifier, DiscoverDeviceState>(
  (ref) => DiscoverDeviceNotifier(),
);

class DiscoverDeviceNotifier extends StateNotifier<DiscoverDeviceState> {
  DiscoverDeviceNotifier()
      : _deviceRepository = DeviceRepository(),
        super(DiscoverDeviceState.initial());

  final DeviceRepository _deviceRepository;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  void initialise() {
    if (state.isInitialised) return;

    getBondedDevices();

    _scanSubscription ??= _deviceRepository.scanResults.listen((results) {
      for (final result in results) {
        if (!state.scanResults.contains(result)) {
          state = state.copyWith(
            scanResults: [...state.scanResults, result],
          );
        }
      }
    });

    _adapterSubscription ??=
        _deviceRepository.adapterState.listen((bluetoothState) {
      state = state.copyWith(bluetoothState: bluetoothState);
    });

    state = state.copyWith(isInitialised: true);
  }

  Future<void> turnOnBluetooth() async {
    final (failure, _) = await _deviceRepository.turnOnBluetooth();
    if (failure != null) {
      state = state.copyWith(
        presentationState: TurnOnBluetoothFailureState(failure),
      );
      return;
    }
  }

  Future<void> scanDevices() async {
    state = state.copyWith(isScanning: true);
    if (state.bluetoothState == BluetoothAdapterState.off) {
      final (failure, _) = await _deviceRepository.turnOnBluetooth();
      if (failure != null) {
        state = state.copyWith(
          isScanning: false,
          presentationState: TurnOnBluetoothFailureState(failure),
        );
        return;
      }
    }
    final (failure, _) = await _deviceRepository.scanDevices();
    if (failure != null) {
      state = state.copyWith(
        isScanning: false,
        presentationState: ScanDevicesFailureState(failure),
      );
      return;
    }
    if (!mounted) return;
    state = state.copyWith(isScanning: false);
  }

  Future<void> getBondedDevices() async {
    final (failure, bondedDevices) = await _deviceRepository.getBondedDevices();
    if (failure != null) {
      state = state.copyWith(
        presentationState: GetBondedDevicesFailureState(failure),
      );
      return;
    }
    state = state.copyWith(bondedDevices: bondedDevices);
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterSubscription?.cancel();
    super.dispose();
  }
}
