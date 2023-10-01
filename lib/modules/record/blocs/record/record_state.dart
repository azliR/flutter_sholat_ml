// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'record_notifier.dart';

@immutable
class RecordState extends Equatable {
  const RecordState({
    required this.isInitialised,
    required this.isCameraPermissionGranted,
    required this.isLocked,
    required this.deviceLocation,
    required this.cameraState,
    required this.currentCamera,
    required this.availableCameras,
    required this.accelerometerDatasets,
    required this.lastDatasets,
    required this.presentationState,
  });

  factory RecordState.initial() => const RecordState(
        isInitialised: false,
        isCameraPermissionGranted: false,
        isLocked: false,
        deviceLocation: null,
        cameraState: CameraState.notInitialised,
        currentCamera: null,
        availableCameras: [],
        accelerometerDatasets: [],
        lastDatasets: null,
        presentationState: RecordInitialState(),
      );

  final bool isInitialised;
  final bool isCameraPermissionGranted;
  final bool isLocked;
  final DeviceLocation? deviceLocation;
  final CameraState cameraState;
  final CameraDescription? currentCamera;
  final List<CameraDescription> availableCameras;
  final List<Dataset> accelerometerDatasets;
  final List<Dataset>? lastDatasets;
  final RecordPresentationState presentationState;

  RecordState copyWith({
    bool? isInitialised,
    bool? isCameraPermissionGranted,
    bool? isLocked,
    DeviceLocation? deviceLocation,
    CameraState? cameraState,
    CameraDescription? currentCamera,
    List<Dataset>? accelerometerDatasets,
    List<CameraDescription>? availableCameras,
    ValueGetter<List<Dataset>?>? lastDatasets,
    RecordPresentationState? presentationState,
  }) {
    return RecordState(
      isInitialised: isInitialised ?? this.isInitialised,
      isCameraPermissionGranted:
          isCameraPermissionGranted ?? this.isCameraPermissionGranted,
      isLocked: isLocked ?? this.isLocked,
      deviceLocation: deviceLocation ?? this.deviceLocation,
      cameraState: cameraState ?? this.cameraState,
      currentCamera: currentCamera ?? this.currentCamera,
      accelerometerDatasets:
          accelerometerDatasets ?? this.accelerometerDatasets,
      availableCameras: availableCameras ?? this.availableCameras,
      lastDatasets: lastDatasets == null ? null : lastDatasets(),
      presentationState: presentationState ?? this.presentationState,
    );
  }

  @override
  List<Object?> get props => [
        isInitialised,
        isCameraPermissionGranted,
        isLocked,
        deviceLocation,
        cameraState,
        currentCamera,
        availableCameras,
        accelerometerDatasets,
        lastDatasets,
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

final class CameraInitialisationFailureState extends RecordPresentationState {
  const CameraInitialisationFailureState(this.failure);

  final Failure failure;
}

final class GetCamerasFailureState extends RecordPresentationState {
  const GetCamerasFailureState(this.failure);

  final Failure failure;
}

final class RecordSuccessState extends RecordPresentationState {
  const RecordSuccessState();
}

final class RecordFailureState extends RecordPresentationState {
  const RecordFailureState(this.failure);

  final Failure failure;
}
