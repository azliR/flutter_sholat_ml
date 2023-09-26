import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class SavedDevicesPage extends ConsumerWidget {
  const SavedDevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    ref.listen(
      authDeviceProvider,
      (previous, next) => handleAuthDeviceState(context, previous, next),
    );

    final currentDevice =
        ref.watch(authDeviceProvider.select((state) => state.currentDevice));
    final savedDevices =
        ref.watch(authDeviceProvider.select((state) => state.savedDevices));

    return Material(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Saved Devices'),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return RoundedListTile(
                  title: Text(savedDevices[index].deviceName),
                  subtitle: Text(savedDevices[index].deviceId),
                  onTap: savedDevices[index] == currentDevice
                      ? null
                      : () {
                          authDeviceNotifier
                              .connectToSavedDevice(savedDevices[index]);
                        },
                  trailing: savedDevices[index] == currentDevice
                      ? const Text('CONNECTED')
                      : null,
                );
              },
              childCount: savedDevices.length,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: FilledButton.tonalIcon(
                onPressed: () {
                  context.router.push(const DiscoverDeviceRoute());
                },
                icon: const Icon(Symbols.add_rounded),
                label: const Text('Add new device'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
