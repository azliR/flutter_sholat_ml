import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/constants/urls.dart';
import 'package:flutter_sholat_ml/modules/device/models/device/device.dart';
import 'package:flutter_sholat_ml/modules/device/models/wearable.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';

class DeviceRepository {
  final _dio = Dio(
    BaseOptions(
      contentType: Headers.jsonContentType,
    ),
  );

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

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

  Future<(Failure?, void)> disconnectDevice(BluetoothDevice device) async {
    try {
      log('Disconnecting from: ${device.remoteId.str}');

      await device.disconnect(timeout: 10);

      log('Disconnected from: ${device.remoteId.str}');
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

  Future<(Failure?, List<Wearable>?)> loginWithXiaomiAccount(
    String accessToken,
  ) async {
    try {
      final random = Random();
      final deviceId1 = random.nextInt(256).toRadixString(16).padLeft(2, '0');
      final deviceId2 = random.nextInt(256).toRadixString(16).padLeft(2, '0');
      final deviceId3 = random.nextInt(256).toRadixString(16).padLeft(2, '0');
      final deviceId = '02:00:00:$deviceId1:$deviceId2:$deviceId3';

      const url = Urls.loginAmazfit;
      final body = Payloads.loginAmazfit;

      body['country_code'] = 'US';
      body['device_id'] = deviceId;
      body['third_name'] = 'mi-watch';
      body['code'] = accessToken;
      body['grant_type'] = 'request_token';

      log(body.toString());

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          followRedirects: false,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final statusCode = response.statusCode;
      final data = response.data;
      log(data?.toString() ?? 'no data');

      if ((statusCode != null && statusCode >= 400) || data == null) {
        final failure = Failure('Failed logging in with xiaomi account');
        return (failure, null);
      }

      final loginResult = jsonDecode(data as String) as Map<String, dynamic>;

      if (loginResult.containsKey('error_code')) {
        final errorCode = loginResult['error_code'] as String;
        if (errorCode == '0106') {
          final failure = Failure('0106. Verification failed, wrong token.');
          return (failure, null);
        } else if (errorCode == '0113') {
          final failure = Failure('0113. Wrong region.');
          return (failure, null);
        } else if (errorCode == '0115') {
          final failure = Failure('0115. Account disabled.');
          return (failure, null);
        } else if (errorCode == '0117') {
          final failure = Failure('0117. Account not registered.');
          return (failure, null);
        } else {
          final failure = Failure('Unknown error code: $errorCode');
          return (failure, null);
        }
      } else if (!loginResult.containsKey('error_code')) {
        final failure = Failure("No 'token_info' parameter in login data.");
        return (failure, null);
      }

      final tokenInfo = loginResult['token_info'] as Map<String, dynamic>;
      if (!tokenInfo.containsKey('app_token')) {
        final failure = Failure("No 'app_token' parameter in login data.");
        return (failure, null);
      } else if (!tokenInfo.containsKey('login_token')) {
        final failure = Failure("No 'login_token' parameter in login data.");
        return (failure, null);
      } else if (!tokenInfo.containsKey('user_id')) {
        final failure = Failure("No 'user_id' parameter in login data.");
        return (failure, null);
      }
      final appToken = tokenInfo['app_token'] as String;
      final loginToken = tokenInfo['login_token'] as String;
      final userId = tokenInfo['user_id'] as String;

      final (failure, wearables) = await getWearables(
        userId: userId,
        appToken: appToken,
        loginToken: loginToken,
      );

      if (failure != null) return (failure, null);

      return (null, wearables);
    } on DioException catch (e, stackTrace) {
      final message = e.message ?? 'Failed logging in with xiaomi account';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    } catch (e, stackTrace) {
      const message = 'Failed logging in with xiaomi account';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<Wearable>?)> getWearables({
    required String userId,
    required String appToken,
    required String loginToken,
  }) async {
    try {
      final devicesUrl = Urls.linkedDevices
          .replaceAll('{user_id}', Uri.encodeComponent(userId));

      final headers = Map<String, String>.from(Payloads.linkedDevices);
      headers['apptoken'] = appToken;

      final params = {'enableMultiDevice': 'true'};

      final response = await _dio
          .getUri<String>(
            Uri.parse(devicesUrl),
            options: Options(
              headers: headers,
            ),
            data: params,
          )
          .timeout(const Duration(seconds: 10));

      final statusCode = response.statusCode;
      final data = response.data;
      log(data ?? 'no data');
      if ((statusCode != null && statusCode >= 400) || data == null) {
        final failure = Failure('Failed getting devices');
        return (failure, null);
      }
      final deviceRequest = json.decode(data) as Map;
      if (!deviceRequest.containsKey('items')) {
        final failure = Failure("No 'items' parameter in devices data.");
        return (failure, null);
      }

      final devices = deviceRequest['items'] as List<Map>;
      final wearables = <Wearable>[];

      for (final wearable in devices) {
        if (!wearable.containsKey('macAddress')) {
          final failure = Failure("No 'macAddress' parameter in device data.");
          return (failure, null);
        }
        final macAddress = wearable['macAddress'] as String;

        if (!wearable.containsKey('additionalInfo')) {
          final failure =
              Failure("No 'additionalInfo' parameter in device data.");
          return (failure, null);
        }
        final deviceInfo = json.decode(wearable['additionalInfo'] as String)
            as Map<String, dynamic>;

        final keyStr = deviceInfo['auth_key'] as String? ?? '';
        final authKey = '0x${keyStr.isNotEmpty ? keyStr : '00'}';

        wearables.add(
          Wearable(
            activeStatus: wearable['activeStatus'] == 1,
            macAddress: macAddress,
            authKey: authKey,
            deviceSource: wearable['deviceSource'].toString(),
            firmwareVersion: wearable['firmwareVersion'] as String? ?? 'v-1',
            hardwareVersion: deviceInfo['hardwareVersion'] as String? ?? 'v-1',
            productionSource: deviceInfo['productVersion'] as String? ?? '0',
          ),
        );
      }

      return (null, wearables);
    } on DioException catch (e, stackTrace) {
      final message = e.message ?? 'Failed logging in with xiaomi account';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    } catch (e, stackTrace) {
      const message = 'Failed getting wearable';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
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

  Device? getPrimaryDevice() {
    final devices = LocalStorageService.getSavedDevices();
    if (devices.isEmpty) return null;
    return devices.first;
  }

  Device? getDeviceById(String deviceId) {
    final devices = LocalStorageService.getSavedDevices();
    if (devices.isEmpty) return null;
    return devices.firstWhere((device) => device.deviceId == deviceId);
  }

  Future<(Failure?, void)> saveDevice(Device device) async {
    try {
      await LocalStorageService.setSavedDevice(device);
      return (null, null);
    } catch (e, stackTrace) {
      final message = 'Failed saving device: $device';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> removeDevice(Device device) async {
    try {
      await LocalStorageService.deleteSavedDevice(device);
      return (null, null);
    } catch (e, stackTrace) {
      final message = 'Failed removing device: $device';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, String?)> getDeviceName(
    BluetoothCharacteristic deviceNameChar,
  ) async {
    try {
      log('Getting device name...');
      final resultBytes = await deviceNameChar.read();
      final deviceName = utf8.decode(resultBytes);

      return (null, deviceName);
    } catch (e, stackTrace) {
      const message = 'Failed sending encrypted key!';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Stream<List<Device>> get savedDevicesStream =>
      LocalStorageService.savedDevicesStream;
}
