import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_sholat_ml/modules/home/views/home_page.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  final _scanResults = <ScanResult>[];
  final _bondedDevices = <BluetoothDevice>[];
  var _isScanning = false;
  var _bluetoothState = BluetoothAdapterState.unknown;

  String? _connectingId;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  Future<void> _scanDevices() async {
    try {
      if (_isScanning) return;

      if (_bluetoothState != BluetoothAdapterState.on) {
        if (Platform.isAndroid) {
          await FlutterBluePlus.turnOn();
        } else {
          return;
        }
      }

      setState(() => _isScanning = true);

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
      );

      await Future<void>.delayed(const Duration(seconds: 15)).then((value) {
        setState(() => _isScanning = false);
      });
    } catch (e, stackTrace) {
      log('Failed scanning devices', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _getBondedDevices() async {
    try {
      await FlutterBluePlus.bondedDevices.then((devices) {
        setState(() {
          _bondedDevices
            ..clear()
            ..addAll(devices);
        });
      });
    } catch (e, stackTrace) {
      log('Failed getting bonded devices', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    try {
      _connectingId = device.remoteId.str;

      log('Connecting to $_connectingId');

      await device.connect(
        timeout: const Duration(seconds: 5),
        autoConnect: true,
      );

      log('Connected to $_connectingId');

      await _selectDevice(device);
    } catch (e, stackTrace) {
      log('Failed connecting to device', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _selectDevice(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => HomePage(
            device: device,
            services: services,
          ),
        ),
      );
    } catch (e, stackTrace) {
      log('Failed selecting device', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void initState() {
    _scanSubscription ??= FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (!_scanResults.contains(result)) {
          setState(() => _scanResults.add(result));
        }
      }
    });

    _adapterSubscription ??= FlutterBluePlus.adapterState.listen((event) {
      setState(() => _bluetoothState = event);
    });

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      unawaited(_scanDevices());
      unawaited(_getBondedDevices());
    });

    super.initState();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Device List'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: OutlinedButton.icon(
                onPressed: () async {
                  var macAddress = '';
                  await showDialog<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Input MAC address'),
                        content: TextField(
                          autocorrect: false,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'MAC address',
                            prefixIcon: const Icon(Icons.bluetooth),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (value) => macAddress = value,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(context);

                              final device = BluetoothDevice.fromId(macAddress);
                              await _connectDevice(device);
                            },
                            child: const Text('Input'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.login_rounded),
                label: const Text('Input MAC address manually'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available devices',
                    style: textTheme.titleSmall,
                  ),
                  if (_isScanning)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await _scanDevices();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
            ),
          ),
          if (_bluetoothState == BluetoothAdapterState.off)
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_bluetoothState.toString()),
                    ElevatedButton(
                      onPressed: () async {
                        await FlutterBluePlus.turnOn();
                      },
                      child: const Text('Turn on'),
                    ),
                  ],
                ),
              ),
            )
          else if (_scanResults.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No devices found'),
                ),
              ),
            ),
          SliverList.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final device = _scanResults[index].device;
              final name = device.localName;
              final isSupported =
                  _scanResults[index].advertisementData.serviceUuids.any(
                        (e) => e == '0000fee0-0000-1000-8000-00805f9b34fb',
                      );
              return ListTile(
                title: Text(name.isEmpty ? 'Unknown device' : name),
                subtitle: Text(device.remoteId.str),
                leading: const Icon(Icons.bluetooth),
                trailing: isSupported ? null : const Text('Not Supported'),
                onTap: !isSupported ? null : () => _connectDevice(device),
              );
            },
          ),
          if (_bondedDevices.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Divider(indent: 8, endIndent: 8),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Bonded devices',
                  style: textTheme.titleSmall,
                ),
              ),
            ),
            SliverList.builder(
              itemCount: _bondedDevices.length,
              itemBuilder: (context, index) {
                final device = _bondedDevices[index];
                final name = device.localName;
                final isSupported = device.type == BluetoothDeviceType.le;

                return ListTile(
                  title: Text(name.isEmpty ? 'Unknown device' : name),
                  subtitle: Text(device.remoteId.str),
                  leading: const Icon(Icons.bluetooth),
                  trailing: isSupported ? null : const Text('Not Supported'),
                  onTap: !isSupported
                      ? null
                      : () async {
                          await _connectDevice(device);
                          await _selectDevice(device);
                        },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
