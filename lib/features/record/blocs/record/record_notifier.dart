import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/enums/device_location.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/features/record/repositories/record_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';

part 'record_state.dart';

final recordProvider =
    NotifierProvider.autoDispose<RecordNotifier, RecordState>(
  RecordNotifier.new,
);

class RecordNotifier extends AutoDisposeNotifier<RecordState> {
  RecordNotifier() : _recordRepository = RecordRepository();

  final RecordRepository _recordRepository;

  late final BluetoothCharacteristic _heartRateMeasureChar;
  late final BluetoothCharacteristic _heartRateControlChar;
  late final BluetoothCharacteristic _sensorChar;
  late final BluetoothCharacteristic _hzChar;
  late final BluetoothCharacteristic _notificationChar;

  final _stopwatch = Stopwatch();

  StreamSubscription<List<int>>? _heartRateMeasureSubscription;
  StreamSubscription<List<int>>? _sensorSubscription;
  StreamSubscription<List<int>>? _hzSubscription;

  int? _lastHeartRate;

  @override
  RecordState build() {
    ref.onDispose(() {
      _heartRateMeasureSubscription?.cancel();
      _sensorSubscription?.cancel();
      _hzSubscription?.cancel();
      _recordRepository.dispose();
    });

    return RecordState.initial();
  }

  Future<void> initialise(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    if (state.isInitialised) return;

    final miBand1Service = services.firstWhere(
      (service) => service.uuid.str128 == DeviceUuids.serviceMiBand1,
    );
    final heartRateService = services.firstWhere(
      (service) => service.uuid.str128 == DeviceUuids.serviceHeartRate,
    );
    final alertNotificationService = services.firstWhere(
      (service) => service.uuid.str128 == DeviceUuids.serviceAlertNotification,
    );

    _heartRateMeasureChar = heartRateService.characteristics.firstWhere(
      (char) => char.uuid.str128 == DeviceUuids.charHeartRateMeasure,
    );
    _heartRateControlChar = heartRateService.characteristics.firstWhere(
      (char) => char.uuid.str128 == DeviceUuids.charHeartRateControl,
    );
    _sensorChar = miBand1Service.characteristics.firstWhere(
      (char) => char.uuid.str128 == DeviceUuids.charSensor,
    );
    _hzChar = miBand1Service.characteristics.firstWhere(
      (char) => char.uuid.str128 == DeviceUuids.charHz,
    );
    _notificationChar = alertNotificationService.characteristics.firstWhere(
      (char) => char.uuid.str128 == DeviceUuids.charNotification,
    );

    final (failure, _) = await _recordRepository.setNotifyChars(
      [
        _heartRateMeasureChar,
        _sensorChar,
        _hzChar,
      ],
      notify: true,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: RecordFailureState(failure),
      );
    }

    _heartRateMeasureChar.onValueReceived.listen((event) {
      log('Heart Rate: $event');
      log('Last Heart Rate: $_lastHeartRate');
      _lastHeartRate = event[1];
    });

    _sensorSubscription ??= _sensorChar.onValueReceived.listen((event) {
      log('Sensor: $event');
    });

    _hzSubscription ??= _hzChar.onValueReceived.listen(_handleAccelerometer);

    final isCameraPermissionGranted =
        await _recordRepository.isCameraPermissionGranted;

    state = state.copyWith(
      isInitialised: true,
      isCameraPermissionGranted: isCameraPermissionGranted,
    );
  }

  void onDeviceLocationChanged(DeviceLocation deviceLocation) {
    state = state.copyWith(deviceLocation: deviceLocation);
  }

  void _handleAccelerometer(List<int> event) {
    final datasets =
        _recordRepository.handleRawSensorData(Uint8List.fromList(event));
    if (datasets != null && _stopwatch.isRunning) {
      const delay = 200;
      final lastElapsed =
          (state.lastDatasets?.lastOrNull?.timestamp?.inMilliseconds ?? 0) +
              delay;
      final elapsed = _stopwatch.elapsedMilliseconds;
      final fraction = (elapsed - lastElapsed) / datasets.length;

      for (var i = 0; i < datasets.length; i++) {
        final realTimestamp = (lastElapsed + (fraction * (i + 1))).toInt();
        // subtract by average delay bluetooth connection
        final tunedTimestamp = realTimestamp - delay;
        if (tunedTimestamp >= 0) {
          datasets[i] = datasets[i].copyWith(
            heartRate: _lastHeartRate,
            timestamp: Duration(
              milliseconds: tunedTimestamp,
            ),
          );
        }
      }
      datasets.removeWhere((dataset) => dataset.timestamp == null);
      state = state.copyWith(
        dataItems: [
          ...state.dataItems,
          ...datasets,
        ],
        lastDatasets: () => datasets,
      );
    }
  }

  Future<CameraController?> initialiseCameraController([
    CameraDescription? cameraDescription,
  ]) async {
    final CameraDescription camera;
    if (cameraDescription == null) {
      final (getCamerasFailure, cameras) =
          await _recordRepository.getAvailableCameras();
      if (getCamerasFailure != null) {
        if (getCamerasFailure is PermissionFailure) {
          state = state.copyWith(isCameraPermissionGranted: false);
        } else {
          state = state.copyWith(
            presentationState: GetCamerasFailureState(getCamerasFailure),
          );
        }
        return null;
      }
      camera = cameras[0];
      state = state.copyWith(availableCameras: cameras);
    } else {
      camera = cameraDescription;
    }

    state = state.copyWith(currentCamera: camera);

    final (initFailure, controller) =
        await _recordRepository.initialiseCameraController(camera);

    if (initFailure != null) {
      if (initFailure is PermissionFailure) {
        state = state.copyWith(isCameraPermissionGranted: false);
      } else {
        state = state.copyWith(
          presentationState: CameraInitialisationFailureState(initFailure),
        );
      }
      return null;
    }
    state = state.copyWith(
      isCameraPermissionGranted: true,
      cameraState: CameraState.ready,
    );
    return controller;
  }

  Future<void> startRecording(CameraController cameraController) async {
    state = state.copyWith(
      dataItems: [],
      lastDatasets: () => null,
      cameraState: CameraState.preparing,
    );
    _lastHeartRate = null;

    final (failure, _) = await _recordRepository.startRecording(
      _stopwatch,
      cameraController: cameraController,
      heartRateMeasureChar: _heartRateMeasureChar,
      heartRateControlChar: _heartRateControlChar,
      sensorChar: _sensorChar,
      hzChar: _hzChar,
      notificationChar: _notificationChar,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: RecordFailureState(failure),
        cameraState: CameraState.ready,
      );
      return;
    }
    state = state.copyWith(cameraState: CameraState.recording);
  }

  Future<void> stopRecording(CameraController cameraController) async {
    _stopwatch
      ..stop()
      ..reset();

    state = state.copyWith(cameraState: CameraState.saving);

    final (stopFailure, _) = await _recordRepository.stopRecording(
      cameraController: cameraController,
      heartRateMeasureChar: _heartRateMeasureChar,
      heartRateControlChar: _heartRateControlChar,
      sensorChar: _sensorChar,
      hzChar: _hzChar,
    );
    if (stopFailure != null) {
      state = state.copyWith(
        presentationState: RecordFailureState(stopFailure),
        cameraState: CameraState.ready,
      );
      return;
    }
    final (saveFailure, _) = await _recordRepository.saveRecording(
      cameraController: cameraController,
      deviceLocation: state.deviceLocation!,
      dataItems: state.dataItems,
    );
    if (saveFailure != null) {
      state = state.copyWith(
        presentationState: RecordFailureState(saveFailure),
        cameraState: CameraState.ready,
      );
      return;
    }
    state = state.copyWith(
      presentationState: const RecordSuccessState(),
      cameraState: CameraState.ready,
    );
  }

  void onLockChanged({required bool isLocked}) {
    state = state.copyWith(isLocked: isLocked);
  }
}
