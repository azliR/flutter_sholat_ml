import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/core/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/modules/home/views/record_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.device,
    required this.services,
    super.key,
  });

  final BluetoothDevice device;
  final List<BluetoothService> services;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final BluetoothService _authService;
  late final BluetoothCharacteristic _authChar;

  final _authKeyController =
      TextEditingController(text: '4e2978939bfadcb1d160256a49e8e90d');

  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  Future<void> _requestRandom() async {
    try {
      log('Requesting random number...');
      final cmd = [0x02, 0x00];
      log('[Request Random CMD]: $cmd');
      await _authChar.write(cmd, withoutResponse: true);
    } catch (e, stackTrace) {
      log('Requesting random number', error: e, stackTrace: stackTrace);
    }
  }

  List<int> _generateAuthKey(String authKey) {
    final cmd = [0x01, 0x00];
    final key = enc.decodeHexString(authKey);
    return [...cmd, ...key];
  }

  Future<void> _sendKey(String authKey) async {
    try {
      log('Sending key: $authKey');
      final sendKeyCmd = _generateAuthKey(authKey);
      log('[Send Key CMD]: $sendKeyCmd');
      await _authChar.write(sendKeyCmd, withoutResponse: true);
      log('Key sended!');
    } catch (e, stackTrace) {
      log('Failed sending key: $authKey', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _sendEncRandom(String authKey, List<int> data) async {
    try {
      log('Sending encrypted random number: $data');
      final sendEncCmd = [0x03, 0x00];
      final encKey = _encrypt(authKey, data);
      final sendCmd = [...sendEncCmd, ...encKey];
      log('[Send Encrypted CMD]: $sendCmd');
      await _authChar.write(sendCmd, withoutResponse: true);
    } catch (e, stackTrace) {
      log('Failed sending encrypted key!', error: e, stackTrace: stackTrace);
    }
  }

  Uint8List _encrypt(String authKey, List<int> data) {
    final key = enc.Key.fromBase16(authKey);
    final aes = enc.AES(key, mode: enc.AESMode.ecb, padding: null);
    return aes.encrypt(Uint8List.fromList(data)).bytes;
  }

  // Future<void> _authNotif(bool enabled) async {
  //   if (enabled) {
  //     log('Enabling Auth Service notifications status...');
  //     await authChar.setNotifyValue(true);
  //   } else {
  //     log('Disabling Auth Service notifications status...');
  //     await authDesc.write([0x00, 0x00]);
  //   }
  // }

  @override
  void initState() {
    _authService = widget.services.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.serviceMiBand2),
    );
    _authChar = _authService.characteristics.singleWhere(
      (element) => element.uuid == Guid(DeviceUuids.charAuth),
    );

    _authChar.setNotifyValue(true);

    _valueSubscription ??= _authChar.onValueReceived.listen((value) async {
      log('Auth value: $value');

      final hexResponse = hex.encode(value.sublist(0, 3));
      if (hexResponse == '100101') {
        await _requestRandom();
        log('Set new key sucessfully!');
      } else if (hexResponse == '100201') {
        final number = value.sublist(3);
        await _sendEncRandom(_authKeyController.text.trim(), number);
      } else if (hexResponse == '100301') {
        log('Auth sucessfully!');
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => RecordPage(
              device: widget.device,
              services: widget.services,
            ),
          ),
        );
      } else if (hexResponse == '100308') {
        log('Auth key is wrong!');
      } else {
        log('Unknown response: $hexResponse');
      }
    });

    _connectionSubscription ??=
        widget.device.connectionState.listen((state) async {
      if (state == BluetoothConnectionState.disconnected) {
        await _valueSubscription?.cancel();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _authKeyController,
                decoration: InputDecoration(
                  labelText: 'Auth key',
                  prefixIcon: const Icon(Icons.key_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _requestRandom,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
