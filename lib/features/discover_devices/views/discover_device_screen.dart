import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/constants/device_uuids.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/features/discover_devices/blocs/discover_device/discover_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class DiscoverDeviceScreen extends ConsumerStatefulWidget {
  const DiscoverDeviceScreen({super.key});

  @override
  ConsumerState<DiscoverDeviceScreen> createState() =>
      _DiscoverDevicePageState();
}

class _DiscoverDevicePageState extends ConsumerState<DiscoverDeviceScreen> {
  late final DiscoverDeviceNotifier _notifier;
  late final AuthDeviceNotifier _authDeviceNotifier;

  Future<void> _onConnectPressed(
    BluetoothDevice bluetoothDevice, {
    bool isBonded = false,
  }) async {
    if (!isBonded) {
      final result = await _authDeviceNotifier.connectDevice(bluetoothDevice);
      if (result == false) {
        return;
      }
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
        ..scanDevices();
      // ..getBondedDevices();
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
                onPressed: () =>
                    context.router.push(const ManualDeviceConnectRoute()),
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
                      icon: const Icon(Symbols.refresh_rounded),
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
                    FilledButton(
                      onPressed: () => _notifier.turnOnBluetooth(),
                      child: const Text('Turn on bluetooth'),
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
                final name = device.platformName;
                final isSupported =
                    scanResults[index].advertisementData.serviceUuids.any(
                          (service) =>
                              service.str128 == DeviceUuids.serviceMiBand1,
                        );
                return RoundedListTile(
                  title: Text(name.isEmpty ? 'Unknown device' : name),
                  subtitle: Text(device.remoteId.str),
                  leading: isSupported
                      ? const Icon(Symbols.watch_rounded)
                      : const Icon(Symbols.bluetooth_rounded),
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
                final name = device.platformName;
                final isSupported = device.servicesList.any(
                  (service) {
                    return service.serviceUuid.str128 ==
                        DeviceUuids.serviceMiBand1;
                  },
                );

                return RoundedListTile(
                  title: Text(name),
                  subtitle: Text(device.remoteId.str),
                  leading: isSupported
                      ? const Icon(Symbols.watch_rounded)
                      : const Icon(Symbols.bluetooth_rounded),
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
