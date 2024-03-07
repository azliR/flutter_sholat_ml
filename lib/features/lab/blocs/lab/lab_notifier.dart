import 'dart:async';
import 'dart:developer';

import 'package:dartx/dartx_io.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/features/lab/repositories/lab_repository.dart';
import 'package:flutter_sholat_ml/features/record/repositories/record_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';

part 'lab_state.dart';

final labProvider = NotifierProvider.autoDispose<LabNotifier, LabState>(
  LabNotifier.new,
);

class LabNotifier extends AutoDisposeNotifier<LabState> {
  LabNotifier()
      : _labRepository = LabRepository(),
        _recordRepository = RecordRepository();

  static const int _timesteps = 40;

  final LabRepository _labRepository;
  final RecordRepository _recordRepository;

  late final String _path;
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
  LabState build() {
    ref.onDispose(() {
      _heartRateMeasureSubscription?.cancel();
      _sensorSubscription?.cancel();
      _hzSubscription?.cancel();
      _recordRepository.dispose();
      _labRepository.dispose();
    });

    return LabState.initial();
  }

  Future<void> initialise(
    String path,
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    if (state.isInitialised) return;

    _path = path;

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
        presentationState: PredictFailureState(failure),
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

    state = state.copyWith(isInitialised: true);
  }

  void _handleAccelerometer(List<int> event) {
    final datasets =
        _recordRepository.handleRawSensorData(Uint8List.fromList(event));

    if (datasets == null || !_stopwatch.isRunning) return;

    final accelData = datasets
        .expand((e) => [e.x.toDouble(), e.y.toDouble(), e.z.toDouble()])
        .toList();
    final lastAccelData = [...?state.lastAccelData, ...accelData];

    // log(lastAccelData.join(','));

    if (lastAccelData.length < _timesteps * 3) {
      log('Not enough data: ${lastAccelData.length}');
      state = state.copyWith(lastAccelData: () => lastAccelData);
      return;
    }

    log('Predicting...');

    final (failure, success) = _labRepository.predict(
      path: _path,
      data: Float32List.fromList(lastAccelData.takeLast(_timesteps * 3)),
      onPredict: (label) {
        log('Predicted: $label');
        state = state.copyWith(predictResult: label);
      },
    );
    if (failure != null || !success) {
      state = state.copyWith(
        // lastAccelData: () => lastAccelData.takeLast(_timesteps - 10),
        presentationState:
            failure != null ? PredictFailureState(failure) : null,
      );
    } else {
      state = state.copyWith(
        lastAccelData: () => null,
      );
    }
  }

  Future<void> startRecording() async {
    state = state.copyWith(
      dataItems: [],
      predictState: PredictState.preparing,
      lastAccelData: () => null,
    );
    _lastHeartRate = null;

    final (failure, _) = await _recordRepository.startRecording(
      _stopwatch,
      heartRateMeasureChar: _heartRateMeasureChar,
      heartRateControlChar: _heartRateControlChar,
      sensorChar: _sensorChar,
      hzChar: _hzChar,
      notificationChar: _notificationChar,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: PredictFailureState(failure),
      );
      return;
    }
    state = state.copyWith(predictState: PredictState.predicting);
  }

  Future<void> stopRecording() async {
    _stopwatch
      ..stop()
      ..reset();

    state = state.copyWith(predictState: PredictState.stopping);

    final (stopFailure, _) = await _recordRepository.stopRecording(
      heartRateMeasureChar: _heartRateMeasureChar,
      heartRateControlChar: _heartRateControlChar,
      sensorChar: _sensorChar,
      hzChar: _hzChar,
    );
    if (stopFailure != null) {
      state = state.copyWith(
        presentationState: PredictFailureState(stopFailure),
        predictState: PredictState.ready,
      );
      return;
    }

    state = state.copyWith(
      presentationState: const PredictSuccessState(),
      predictState: PredictState.ready,
    );
  }

  Future<void> predict(List<double> data) async {
    final (failure, _) = _labRepository.predict(
      path: _path,
      data: Float32List.fromList(data),
      onPredict: (label) {
        state = state.copyWith(predictResult: label);
      },
    );
    if (failure != null) {
      state = state.copyWith(presentationState: PredictFailureState(failure));
      return;
    }
  }
}
