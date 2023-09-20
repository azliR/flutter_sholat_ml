import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/core/constants/device_uuids.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({required this.device, required this.services, super.key});

  final BluetoothDevice device;
  final List<BluetoothService> services;

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late final BluetoothService _miBand1Service;
  late final BluetoothService _heartRateService;
  late final BluetoothCharacteristic _heartRateMeasureChar;
  late final BluetoothCharacteristic _heartRateControlChar;
  late final BluetoothCharacteristic _sensorChar;
  late final BluetoothCharacteristic _hzChar;

  final _accelerometerDatasets = <int>[];

  var _isRecording = false;

  Timer? _timer;
  StreamSubscription<List<int>>? _heartRateMeasureSubscription;
  StreamSubscription<List<int>>? _sensorSubscription;
  StreamSubscription<List<int>>? _hzSubscription;

  Future<void> _startRealtimeData() async {
    log('Starting realtime...');
    try {
      await _heartRateMeasureChar.setNotifyValue(true);
      await _sensorChar.setNotifyValue(true);
      await _hzChar.setNotifyValue(true);

      // stop heart monitor continues & manual
      await _heartRateControlChar.write([0x15, 0x02, 0x00]);
      await _heartRateControlChar.write([0x15, 0x01, 0x00]);

      // start hear monitor continues
      await _heartRateControlChar.write([0x15, 0x01, 0x01]);

      // enabling accelerometer & heart monitor raw data notifications

      await _sensorChar.write([0x01, 0x01, 0x19], withoutResponse: true);
      await _sensorChar.write([0x02], withoutResponse: true);

      // send ping request every 12 sec
      _timer = Timer.periodic(const Duration(seconds: 12), (timer) {
        _heartRateControlChar.write([0x16]);
      });

      setState(() {
        _isRecording = true;
      });
      log('Realtime started!');
    } catch (e, stackTrace) {
      log('Failed starting realtime', error: e, stackTrace: stackTrace);
      await _stopRealtimeData();
    }
  }

  // def _parse_raw_accel(self, bytes):
  //     res = []
  //     for i in xrange(3):
  //         g = struct.unpack('hhh', bytes[2 + i * 6:8 + i * 6])
  //         res.append({'x': g[0], 'y': g[1], 'wtf': g[2]})
  //     return res

  Future<void> _stopRealtimeData() async {
    log('Stopping realtime...');
    try {
      _timer?.cancel();

      // stop heart monitor continues
      await _heartRateControlChar.write([0x15, 0x01, 0x00]);
      await _heartRateControlChar.write([0x15, 0x02, 0x00]);

      await _sensorChar.write([0x03], withoutResponse: true);

      await _heartRateMeasureChar.setNotifyValue(false);
      await _sensorChar.setNotifyValue(false);

      setState(() {
        _isRecording = false;
      });
      log('Realtime stopped!');
    } catch (e, stackTrace) {
      log('Failed stopping realtime', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void initState() {
    _miBand1Service = widget.services.singleWhere(
      (service) => service.uuid == Guid(DeviceUuids.serviceMiBand1),
    );
    _heartRateService = widget.services.singleWhere(
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

    _heartRateMeasureSubscription =
        _heartRateMeasureChar.onValueReceived.listen((event) {
      setState(() {
        _accelerometerDatasets.add(event.last);
      });
      log('Heart rate: $event');
    });

    _sensorSubscription = _sensorChar.onValueReceived.listen((event) {
      log('Sensor: $event');
    });

    _hzSubscription = _hzChar.onValueReceived.listen((event) {
      log('Hz: $event');
    });
    super.initState();
  }

  @override
  void dispose() {
    _heartRateMeasureSubscription?.cancel();
    _sensorSubscription?.cancel();
    _hzSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Record'),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Text(
                _accelerometerDatasets.isEmpty
                    ? '0'
                    : _accelerometerDatasets.last.toString(),
                style: textTheme.displaySmall,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FilledButton(
              onPressed: _isRecording ? _stopRealtimeData : _startRealtimeData,
              child: Text(_isRecording ? 'Stop record' : 'Start record'),
            ),
          ),
        ],
      ),
    );
  }
}
