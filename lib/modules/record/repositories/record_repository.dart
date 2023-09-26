import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:convert/convert.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordRepository {
  final hextChars = '0123456789ABCDEF'.split('');

  Future<(Failure?, CameraController?)> initialiseCamera([
    CameraDescription? cameraDescription,
  ]) async {
    try {
      if (!await isCameraPermissionGranted && !await requestCameraPermission) {
        return (PermissionFailure('Camera permission denied'), null);
      }

      final cameras = await availableCameras();

      final controller = CameraController(
        cameraDescription ?? cameras[0],
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
    Timer? timer, {
    required CameraController cameraController,
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
  }) async {
    try {
      await _startRealtimeData(
        timer,
        heartRateMeasureChar: heartRateMeasureChar,
        heartRateControlChar: heartRateControlChar,
        sensorChar: sensorChar,
        hzChar: hzChar,
      );
      await cameraController.startVideoRecording();
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed starting recording';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> stopRecording(
    Timer? timer, {
    required CameraController cameraController,
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
  }) async {
    try {
      await cameraController.pauseVideoRecording();
      await _stopRealtimeData(
        timer,
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
    required List<Dataset> accelerometerDatasets,
  }) async {
    final now = DateTime.now();
    final dir = await getApplicationDocumentsDirectory();
    const savedDir = Directories.savedDatasetDir;
    final fileName = now.toIso8601String();

    final fullSavedDir = await Directory('${dir.path}/$savedDir/$fileName')
        .create(recursive: true);

    try {
      final datasetStr =
          accelerometerDatasets.fold('', (previousValue, dataset) {
        final x = dataset.x.toStringAsFixed(6);
        final y = dataset.y.toStringAsFixed(6);
        final z = dataset.z.toStringAsFixed(6);
        final timeStamp = dataset.timestamp.inMilliseconds.toString();

        return '$previousValue$timeStamp,$x,$y,$z\n';
      });

      final videoFile = await cameraController.stopVideoRecording();

      await videoFile.saveTo('${fullSavedDir.path}/$fileName.mp4');

      await File('${fullSavedDir.path}/$fileName.csv')
          .writeAsString(datasetStr);

      // await FileSaver.instance.saveFile(
      //   name: now.toIso8601String(),
      //   mimeType: MimeType.csv,
      //   ext: 'csv',
      //   bytes: Uint8List.fromList(datasetStr.codeUnits),
      // );

      // await FileSaver.instance.saveFile(
      //   name: now.toIso8601String(),
      //   mimeType: MimeType.custom,
      //   customMimeType: 'mp4',
      //   ext: 'mp4',
      //   filePath: savedPath.path,
      // );
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

  Future<(Failure?, void)> _startRealtimeData(
    Timer? timer, {
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
      // ignore: parameter_assignments
      timer = Timer.periodic(const Duration(seconds: 12), (timer) async {
        await heartRateControlChar.write([0x16]);
      });

      log('Realtime started!');

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed starting realtime';
      final failure = Failure(message, error: e, stackTrace: stackTrace);

      await _stopRealtimeData(
        timer,
        heartRateMeasureChar: heartRateMeasureChar,
        heartRateControlChar: heartRateControlChar,
        sensorChar: sensorChar,
        hzChar: hzChar,
      );

      return (failure, null);
    }
  }

  Future<(Failure?, void)> _stopRealtimeData(
    Timer? timer, {
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
  }) async {
    log('Stopping realtime...');
    try {
      timer?.cancel();

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

  // void _parseRawAccel(Uint8List bytes) {
  //   final res = <Map<String, int>>[];
  //   for (var i = 0; i < 3; i++) {
  //     final g = ByteData.sublistView(bytes, 2 + i * 6, 6).buffer.asInt16List();
  //     res.add({'x': g[0], 'y': g[1], 'wtf': g[2]});
  //   }
  // }

  // void _parseRawAccel(Uint8List bytes) {
  //   for (var i = 0; i < 3; i++) {
  //     final g = bytes.buffer.asUint16List(i * 3 + 1, 3);
  //     setState(() {
  //       _accelerometerDatasets.add(
  //         Dataset(
  //           x: g[0].toDouble(),
  //           y: g[1].toDouble(),
  //           z: g[2].toDouble(),
  //           timestamp: DateTime.now(),
  //         ),
  //       );
  //     });
  //   }
  // }

  List<Dataset>? handleRawSensorData(Uint8List bytes, Stopwatch stopwatch) {
    final buf = ByteData.view(bytes.buffer);
    final type = buf.getInt8(0);
    final index = buf.getInt8(1) & 0xff;
    if (type == 0x00) {
      final datasets = <Dataset>[];
      log(hex.encode(bytes));
      final g = ByteData.sublistView(bytes).buffer.asInt16List();
      log('g: $g');

      for (var i = 1; i < g.length; i = i + 3) {
        final dataset = Dataset(
          x: g[i],
          y: g[i + 1],
          z: g[i + 2],
          timestamp: Duration(milliseconds: stopwatch.elapsedMilliseconds),
        );
        datasets.add(dataset);
      }
      return datasets;
    } else if (type == 0x01) {
      if ((bytes.length - 2) % 4 != 0) {
        log('Raw sensor value for type 1 not divisible by 4');
        return null;
      }

      for (var i = 2; i < bytes.length; i += 4) {
        final val = _toUint32(bytes, i);
        log('Raw sensor 1: $val');
      }
    } else if (type == 0x07) {
      final targetType = buf.getInt8(2) & 0xff;
      final tsMillis = buf.getInt64(3);
      log('Raw sensor timestamp for type=$targetType index=$index: $tsMillis');
    } else {
      log('Unknown raw sensor type: ${_hexdumpWrap(bytes)}');
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

  void handleRawSensorData2(
    Uint8List value,
    Stopwatch stopwatch, {
    required void Function(Dataset dataset) onUpdated,
  }) {
    const scaleFactor = 4100.0;
    const gravity = -9.81;
    final buf = ByteData.view(value.buffer);
    final type = buf.getInt8(0);
    final index = buf.getInt8(1) & 0xff;

    if (type == 0x00) {
      if ((value.length - 2) % 6 != 0) {
        log('Raw sensor value for type 0 not divisible by 6');
        return;
      }

      for (var i = 2; i < value.length; i += 6) {
        final x = (_toUint16(value, i) << 16) >> 16;
        final y = (_toUint16(value, i + 2) << 16) >> 16;
        final z = (_toUint16(value, i + 4) << 16) >> 16;
        log('Raw sensor raw g: x=$x y=$y z=$z');

        final gx = (x * gravity) / scaleFactor;
        final gy = (y * gravity) / scaleFactor;
        final gz = (z * gravity) / scaleFactor;

        log('Raw sensor g: x=$gx y=$gy z=$gz');
        onUpdated(
          Dataset(
            x: gx,
            y: gy,
            z: gz,
            timestamp: Duration(milliseconds: stopwatch.elapsedMilliseconds),
          ),
        );
      }
    } else if (type == 0x01) {
      if ((value.length - 2) % 4 != 0) {
        log('Raw sensor value for type 1 not divisible by 4');
        return;
      }

      for (var i = 2; i < value.length; i += 4) {
        final val = _toUint32(value, i);
        log('Raw sensor 1: $val');
      }
    } else if (type == 0x07) {
      final targetType = buf.getInt8(2) & 0xff;
      final tsMillis = buf.getInt64(3);
      log('Raw sensor timestamp for type=$targetType index=$index: $tsMillis');
    } else {
      log('Unknown raw sensor type: ${_hexdumpWrap(value)}');
    }
  }

  int _toUint16(Uint8List bytes, int offset) {
    return (bytes[offset + 0] & 0xff) | ((bytes[offset + 1] & 0xff) << 8);
  }

  int _toUint32(Uint8List bytes, int offset) {
    return (bytes[offset + 0] & 0xff) |
        ((bytes[offset + 1] & 0xff) << 8) |
        ((bytes[offset + 2] & 0xff) << 16) |
        ((bytes[offset + 3] & 0xff) << 24);
  }

  String _hexdumpWrap(Uint8List buffer) {
    return _hexdump(buffer, 0, buffer.length);
  }

  String _hexdump(Uint8List buffer, int offset, int length) {
    var lengthCopy = length;
    if (length == -1) {
      lengthCopy = buffer.length - offset;
    }

    final hexChars = List.filled(lengthCopy * 2, ' ');
    for (var i = 0; i < lengthCopy; i++) {
      final v = buffer[i + offset] & 0xFF;
      hexChars[i * 2] = hextChars[v >> 4];
      hexChars[i * 2 + 1] = hextChars[v & 0x0F];
    }
    return hexChars.join();
  }
}
