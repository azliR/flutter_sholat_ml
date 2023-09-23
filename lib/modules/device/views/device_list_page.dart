import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/device_list/device_list_notifier.dart';
import 'package:flutter_sholat_ml/modules/device/widgets/device_tile_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/dialogs.dart';
import 'package:flutter_sholat_ml/utils/ui/input_formatters.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';

@RoutePage()
class DeviceListPage extends ConsumerStatefulWidget {
  const DeviceListPage({super.key});

  @override
  ConsumerState<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends ConsumerState<DeviceListPage> {
  Future<void> _showInputMacDialog() async {
    final notifier = ref.read(deviceListProvider.notifier);

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
              prefixIcon: const Icon(Icons.bluetooth),
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

                final device = BluetoothDevice.fromId(macAddress);
                await notifier.connectDevice(device);
              },
              child: const Text('Input'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceListProvider.notifier)
        ..initialise()
        ..scanDevices()
        ..getBondedDevices();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final notifier = ref.read(deviceListProvider.notifier);

    ref.listen(deviceListProvider, (previous, next) {
      if (previous?.presentationState != next.presentationState) {
        final presentationState = next.presentationState;
        switch (presentationState) {
          case TurnOnBluetoothFailureState():
            showErrorSnackbar(context, 'Failed turning on bluetooth');
          case ScanDevicesFailureState():
            showErrorSnackbar(context, 'Failed scanning devices');
          case GetBondedDevicesFailureState():
            showErrorSnackbar(context, 'Failed getting bonded devices');
          case ConnectDeviceFailureState():
            showErrorSnackbar(context, 'Failed connecting to device');
          case SelectDeviceFailureState():
            showErrorSnackbar(context, 'Failed selecting device');
          case ConnectDeviceLoadingState():
            showLoadingDialog(context);
          case ConnectDeviceSuccessState():
            notifier.selectDevice(presentationState.device);
            Navigator.pop(context);
          case SelectDeviceLoadingState():
            showLoadingDialog(context);
          case SelectDeviceSuccessState():
            Navigator.pop(context);
            context.router.push(
              AuthDeviceRoute(
                device: presentationState.device,
                services: presentationState.services,
              ),
            );
          case DeviceListInitialState():
        }
      }
    });

    final isScanning =
        ref.watch(deviceListProvider.select((value) => value.isScanning));
    final bluetoothState =
        ref.watch(deviceListProvider.select((value) => value.bluetoothState));
    final scanResults =
        ref.watch(deviceListProvider.select((value) => value.scanResults));
    final bondedDevices =
        ref.watch(deviceListProvider.select((value) => value.bondedDevices));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Device List'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: FilledButton.tonalIcon(
                onPressed: _showInputMacDialog,
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
                        await notifier.scanDevices();
                      },
                      icon: const Icon(Icons.refresh),
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
                return DeviceTile(
                  title: Text(name.isEmpty ? 'Unknown device' : name),
                  subtitle: Text(device.remoteId.str),
                  leading: const Icon(Icons.bluetooth),
                  trailing: isSupported ? null : const Text('Not Supported'),
                  onTap: !isSupported
                      ? null
                      : () => notifier.connectDevice(device),
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

                return DeviceTile(
                  title: Text(name.isEmpty ? 'Unknown device' : name),
                  subtitle: Text(device.remoteId.str),
                  leading: const Icon(Icons.bluetooth),
                  trailing: isSupported ? null : const Text('Not Supported'),
                  onTap: !isSupported
                      ? null
                      : () async {
                          await notifier.selectDevice(device);
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
