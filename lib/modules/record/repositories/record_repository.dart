import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';
import 'package:flutter_sholat_ml/enums/device_location.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:flutter_sholat_ml/utils/services/local_dataset_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordRepository {
  Timer? _timer;

  Future<(Failure?, void)> setNotifyChars(
    List<BluetoothCharacteristic> chars, {
    required bool notify,
  }) async {
    try {
      await Future.wait(
        chars.map((char) async {
          if (char.isNotifying != notify) {
            await char.setNotifyValue(notify);
          }
        }),
      );
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed setting notify value';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, CameraController?)> initialiseCameraController(
    CameraDescription cameraDescription,
  ) async {
    try {
      if (!await isCameraPermissionGranted && !await requestCameraPermission) {
        return (PermissionFailure('Camera permission denied'), null);
      }

      final controller = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
      );
      await controller.initialize();
      await controller.prepareForVideoRecording();

      return (null, controller);
    } catch (e, stackTrace) {
      const message = 'Failed initialising camera controller';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<CameraDescription>)> getAvailableCameras() async {
    try {
      if (!await isCameraPermissionGranted && !await requestCameraPermission) {
        return (
          PermissionFailure('Camera permission denied'),
          <CameraDescription>[]
        );
      }

      final cameras = await availableCameras();
      return (null, cameras);
    } catch (e, stackTrace) {
      const message = 'Failed getting cameras';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, <CameraDescription>[]);
    }
  }

  Future<bool> get requestCameraPermission async {
    final permission = await Permission.camera.request();
    return permission.isGranted ||
        permission.isProvisional ||
        permission.isLimited;
  }

  Future<bool> get isCameraPermissionGranted async {
    final permission = await Permission.camera.status;
    return permission.isGranted ||
        permission.isProvisional ||
        permission.isLimited;
  }

  Future<(Failure?, void)> startRecording(
    Stopwatch stopwatch, {
    required CameraController cameraController,
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
  }) async {
    try {
      await _startRealtimeData(
        heartRateMeasureChar: heartRateMeasureChar,
        heartRateControlChar: heartRateControlChar,
        sensorChar: sensorChar,
        hzChar: hzChar,
      );
      await cameraController.startVideoRecording();
      stopwatch.start();
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed starting recording';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> stopRecording({
    required CameraController cameraController,
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
  }) async {
    try {
      await cameraController.pauseVideoRecording();
      await _stopRealtimeData(
        heartRateMeasureChar: heartRateMeasureChar,
        heartRateControlChar: heartRateControlChar,
        sensorChar: sensorChar,
        hzChar: hzChar,
      );
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed stopping recording';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> saveRecording({
    required CameraController cameraController,
    required List<DataItem> dataItems,
  }) async {
    final now = DateTime.now();
    final dir = await getApplicationDocumentsDirectory();
    const needReviewDir = Directories.needReviewDirPath;
    final dirName = now.toIso8601String();

    final fullSavedDir = await Directory('${dir.path}/$needReviewDir/$dirName')
        .create(recursive: true);

    try {
      final datasetProp = DatasetProp(
        id: dirName,
        datasetVersion: DatasetVersion.values.last,
        createdAt: now,
      );

      final videoFile = await cameraController.stopVideoRecording();

      const datasetCsvPath = Paths.datasetCsv;
      const datasetVideoPath = Paths.datasetVideo;
      const datasetPropPath = Paths.datasetProp;

      final fullDatasetCsvPath = '${fullSavedDir.path}/$datasetCsvPath';
      final fullDatasetPropPath = '${fullSavedDir.path}/$datasetPropPath';

      await videoFile.saveTo('${fullSavedDir.path}/$datasetVideoPath');

      final (failure, _) = await writeDataset(
        csvPath: fullDatasetCsvPath,
        propPath: fullDatasetPropPath,
        datasetProp: datasetProp,
        dataItems: dataItems,
      );
      if (failure != null) return (failure, null);

      LocalDatasetStorageService.putDataset(dirName, datasetProp);

      return (null, null);
    } catch (e, stackTrace) {
      if (fullSavedDir.existsSync()) {
        await fullSavedDir.delete(recursive: true);
      }

      const message = 'Failed saving recording';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> writeDataset({
    required String csvPath,
    required String propPath,
    required DatasetProp datasetProp,
    required List<DataItem> dataItems,
  }) async {
    try {
      final message = {
        'csvPath': csvPath,
        'propPath': propPath,
        'datasetProp': datasetProp,
        'dataItems': dataItems,
      };
      await compute(
        (message) async {
          final csvPath = message['csvPath']! as String;
          final propPath = message['propPath']! as String;
          final datasetProp = message['datasetProp']! as DatasetProp;
          final dataItems = message['dataItems']! as List<DataItem>;

          final datasetStr = dataItems.fold('', (previousValue, dataset) {
            return previousValue + dataset.toCsv();
          });

          await File(csvPath).writeAsString(datasetStr);
          await File(propPath).writeAsString(jsonEncode(datasetProp.toJson()));
        },
        message,
      );
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed writing dataset using compute';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> _startRealtimeData({
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
  }) async {
    log('Starting realtime...');
    try {
      await heartRateMeasureChar.setNotifyValue(true);
      await sensorChar.setNotifyValue(true);
      await hzChar.setNotifyValue(true);

      // stop heart monitor continues & manual
      await heartRateControlChar.write([0x15, 0x02, 0x00]);
      await heartRateControlChar.write([0x15, 0x01, 0x00]);

      // start hear monitor continues
      await heartRateControlChar.write([0x15, 0x01, 0x01]);

      // enabling accelerometer raw data continues
      await sensorChar.write([0x01, 0x03, 0x19], withoutResponse: true);
      await sensorChar
          .write([0x01, 0x03, 0x00, 0x00, 0x00, 0x19], withoutResponse: true);
      await sensorChar.write([0x02], withoutResponse: true);

      // send ping request every 12 sec
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        await heartRateControlChar.write([0x16]);
        if (timer.tick % 5 == 0) {
          await sensorChar.write([0x00], withoutResponse: true);
        }
      });

      log('Realtime started!');

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed starting realtime';
      final failure = Failure(message, error: e, stackTrace: stackTrace);

      await _stopRealtimeData(
        heartRateMeasureChar: heartRateMeasureChar,
        heartRateControlChar: heartRateControlChar,
        sensorChar: sensorChar,
        hzChar: hzChar,
      );

      return (failure, null);
    }
  }

  Future<(Failure?, void)> _stopRealtimeData({
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
  }) async {
    log('Stopping realtime...');
    try {
      _timer?.cancel();

      // stop heart monitor continues
      await heartRateControlChar.write([0x15, 0x01, 0x00]);
      await heartRateControlChar.write([0x15, 0x02, 0x00]);

      await sensorChar.write([0x03], withoutResponse: true);

      log('Realtime stopped!');

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed stopping realtime';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  List<DataItem>? handleRawSensorData(
    Uint8List bytes,
    DeviceLocation deviceLocation,
  ) {
    final byteData = ByteData.view(bytes.buffer);
    final type = byteData.getInt8(0);

    if (type == 0x00) {
      final datasets = <DataItem>[];
      final list = byteData.buffer.asInt16List();

      for (var i = 1; i < list.length; i = i + 3) {
        // final gx = (x * gravity) / scaleFactor;
        // final gy = (y * gravity) / scaleFactor;
        // final gz = (z * gravity) / scaleFactor;

        final dataset = DataItem(
          x: list[i],
          y: list[i + 1],
          z: list[i + 2],
          deviceLocation: deviceLocation,
        );
        datasets.add(dataset);
      }
      return datasets;
    }
    return null;
  }

  List<double> getEuler(List<int> g) {
    final gx = g[0];
    final gy = g[1];
    final gz = g[2];

    final roll = atan2(gy, gz);
    final pitch = atan2(-gx, sqrt(pow(gy, 2) + pow(gz, 2)));

    return [roll, pitch, 0];
  }

  void dispose() {
    _timer?.cancel();
  }
}
