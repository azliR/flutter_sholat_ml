part of 'auth_device_cubit.dart';

@immutable
class AuthDeviceState extends Equatable {
  const AuthDeviceState({
    required this.isInitialised,
    required this.authKey,
    required this.presentationState,
  });

  factory AuthDeviceState.initial() => const AuthDeviceState(
        isInitialised: false,
        authKey: '',
        presentationState: AuthDeviceInitialState(),
      );

  final bool isInitialised;
  final String authKey;
  final AuthDevicePresentationState presentationState;

  AuthDeviceState copyWith({
    bool? isInitialised,
    String? authKey,
    AuthDevicePresentationState? presentationState,
  }) {
    return AuthDeviceState(
      isInitialised: isInitialised ?? this.isInitialised,
      authKey: authKey ?? this.authKey,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [isInitialised, authKey, presentationState];
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
