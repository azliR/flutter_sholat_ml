import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/input_formatters.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class ManualDeviceConnectScreen extends ConsumerStatefulWidget {
  const ManualDeviceConnectScreen({super.key});

  @override
  ConsumerState<ManualDeviceConnectScreen> createState() =>
      _ManualDeviceConnectScreenState();
}

class _ManualDeviceConnectScreenState
    extends ConsumerState<ManualDeviceConnectScreen> {
  late final AuthDeviceNotifier _authDeviceNotifier;

  final _macAddressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

    if (!mounted) return;

    await context.router.replace(
      AuthDeviceRoute(
        device: bluetoothDevice,
        services: services,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar.large(
            title: Text('Connect to Device'),
          ),
        ],
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              kBottomNavigationBarHeight,
            ),
            children: [
              TextFormField(
                controller: _macAddressController,
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
                decoration: const InputDecoration(
                  labelText: 'MAC address',
                  prefixIcon: Icon(Symbols.bluetooth_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    final bluetoothDevice =
                        BluetoothDevice.fromId(_macAddressController.text);
                    await _onConnectPressed(bluetoothDevice);
                  },
                  child: const Text('Connect'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
