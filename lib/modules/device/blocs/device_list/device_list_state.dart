part of 'device_list_notifier.dart';

@immutable
class DeviceListState {
  const DeviceListState({
    required this.isInitialised,
    required this.isScanning,
    required this.bluetoothState,
    required this.scanResults,
    required this.bondedDevices,
    required this.presentationState,
  });

  factory DeviceListState.initial() => const DeviceListState(
        isInitialised: false,
        isScanning: false,
        bluetoothState: BluetoothAdapterState.unknown,
        scanResults: [],
        bondedDevices: [],
        presentationState: DeviceListInitialState(),
      );

  final bool isInitialised;
  final bool isScanning;
  final BluetoothAdapterState bluetoothState;
  final List<ScanResult> scanResults;
  final List<BluetoothDevice> bondedDevices;
  final DeviceListPresentationState presentationState;

  DeviceListState copyWith({
    bool? isInitialised,
    bool? isScanning,
    BluetoothAdapterState? bluetoothState,
    List<ScanResult>? scanResults,
    List<BluetoothDevice>? bondedDevices,
    DeviceListPresentationState? presentationState,
  }) {
    return DeviceListState(
      isInitialised: isInitialised ?? this.isInitialised,
      isScanning: isScanning ?? this.isScanning,
      bluetoothState: bluetoothState ?? this.bluetoothState,
      scanResults: scanResults ?? this.scanResults,
      bondedDevices: bondedDevices ?? this.bondedDevices,
      presentationState: presentationState ?? this.presentationState,
    );
  }
}

@immutable
sealed class DeviceListPresentationState {
  const DeviceListPresentationState();
}

final class DeviceListInitialState extends DeviceListPresentationState {
  const DeviceListInitialState();
}

final class TurnOnBluetoothFailureState extends DeviceListPresentationState {
  const TurnOnBluetoothFailureState(this.failure);

  final Failure failure;
}

final class ScanDevicesFailureState extends DeviceListPresentationState {
  const ScanDevicesFailureState(this.failure);

  final Failure failure;
}

final class GetBondedDevicesFailureState extends DeviceListPresentationState {
  const GetBondedDevicesFailureState(this.failure);

  final Failure failure;
}

final class ConnectDeviceLoadingState extends DeviceListPresentationState {
  const ConnectDeviceLoadingState();
}

final class ConnectDeviceSuccessState extends DeviceListPresentationState {
  const ConnectDeviceSuccessState(this.device);

  final BluetoothDevice device;
}

final class ConnectDeviceFailureState extends DeviceListPresentationState {
  const ConnectDeviceFailureState(this.failure);

  final Failure failure;
}

final class SelectDeviceLoadingState extends DeviceListPresentationState {
  const SelectDeviceLoadingState();
}

final class SelectDeviceSuccessState extends DeviceListPresentationState {
  const SelectDeviceSuccessState(this.device, this.services);

  final BluetoothDevice device;
  final List<BluetoothService> services;
}

final class SelectDeviceFailureState extends DeviceListPresentationState {
  const SelectDeviceFailureState(this.failure);

  final Failure failure;
}
