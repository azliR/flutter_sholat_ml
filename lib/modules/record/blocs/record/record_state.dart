// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'record_notifier.dart';

@immutable
class RecordState extends Equatable {
  const RecordState({
    required this.isInitialised,
    required this.isCameraPermissionGranted,
    required this.cameraState,
    required this.accelerometerDatasets,
    required this.presentationState,
  });

  factory RecordState.initial() => const RecordState(
        isInitialised: false,
        isCameraPermissionGranted: false,
        cameraState: CameraState.notInitialised,
        accelerometerDatasets: [],
        presentationState: RecordInitialState(),
      );

  final bool isInitialised;
  final bool isCameraPermissionGranted;
  final CameraState cameraState;
  final List<Dataset> accelerometerDatasets;
  final RecordPresentationState presentationState;

  RecordState copyWith({
    bool? isInitialised,
    bool? isCameraPermissionGranted,
    CameraState? cameraState,
    List<Dataset>? accelerometerDatasets,
    RecordPresentationState? presentationState,
  }) {
    return RecordState(
      isInitialised: isInitialised ?? this.isInitialised,
      isCameraPermissionGranted:
          isCameraPermissionGranted ?? this.isCameraPermissionGranted,
      cameraState: cameraState ?? this.cameraState,
      accelerometerDatasets:
          accelerometerDatasets ?? this.accelerometerDatasets,
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isInitialised,
        isCameraPermissionGranted,
        cameraState,
        accelerometerDatasets,
        presentationState,
      ];
}

enum CameraState {
  notInitialised,
  ready,
  preparing,
  recording,
  saving,
}

@immutable
sealed class RecordPresentationState {
  const RecordPresentationState();
}

final class RecordInitialState extends RecordPresentationState {
  const RecordInitialState();
}

final class RecordSuccessState extends RecordPresentationState {
  const RecordSuccessState();
}

final class RecordFailureState extends RecordPresentationState {
  const RecordFailureState(this.failure);

  final Failure failure;
}

final class CameraInitialisationFailureState extends RecordPresentationState {
  const CameraInitialisationFailureState(this.failure);

  final Failure failure;
}
