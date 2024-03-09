import 'dart:async';
import 'dart:developer';

import 'package:dartx/dartx_io.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/lab/models/ml_model_config/ml_model_config.dart';
import 'package:flutter_sholat_ml/features/lab/repositories/lab_repository.dart';
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/record/repositories/record_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';

part 'lab_state.dart';

final labProvider = NotifierProvider.autoDispose<LabNotifier, LabState>(
  LabNotifier.new,
);

class LabNotifier extends AutoDisposeNotifier<LabState> {
  LabNotifier()
      : _labRepository = LabRepository(),
        _recordRepository = RecordRepository();

  final LabRepository _labRepository;
  final RecordRepository _recordRepository;

  late final MlModel _mlModel;
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

    return LabState.initial(
      showBottomPanel: LocalStorageService.getLabShowBottomPanel(),
      modelConfig: const MlModelConfig(
        enableTeacherForcing: false,
        batchSize: 1,
        windowSize: 10,
        numberOfFeatures: 3,
        inputDataType: InputDataType.float32,
        smoothings: {},
        filterings: {},
        temporalConsistencyEnforcements: {},
      ),
    );
  }

  Future<void> initialise(
    MlModel mlModel,
    BluetoothDevice device,
    List<BluetoothService> services,
  ) async {
    if (state.isInitialised) return;

    state = state.copyWith(
      logs: [...state.logs, 'Initialising...'],
    );

    _mlModel = mlModel;

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
        logs: [...state.logs, 'Initialising failed: $failure'],
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

    state = state.copyWith(
      isInitialised: true,
      logs: [...state.logs, 'Initialised'],
    );
  }

  void _handleAccelerometer(List<int> event) {
    final datasets =
        _recordRepository.handleRawSensorData(Uint8List.fromList(event));

    if (datasets == null || !_stopwatch.isRunning) return;

    final accelData = datasets.expand((e) => [e.x, e.y, e.z]).toList();
    final lastAccelData = [...?state.lastAccelData, ...accelData];

    state = state.copyWith(
      lastAccelData: () => lastAccelData,
    );

    final modelConfig = state.modelConfig;
    final totalDataSize = modelConfig.batchSize *
        modelConfig.windowSize *
        modelConfig.numberOfFeatures;

    if (lastAccelData.length < totalDataSize) {
      return;
    }

    final inputData = lastAccelData.takeLast(totalDataSize);

    final success = _labRepository.predict(
      path: _mlModel.path,
      data: inputData,
      config: modelConfig,
      previousLabels: modelConfig.enableTeacherForcing
          ? state.predictedCategories?.takeLast(modelConfig.batchSize)
          : null,
      onPredict: (labels) {
        state = state.copyWith(
          predictState: PredictState.ready,
          predictedCategory: labels.last,
          predictedCategories: [...?state.predictedCategories, ...labels],
          logs: [...state.logs, 'Predicted: $labels'],
        );
      },
      onError: (failure) {
        state = state.copyWith(
          presentationState: PredictFailureState(failure),
          logs: [...state.logs, 'Predict failed: $failure'],
        );
      },
    );
    if (!success) {
      state = state.copyWith(
        logs: [...state.logs, 'Skipped'],
      );
    } else {
      state = state.copyWith(
        predictState: PredictState.predicting,
        logs: [
          ...state.logs,
          'Predicting (${modelConfig.batchSize}, ${modelConfig.windowSize}, ${modelConfig.numberOfFeatures})',
        ],
      );
    }
  }

  Future<void> startRecording() async {
    state = state.copyWith(
      recordState: RecordState.preparing,
      lastAccelData: () => null,
      logs: [...state.logs, 'Starting to record...'],
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
        recordState: RecordState.ready,
        presentationState: PredictFailureState(failure),
        logs: [...state.logs, 'Starting recording failed: $failure'],
      );
      return;
    }
    state = state.copyWith(
      recordState: RecordState.recording,
      logs: [...state.logs, 'Started recording'],
    );
  }

  Future<void> stopRecording() async {
    _stopwatch
      ..stop()
      ..reset();

    state = state.copyWith(
      recordState: RecordState.stopping,
      logs: [...state.logs, 'Stopping recording'],
    );

    final (failure, _) = await _recordRepository.stopRecording(
      heartRateMeasureChar: _heartRateMeasureChar,
      heartRateControlChar: _heartRateControlChar,
      sensorChar: _sensorChar,
      hzChar: _hzChar,
    );
    if (failure != null) {
      state = state.copyWith(
        presentationState: PredictFailureState(failure),
        recordState: RecordState.ready,
        logs: [...state.logs, 'Stopping recording failed: $failure'],
      );
      return;
    }

    state = state.copyWith(
      presentationState: const PredictSuccessState(),
      recordState: RecordState.ready,
      logs: [...state.logs, 'Stopped recording'],
    );
  }

  Future<void> singlePredict(List<num> data) async {
    final modelConfig = state.modelConfig;

    state = state.copyWith(
      predictState: PredictState.predicting,
      logs: [
        ...state.logs,
        'Predicting (${modelConfig.batchSize}, ${modelConfig.windowSize}, ${modelConfig.numberOfFeatures})',
      ],
    );

    _labRepository.predict(
      path: _mlModel.path,
      data: data,
      config: modelConfig,
      previousLabels: null,
      onPredict: (labels) {
        state = state.copyWith(
          predictedCategory: labels[0],
          predictState: PredictState.ready,
          logs: [...state.logs, 'Predicted: $labels'],
        );
      },
      onError: (failure) {
        state = state.copyWith(
          predictState: PredictState.ready,
          logs: [...state.logs, 'Predict failed: $failure'],
          presentationState: PredictFailureState(failure),
        );
      },
    );
  }

  void setShowBottomPanel({required bool enable}) {
    _labRepository.setShowBottomPanel(showBottomPanel: enable);
    state = state.copyWith(showBottomPanel: enable);
  }

  void setModelConfig(MlModelConfig config) {
    state = state.copyWith(modelConfig: config);
  }
}
