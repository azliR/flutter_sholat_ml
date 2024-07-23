import 'dart:async';
import 'dart:developer';

import 'package:dartx/dartx_io.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/ml_model/repositories/ml_model_repository.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model_config.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/ml_model/ml_model_provider.dart';
import 'package:flutter_sholat_ml/features/record/repositories/record_repository.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';

part 'ml_model_state.dart';

class MlModelArg extends Equatable {
  const MlModelArg({required this.model});

  final MlModel model;

  @override
  List<Object?> get props => [model];
}

final mlModelProvider = NotifierProvider.autoDispose
    .family<MlModelNotifier, MlModelState, MlModelArg>(
  MlModelNotifier.new,
);

class MlModelNotifier
    extends AutoDisposeFamilyNotifier<MlModelState, MlModelArg> {
  MlModelNotifier()
      : _mlModelRepository = MlModelRepository(),
        _recordRepository = RecordRepository();

  final MlModelRepository _mlModelRepository;
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
  MlModelState build(MlModelArg arg) {
    ref.onDispose(() {
      _heartRateMeasureSubscription?.cancel();
      _sensorSubscription?.cancel();
      _hzSubscription?.cancel();
      _recordRepository.dispose();
      _mlModelRepository.dispose();
    });

    return MlModelState.initial(
      showBottomPanel: LocalStorageService.getMlModelShowBottomPanel(),
      model: arg.model,
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

  // final _s = Stopwatch()..start();
  // var _lastAverageElapsedMs = 0;
  // var _i = 0;

  Future<void> _handleAccelerometer(List<int> event) async {
    final datasets =
        _recordRepository.handleRawSensorData(Uint8List.fromList(event));

    // if (datasets != null) {
    //   print('Current elapsed: ${_s.elapsed.inMilliseconds} ms');
    //   _i++;

    //   _lastAverageElapsedMs =
    //       (_lastAverageElapsedMs * (_i - 1) + _s.elapsed.inMilliseconds) ~/ _i;

    //   print('Average elapsed: $_lastAverageElapsedMs ms');
    //   _s
    //     ..reset()
    //     ..start();
    // }

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

    final (failure, predictions) = await _mlModelRepository.predict(
      path: _mlModel.path,
      data: inputData,
      config: modelConfig,
      previousLabels: state.predictedCategories ?? [],
      skipWhenLocked: true,
      onPredicting: () {
        state = state.copyWith(
          predictState: PredictState.predicting,
          logs: [
            ...state.logs,
            'Predicting (${modelConfig.batchSize}, ${modelConfig.windowSize}, ${modelConfig.numberOfFeatures})',
          ],
        );
      },
    );

    if (failure != null) {
      state = state.copyWith(
        presentationState: PredictFailureState(failure),
        logs: [...state.logs, 'Predict failed: $failure'],
      );
      return;
    }

    if (predictions == null) {
      state = state.copyWith(
        logs: [...state.logs, 'Skipped'],
      );
      return;
    }

    state = state.copyWith(
      predictState: PredictState.ready,
      predictedCategory: predictions.last,
      predictedCategories: [...?state.predictedCategories, ...predictions],
      logs: [...state.logs, 'Predicted: $predictions'],
    );
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

  void setShowBottomPanel({required bool enable}) {
    _mlModelRepository.setShowBottomPanel(showBottomPanel: enable);
    state = state.copyWith(showBottomPanel: enable);
  }

  void setModel(MlModel model) {
    final updatedModel = model.copyWith(
      updatedAt: DateTime.now(),
    );
    _mlModelRepository.saveModel(updatedModel);
    state = state.copyWith(model: updatedModel);
  }

  void setModelConfig(MlModelConfig config) {
    final model = state.model.copyWith(config: config);
    final updatedModel = model.copyWith(
      updatedAt: DateTime.now(),
    );
    _mlModelRepository.saveModel(updatedModel);

    final selectedModel = ref.read(selectedMlModelProvider);
    if (selectedModel != null && selectedModel.id == model.id) {
      ref.read(selectedMlModelProvider.notifier).setModel(updatedModel);
    }

    state = state.copyWith(model: updatedModel);
  }
}
