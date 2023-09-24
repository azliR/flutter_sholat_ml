import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/discover_device/discover_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/input_formatters.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class DiscoverDevicePage extends ConsumerStatefulWidget {
  const DiscoverDevicePage({super.key});

  @override
  ConsumerState<DiscoverDevicePage> createState() => _DiscoverDevicePageState();
}

class _DiscoverDevicePageState extends ConsumerState<DiscoverDevicePage> {
  late final DiscoverDeviceNotifier _notifier;
  late final AuthDeviceNotifier _authDeviceNotifier;

  Future<void> _showInputMacDialog() async {
    var macAddress = '';
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Input MAC address'),
          content: TextFormField(
            autocorrect: false,
            autofocus: true,
            maxLength: 17,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              UpperCaseTextFormatter(),
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final macAddressFormat =
                  RegExp(r'^([0-9A-Za-z]{2}:){5}[0-9A-Za-z]{2}$');
              if (!macAddressFormat.hasMatch(value ?? '')) {
                return 'Mac address is not valid';
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'MAC address',
              prefixIcon: const Icon(Symbols.bluetooth),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => macAddress = value,
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final bluetoothDevice = BluetoothDevice.fromId(macAddress);
                await _onConnectPressed(bluetoothDevice);
              },
              child: const Text('Input'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onConnectPressed(
    BluetoothDevice bluetoothDevice, {
    bool isBonded = false,
  }) async {
    if (!isBonded) {
      await _authDeviceNotifier.connectDevice(bluetoothDevice);
    }
    final services = await _authDeviceNotifier.selectDevice(bluetoothDevice);
    if (services == null) return;

    if (!context.mounted) return;

    await context.router.push(
      AuthDeviceRoute(
        device: bluetoothDevice,
        services: services,
      ),
    );
  }

  @override
  void initState() {
    _notifier = ref.read(discoverDeviceProvider.notifier);
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier
        ..initialise()
        ..scanDevices()
        ..getBondedDevices();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    ref
      ..listen(discoverDeviceProvider, (previous, next) {
        if (previous?.presentationState != next.presentationState) {
          final presentationState = next.presentationState;
          switch (presentationState) {
            case TurnOnBluetoothFailureState():
              showErrorSnackbar(context, 'Failed turning on bluetooth');
            case ScanDevicesFailureState():
              showErrorSnackbar(context, 'Failed scanning devices');
            case GetBondedDevicesFailureState():
              showErrorSnackbar(context, 'Failed getting bonded devices');
            case DiscoverDeviceInitialState():
          }
        }
      })
      ..listen(
        authDeviceProvider,
        (previous, next) => handleAuthDeviceState(context, previous, next),
      );

    final isScanning =
        ref.watch(discoverDeviceProvider.select((value) => value.isScanning));
    final bluetoothState = ref
        .watch(discoverDeviceProvider.select((value) => value.bluetoothState));
    final scanResults =
        ref.watch(discoverDeviceProvider.select((value) => value.scanResults));
    final bondedDevices = ref
        .watch(discoverDeviceProvider.select((value) => value.bondedDevices));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Discover Device'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: FilledButton.tonalIcon(
                onPressed: _showInputMacDialog,
                icon: const Icon(Symbols.login_rounded),
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
                  if (isScanning)
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
                        await _notifier.scanDevices();
                      },
                      icon: const Icon(Symbols.refresh),
                    ),
                ],
              ),
            ),
          ),
          if (bluetoothState == BluetoothAdapterState.off)
            SliverToBoxAdapter(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(bluetoothState.toString()),
                    FilledButton(
                      onPressed: () async {
                        await FlutterBluePlus.turnOn();
                      },
                      child: const Text('Turn on'),
                    ),
                  ],
                ),
              ),
            ),
          if (scanResults.isEmpty)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No devices found'),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final device = scanResults[index].device;
                final name = device.localName;
                final isSupported =
                    scanResults[index].advertisementData.serviceUuids.any(
                          (service) => service == DeviceUuids.serviceMiBand1,
                        );
                return RoundedListTile(
                  title: Text(name.isEmpty ? 'Unknown device' : name),
                  subtitle: Text(device.remoteId.str),
                  leading: const Icon(Symbols.bluetooth),
                  trailing: isSupported ? null : const Text('Not Supported'),
                  onTap: !isSupported ? null : () => _onConnectPressed(device),
                );
              },
            ),
          if (bondedDevices.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Bonded devices',
                  style: textTheme.titleSmall,
                ),
              ),
            ),
            SliverList.builder(
              itemCount: bondedDevices.length,
              itemBuilder: (context, index) {
                final device = bondedDevices[index];
                final name = device.localName;
                final isSupported = device.type == BluetoothDeviceType.le;

                return RoundedListTile(
                  title: Text(name.isEmpty ? 'Unknown device' : name),
                  subtitle: Text(device.remoteId.str),
                  leading: const Icon(Symbols.bluetooth),
                  trailing: isSupported ? null : const Text('Not Supported'),
                  onTap: !isSupported
                      ? null
                      : () => _onConnectPressed(device, isBonded: true),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
