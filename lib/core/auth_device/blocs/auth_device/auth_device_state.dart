part of 'auth_device_notifier.dart';

@immutable
class AuthDeviceState extends Equatable {
  const AuthDeviceState({
    required this.isInitialised,
    required this.currentDevice,
    required this.savedDevices,
    required this.currentBluetoothDevice,
    required this.currentServices,
    required this.presentationState,
  });

  factory AuthDeviceState.initial() => const AuthDeviceState(
        isInitialised: false,
        currentDevice: null,
        savedDevices: [],
        currentBluetoothDevice: null,
        currentServices: null,
        presentationState: AuthDeviceInitialState(),
      );

  final bool isInitialised;
  final Device? currentDevice;
  final List<Device> savedDevices;
  final BluetoothDevice? currentBluetoothDevice;
  final List<BluetoothService>? currentServices;
  final AuthDevicePresentationState presentationState;

  AuthDeviceState copyWith({
    bool? isInitialised,
    ValueGetter<Device?>? currentDevice,
    List<Device>? savedDevices,
    ValueGetter<BluetoothDevice?>? currentBluetoothDevice,
    ValueGetter<List<BluetoothService>?>? currentServices,
    AuthDevicePresentationState? presentationState,
  }) {
    return AuthDeviceState(
      isInitialised: isInitialised ?? this.isInitialised,
      currentDevice:
          currentDevice != null ? currentDevice() : this.currentDevice,
      savedDevices: savedDevices ?? this.savedDevices,
      currentBluetoothDevice: currentBluetoothDevice != null
          ? currentBluetoothDevice()
          : this.currentBluetoothDevice,
      currentServices:
          currentServices != null ? currentServices() : this.currentServices,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isInitialised,
        currentDevice,
        savedDevices,
        currentBluetoothDevice,
        currentServices,
        presentationState,
      ];
}

@immutable
sealed class AuthDevicePresentationState {
  const AuthDevicePresentationState();
}

final class AuthDeviceInitialState extends AuthDevicePresentationState {
  const AuthDeviceInitialState();
}

final class ConnectDeviceLoadingState extends AuthDevicePresentationState {
  const ConnectDeviceLoadingState();
}

final class ConnectDeviceSuccessState extends AuthDevicePresentationState {
  const ConnectDeviceSuccessState(this.device);

  final BluetoothDevice device;
}

final class ConnectDeviceFailureState extends AuthDevicePresentationState {
  const ConnectDeviceFailureState(this.failure);

  final Failure failure;
}

final class SelectDeviceLoadingState extends AuthDevicePresentationState {
  const SelectDeviceLoadingState();
}

final class SelectDeviceSuccessState extends AuthDevicePresentationState {
  const SelectDeviceSuccessState(this.device, this.services);

  final BluetoothDevice device;
  final List<BluetoothService> services;
}

final class SelectDeviceFailureState extends AuthDevicePresentationState {
  const SelectDeviceFailureState(this.failure);

  final Failure failure;
}

final class AuthDeviceLoadingState extends AuthDevicePresentationState {
  const AuthDeviceLoadingState();
}

final class AuthDeviceSuccessState extends AuthDevicePresentationState {
  const AuthDeviceSuccessState();
}

final class AuthDeviceFailureState extends AuthDevicePresentationState {
  const AuthDeviceFailureState(this.failure);

  final Failure failure;
}

final class AuthDeviceResponseFailureState extends AuthDevicePresentationState {
  const AuthDeviceResponseFailureState();
}

final class LoginXiaomiAccountLoadingState extends AuthDevicePresentationState {
  const LoginXiaomiAccountLoadingState();
}

final class LoginXiaomiAccountSuccessState extends AuthDevicePresentationState {
  const LoginXiaomiAccountSuccessState(this.wearable);

  final Wearable wearable;
}

final class LoginXiaomiAccountFailureState extends AuthDevicePresentationState {
  const LoginXiaomiAccountFailureState(this.failure);

  final Failure failure;
}

final class LoginXiaomiAccountResponseFailureState
    extends AuthDevicePresentationState {
  const LoginXiaomiAccountResponseFailureState();
}

final class DisconnectDeviceFailureState extends AuthDevicePresentationState {
  const DisconnectDeviceFailureState(this.failure);

  final Failure failure;
}

final class GetPrimaryDeviceFailureState extends AuthDevicePresentationState {
  const GetPrimaryDeviceFailureState(this.failure);

  final Failure failure;
}

final class RemoveDeviceFailureState extends AuthDevicePresentationState {
  const RemoveDeviceFailureState(this.failure);

  final Failure failure;
}

final class GetDeviceNameLoadingState extends AuthDevicePresentationState {
  const GetDeviceNameLoadingState();
}

final class GetDeviceNameFailureState extends AuthDevicePresentationState {
  const GetDeviceNameFailureState(this.failure);

  final Failure failure;
}
