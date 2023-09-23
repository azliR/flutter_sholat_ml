import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeRepository {
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

  Future<(Failure?, void)> startRecording({
    required CameraController cameraController,
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
    required Timer? timer,
  }) async {
    try {
      await _startRealtimeData(
        heartRateMeasureChar: heartRateMeasureChar,
        heartRateControlChar: heartRateControlChar,
        sensorChar: sensorChar,
        hzChar: hzChar,
        timer: timer,
      );
      await cameraController.startVideoRecording();
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed starting recording';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, String?)> stopRecording({
    required CameraController cameraController,
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
    required Timer? timer,
  }) async {
    try {
      await cameraController.pauseVideoRecording();
      await _stopRealtimeData(
        heartRateMeasureChar: heartRateMeasureChar,
        heartRateControlChar: heartRateControlChar,
        sensorChar: sensorChar,
        hzChar: hzChar,
        timer: timer,
      );
      return (null, 'savedPath.toString()');
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
    try {
      final now = DateTime.now();

      final datasetStr =
          accelerometerDatasets.fold('', (previousValue, dataset) {
        final x = dataset.x.toStringAsFixed(6);
        final y = dataset.y.toStringAsFixed(6);
        final z = dataset.z.toStringAsFixed(6);
        final timeStamp = dataset.timestamp.millisecondsSinceEpoch;

        return '$previousValue$timeStamp,$x,$y,$z\n';
      });

      final savedPath = await cameraController.stopVideoRecording();

      await FileSaver.instance.saveFile(
        name: now.toIso8601String(),
        mimeType: MimeType.csv,
        ext: 'csv',
        bytes: Uint8List.fromList(datasetStr.codeUnits),
      );

      await FileSaver.instance.saveFile(
        name: now.toIso8601String(),
        mimeType: MimeType.custom,
        customMimeType: 'mp4',
        ext: 'mp4',
        filePath: savedPath.path,
      );
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed saving recording';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> _startRealtimeData({
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
    required Timer? timer,
  }) async {
    log('Starting realtime...');
    try {
      // await heartRateMeasureChar.setNotifyValue(true);
      await sensorChar.setNotifyValue(true);
      await hzChar.setNotifyValue(true);

      // stop heart monitor continues & manual
      // await heartRateControlChar.write([0x15, 0x02, 0x00]);
      // await heartRateControlChar.write([0x15, 0x01, 0x00]);

      // start hear monitor continues
      // await heartRateControlChar.write([0x15, 0x01, 0x01]);

      // enabling accelerometer raw data continues
      await sensorChar.write([0x01, 0x03, 0x19], withoutResponse: true);
      await sensorChar
          .write([0x01, 0x03, 0x00, 0x00, 0x00, 0x19], withoutResponse: true);
      await sensorChar.write([0x02], withoutResponse: true);

      // send ping request every 12 sec
      timer = Timer.periodic(const Duration(seconds: 12), (timer) async {
        await heartRateControlChar.write([0x16]);
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
        timer: timer,
      );

      return (failure, null);
    }
  }

  Future<(Failure?, void)> _stopRealtimeData({
    required BluetoothCharacteristic heartRateMeasureChar,
    required BluetoothCharacteristic heartRateControlChar,
    required BluetoothCharacteristic sensorChar,
    required BluetoothCharacteristic hzChar,
    required Timer? timer,
  }) async {
    log('Stopping realtime...');
    try {
      timer?.cancel();

      // stop heart monitor continues
      // await heartRateControlChar.write([0x15, 0x01, 0x00]);
      // await heartRateControlChar.write([0x15, 0x02, 0x00]);

      await sensorChar.write([0x03], withoutResponse: true);

      // await heartRateMeasureChar.setNotifyValue(false);
      await sensorChar.setNotifyValue(false);
      await hzChar.setNotifyValue(false);

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

  void handleRawSensorData(
    Uint8List value,
    void Function(Dataset dataset) onUpdated,
  ) {
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

        final gx = (x * gravity) / scaleFactor;
        final gy = (y * gravity) / scaleFactor;
        final gz = (z * gravity) / scaleFactor;

        log('Raw sensor g: x=$gx y=$gy z=$gz');
        onUpdated(
          Dataset(
            x: gx,
            y: gy,
            z: gz,
            timestamp: DateTime.now(),
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
