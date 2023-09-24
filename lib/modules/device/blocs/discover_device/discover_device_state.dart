part of 'discover_device_notifier.dart';

@immutable
class DiscoverDeviceState {
  const DiscoverDeviceState({
    required this.isInitialised,
    required this.isScanning,
    required this.bluetoothState,
    required this.scanResults,
    required this.bondedDevices,
    required this.presentationState,
  });

  factory DiscoverDeviceState.initial() => const DiscoverDeviceState(
        isInitialised: false,
        isScanning: false,
        bluetoothState: BluetoothAdapterState.unknown,
        scanResults: [],
        bondedDevices: [],
        presentationState: DiscoverDeviceInitialState(),
      );

  final bool isInitialised;
  final bool isScanning;
  final BluetoothAdapterState bluetoothState;
  final List<ScanResult> scanResults;
  final List<BluetoothDevice> bondedDevices;
  final DiscoverDevicePresentationState presentationState;

  DiscoverDeviceState copyWith({
    bool? isInitialised,
    bool? isScanning,
    BluetoothAdapterState? bluetoothState,
    List<ScanResult>? scanResults,
    List<BluetoothDevice>? bondedDevices,
    DiscoverDevicePresentationState? presentationState,
  }) {
    return DiscoverDeviceState(
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
sealed class DiscoverDevicePresentationState {
  const DiscoverDevicePresentationState();
}

final class DiscoverDeviceInitialState extends DiscoverDevicePresentationState {
  const DiscoverDeviceInitialState();
}

final class TurnOnBluetoothFailureState
    extends DiscoverDevicePresentationState {
  const TurnOnBluetoothFailureState(this.failure);

  final Failure failure;
}

final class ScanDevicesFailureState extends DiscoverDevicePresentationState {
  const ScanDevicesFailureState(this.failure);

  final Failure failure;
}

final class GetBondedDevicesFailureState
    extends DiscoverDevicePresentationState {
  const GetBondedDevicesFailureState(this.failure);

  final Failure failure;
}
