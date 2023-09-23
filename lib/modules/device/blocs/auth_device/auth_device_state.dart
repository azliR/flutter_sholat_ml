part of 'auth_device_notifier.dart';

@immutable
class AuthDeviceState extends Equatable {
  const AuthDeviceState({
    required this.isInitialised,
    required this.savedDevices,
    required this.presentationState,
  });

  factory AuthDeviceState.initial() => const AuthDeviceState(
        isInitialised: false,
        savedDevices: [],
        presentationState: AuthDeviceInitialState(),
      );

  final bool isInitialised;
  final List<Device> savedDevices;
  final AuthDevicePresentationState presentationState;

  AuthDeviceState copyWith({
    bool? isInitialised,
    List<Device>? savedDevices,
    AuthDevicePresentationState? presentationState,
  }) {
    return AuthDeviceState(
      isInitialised: isInitialised ?? this.isInitialised,
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
