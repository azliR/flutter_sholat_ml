import 'dart:async';
import 'dart:developer';

import 'package:async/async.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/record/repositories/record_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

part 'record_state.dart';

final recordProvider =
    StateNotifierProvider.autoDispose<RecordNotifier, RecordState>(
  (ref) => RecordNotifier(),
);

class RecordNotifier extends StateNotifier<RecordState> {
  RecordNotifier()
      : _recordRepository = RecordRepository(),
        super(RecordState.initial());

  final RecordRepository _recordRepository;

  late final BluetoothService _miBand1Service;
  late final BluetoothService _heartRateService;
  late final BluetoothCharacteristic _heartRateMeasureChar;
  late final BluetoothCharacteristic _heartRateControlChar;
  late final BluetoothCharacteristic _sensorChar;
  late final BluetoothCharacteristic _hzChar;

  Timer? _timer;
  StreamSubscription<List<int>>? _heartRateMeasureSubscription;
  StreamSubscription<List<int>>? _sensorSubscription;
  StreamSubscription<List<int>>? _hzSubscription;

  Future<void> initialise(
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    if (state.isInitialised) return;

    _miBand1Service = services.singleWhere(
      (service) => service.uuid == Guid(DeviceUuids.serviceMiBand1),
    );
    _heartRateService = services.singleWhere(
      (service) => service.uuid == Guid(DeviceUuids.serviceHeartRate),
    );
    _heartRateMeasureChar = _heartRateService.characteristics.singleWhere(
      (char) => char.uuid == Guid(DeviceUuids.charHeartRateMeasure),
    );
    _heartRateControlChar = _heartRateService.characteristics.singleWhere(
      (char) => char.uuid == Guid(DeviceUuids.charHeartRateControl),
    );
    _sensorChar = _miBand1Service.characteristics.singleWhere(
      (char) => char.uuid == Guid(DeviceUuids.charSensor),
    );
    _hzChar = _miBand1Service.characteristics.singleWhere(
      (char) => char.uuid == Guid(DeviceUuids.charHz),
    );

    StreamZip([
      _heartRateMeasureChar.onValueReceived,
      _hzChar.onValueReceived,
    ]).listen((event) {
      final heartRate = event[0];
      final hz = event[1];
      log('Heart rate: $heartRate, Hz: $hz');
    });

    _sensorSubscription ??= _sensorChar.onValueReceived.listen((event) {
      log('Sensor: $event');
    });

    _hzSubscription ??= _hzChar.onValueReceived.listen((event) {
      log('Hz: $event');
      _recordRepository.handleRawSensorData(
        Uint8List.fromList(event),
        onUpdated: (dataset) {
          Timer(const Duration(milliseconds: 10), () {
            state = state.copyWith(
              accelerometerDatasets: [
                ...state.accelerometerDatasets,
                dataset,
              ],
            );
          });
        },
      );
      // if (accelerometerDatasets == null) return;

      // state = state.copyWith(
      //   accelerometerDatasets: [
      //     ...state.accelerometerDatasets,
      //     ...accelerometerDatasets,
      //   ],
      // );
    });

    final isCameraPermissionGranted =
        await _recordRepository.isCameraPermissionGranted;

    state = state.copyWith(
      isInitialised: true,
      isCameraPermissionGranted: isCameraPermissionGranted,
    );
  }

  Future<CameraController?> initialiseCamera([
    CameraDescription? cameraDescription,
  ]) async {
    final (failure, controller) =
        await _recordRepository.initialiseCamera(cameraDescription);
    if (failure != null) {
      if (failure is PermissionFailure) {
        state = state.copyWith(isCameraPermissionGranted: false);
      } else {
        state = state.copyWith(
          presentationState: CameraInitialisationFailureState(failure),
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
    state = state.copyWith(cameraState: CameraState.preparing);

    final (failure, _) = await _recordRepository.startRecording(
      _timer,
      cameraController: cameraController,
      heartRateMeasureChar: _heartRateMeasureChar,
      heartRateControlChar: _heartRateControlChar,
      sensorChar: _sensorChar,
      hzChar: _hzChar,
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
    state = state.copyWith(cameraState: CameraState.saving);

    final (stopFailure, _) = await _recordRepository.stopRecording(
      _timer,
      cameraController: cameraController,
      heartRateMeasureChar: _heartRateMeasureChar,
      heartRateControlChar: _heartRateControlChar,
      sensorChar: _sensorChar,
      hzChar: _hzChar,
    );
    if (stopFailure != null) {
      state = state.copyWith(
        accelerometerDatasets: [],
        presentationState: RecordFailureState(stopFailure),
        cameraState: CameraState.ready,
      );
      return;
    }
    final (saveFailure, _) = await _recordRepository.saveRecording(
      cameraController: cameraController,
      accelerometerDatasets: state.accelerometerDatasets,
    );
    if (saveFailure != null) {
      state = state.copyWith(
        accelerometerDatasets: [],
        presentationState: RecordFailureState(saveFailure),
        cameraState: CameraState.ready,
      );
      return;
    }
    state = state.copyWith(
      accelerometerDatasets: [],
      presentationState: const RecordSuccessState(),
      cameraState: CameraState.ready,
    );
  }

  @override
  void dispose() {
    _heartRateMeasureSubscription?.cancel();
    _sensorSubscription?.cancel();
    _hzSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
