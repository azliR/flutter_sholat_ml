import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/modules/device/models/device/device.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';

class DeviceRepository {
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  Future<(Failure?, void)> turnOnBluetooth() async {
    try {
      log('Turning on bluetooth...');
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
      log('Bluetooth turned on');
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed turning on bluetooth';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> scanDevices() async {
    try {
      log('Scanning devices...');
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        removeIfGone: const Duration(seconds: 5),
      );

      await Future<void>.delayed(const Duration(seconds: 15));
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed scanning devices';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<BluetoothDevice>)> getBondedDevices() async {
    try {
      log('Getting bonded devices...');
      final bondedDevices = await FlutterBluePlus.bondedDevices;
      log('Got bonded devices: $bondedDevices');
      return (null, bondedDevices);
    } catch (e, stackTrace) {
      final failure = Failure(
        'Failed getting bonded devices',
        error: e,
        stackTrace: stackTrace,
      );
      return (failure, <BluetoothDevice>[]);
    }
  }

  Future<(Failure?, void)> connectDevice(BluetoothDevice device) async {
    try {
      log('Connecting to: ${device.remoteId.str}');

      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: true,
      );

      log('Connected to: ${device.remoteId.str}');
      return (null, null);
    } catch (e, stackTrace) {
      final message = 'Failed connecting to: ${device.remoteId.str}';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<BluetoothService>)> discoverServices(
    BluetoothDevice device,
  ) async {
    try {
      log('Selecting device: ${device.remoteId.str}');

      final services = await device.discoverServices();

      log('Selected device: ${device.remoteId.str}');
      return (null, services);
    } catch (e, stackTrace) {
      final message = 'Failed selecting device ${device.remoteId.str}';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, <BluetoothService>[]);
    }
  }

  Future<(Failure?, void)> requestRandomNumber(
    BluetoothCharacteristic authChar,
  ) async {
    try {
      log('Requesting random number...');

      final cmd = [0x02, 0x00];

      log('[Request Random CMD]: $cmd');

      await authChar.write(cmd, withoutResponse: true);
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Requesting random number';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> sendEncRandom(
    BluetoothCharacteristic authChar,
    String authKey,
    List<int> data,
  ) async {
    try {
      log('Sending encrypted random number: $data');

      final sendEncCmd = [0x03, 0x00];
      final encKey = _encrypt(authKey, data);
      final sendCmd = [...sendEncCmd, ...encKey];

      log('[Send Encrypted CMD]: $sendCmd');

      await authChar.write(sendCmd, withoutResponse: true);
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed sending encrypted key!';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Uint8List _encrypt(String authKey, List<int> data) {
    final key = enc.Key.fromBase16(authKey);
    final aes = enc.AES(key, mode: enc.AESMode.ecb, padding: null);
    return aes.encrypt(Uint8List.fromList(data)).bytes;
  }

  Future<Device?> getPrimaryDevice() async {
    final devices = await LocalStorageService.getSavedDevices();
    if (devices.isEmpty) return null;
    return devices.first;
  }

  Future<void> saveDevice(Device device) async {
    await LocalStorageService.setSavedDevice(device);
  }

  Stream<List<Device>> get savedDevicesStream =>
      LocalStorageService.savedDevicesStream;
}
