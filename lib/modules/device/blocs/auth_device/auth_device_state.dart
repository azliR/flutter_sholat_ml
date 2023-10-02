part of 'auth_device_notifier.dart';

@immutable
class AuthDeviceState extends Equatable {
  const AuthDeviceState({
    required this.isInitialised,
    required this.currentDevice,
    required this.savedDevices,
    required this.presentationState,
  });

  factory AuthDeviceState.initial() => const AuthDeviceState(
        isInitialised: false,
        currentDevice: null,
        savedDevices: [],
        presentationState: AuthDeviceInitialState(),
      );

  final bool isInitialised;
  final Device? currentDevice;
  final List<Device> savedDevices;
  final AuthDevicePresentationState presentationState;

  AuthDeviceState copyWith({
    bool? isInitialised,
    ValueGetter<Device?>? currentDevice,
    List<Device>? savedDevices,
    AuthDevicePresentationState? presentationState,
  }) {
    return AuthDeviceState(
      isInitialised: isInitialised ?? this.isInitialised,
      currentDevice: currentDevice?.call() ?? this.currentDevice,
      savedDevices: savedDevices ?? this.savedDevices,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isInitialised,
        savedDevices,
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

final class AuthWithXiaomiAccountLoadingState
    extends AuthDevicePresentationState {
  const AuthWithXiaomiAccountLoadingState();
}

final class AuthWithXiaomiAccountSuccessState
    extends AuthDevicePresentationState {
  const AuthWithXiaomiAccountSuccessState();
}

final class AuthWithXiaomiAccountFailureState
    extends AuthDevicePresentationState {
  const AuthWithXiaomiAccountFailureState(this.failure);

  final Failure failure;
}

final class AuthWithXiaomiAccountResponseFailureState
    extends AuthDevicePresentationState {
  const AuthWithXiaomiAccountResponseFailureState();
}

final class DisconnectDeviceFailure extends AuthDevicePresentationState {
  const DisconnectDeviceFailure(this.failure);

  final Failure failure;
}

final class GetPrimaryDeviceFailure extends AuthDevicePresentationState {
  const GetPrimaryDeviceFailure(this.failure);

  final Failure failure;
}

final class RemoveDeviceFailure extends AuthDevicePresentationState {
  const RemoveDeviceFailure(this.failure);

  final Failure failure;
}
