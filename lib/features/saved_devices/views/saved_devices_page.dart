import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/dimens.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/core/auth_device/models/device/device.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class SavedDevicesPage extends ConsumerWidget {
  const SavedDevicesPage({super.key});

  Future<void> _showDeleteDeviceDialog({
    required BuildContext context,
    required String deviceName,
    required void Function() action,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $deviceName?'),
        content: Text(
          '$deviceName will be deleted and you need to connect it again to use it for this app. The data inside the device and this app will not be deleted.',
        ),
        icon: const Icon(Symbols.delete_rounded, weight: 600),
        iconColor: colorScheme.error,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              action();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final notifier = ref.read(authDeviceProvider.notifier);

    ref.listen(
      authDeviceProvider,
      (previous, next) => handleAuthDeviceState(context, previous, next),
    );

    final currentDevice =
        ref.watch(authDeviceProvider.select((state) => state.currentDevice));
    final savedDevices =
        ref.watch(authDeviceProvider.select((state) => state.savedDevices));

    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(
          title: Text('Saved Devices'),
        ),
        if (savedDevices.isEmpty)
          const SliverFillRemaining(
            child: IllustrationWidget(
              icon: Icon(Symbols.watch_off_rounded),
              title: Text('No devices saved, yet'),
              description: Text(
                "Once you connect a device, it'll show up here for easy access! 😉",
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final device = savedDevices[index];
                return RoundedListTile(
                  leading: const Icon(Symbols.watch_rounded),
                  title: Row(
                    children: [
                      Text(
                        device.deviceName,
                      ),
                      if (device == currentDevice) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Text(
                            'CONNECTED',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(device.deviceId),
                  trailing: _buildActions(
                    context: context,
                    ref: ref,
                    notifier: notifier,
                    device: device,
                  ),
                  onTap: () {
                    if (savedDevices[index] == currentDevice) {
                      AutoTabsRouter.of(context).setActiveIndex(index + 1);
                    } else {
                      notifier.connectToSavedDevice(savedDevices[index]);
                    }
                  },
                );
              },
              childCount: savedDevices.length,
            ),
          ),
        const SliverPadding(
          padding: EdgeInsets.only(bottom: Dimens.bottomListPadding),
        ),
      ],
    );
  }

  Widget _buildActions({
    required BuildContext context,
    required WidgetRef ref,
    required AuthDeviceNotifier notifier,
    required Device device,
  }) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: child!,
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Symbols.delete_rounded),
          onPressed: () async {
            await _showDeleteDeviceDialog(
              context: context,
              deviceName: device.deviceName,
              action: () => notifier.removeSavedDevice(device),
            );
          },
          child: const Text('Delete this device'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
