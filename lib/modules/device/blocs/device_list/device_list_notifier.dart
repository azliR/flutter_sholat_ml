import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/device/repository/device_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

part 'device_list_state.dart';

final deviceListProvider =
    StateNotifierProvider.autoDispose<DeviceListNotifier, DeviceListState>(
  (ref) => DeviceListNotifier(),
);

class DeviceListNotifier extends StateNotifier<DeviceListState> {
  DeviceListNotifier()
      : _deviceRepository = DeviceRepository(),
        super(DeviceListState.initial());

  final DeviceRepository _deviceRepository;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  void initialise() {
    if (state.isInitialised) return;

    _scanSubscription ??= _deviceRepository.scanResults.listen((results) {
      for (final result in results) {
        if (!state.scanResults.contains(result)) {
          log('Device found: ${result.device.localName}');
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

  Future<void> connectDevice(BluetoothDevice device) async {
    state =
        state.copyWith(presentationState: const ConnectDeviceLoadingState());
    final (failure, _) = await _deviceRepository.connectDevice(device);
    if (failure != null) {
      state =
          state.copyWith(presentationState: ConnectDeviceFailureState(failure));
      return;
    }
    state =
        state.copyWith(presentationState: ConnectDeviceSuccessState(device));
  }

  Future<void> selectDevice(BluetoothDevice device) async {
    state = state.copyWith(presentationState: const SelectDeviceLoadingState());
    final (failure, services) =
        await _deviceRepository.discoverServices(device);
    if (failure != null) {
      state =
          state.copyWith(presentationState: SelectDeviceFailureState(failure));
      return;
    }
    state = state.copyWith(
      presentationState: SelectDeviceSuccessState(device, services),
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterSubscription?.cancel();
    super.dispose();
  }
}
