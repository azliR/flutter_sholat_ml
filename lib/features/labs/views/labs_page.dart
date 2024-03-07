import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/features/labs/blocs/labs/labs_notifer.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class LabsPage extends ConsumerStatefulWidget {
  const LabsPage({super.key});

  @override
  ConsumerState<LabsPage> createState() => _LabsPageState();
}

class _LabsPageState extends ConsumerState<LabsPage> {
  late final LabsNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(labsProvider.notifier);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      labsProvider.select((value) => value.presentationState),
      (previous, presentationState) async {
        switch (presentationState) {
          case LabsInitialState():
            break;
          case PickModelProgressState():
            context.loaderOverlay.show();
          case PickModelSuccessState():
            context.loaderOverlay.hide();

            final currentBluetoothDevice =
                ref.read(authDeviceProvider).currentBluetoothDevice;
            final currentServices =
                ref.read(authDeviceProvider).currentServices;

            if (currentBluetoothDevice == null || currentServices == null) {
              showSnackbar(context, 'No connected device found');
              return;
            }

            await context.router.push(
              LabRoute(
                path: presentationState.path,
                device: currentBluetoothDevice,
                services: currentServices,
              ),
            );
          case PickModelFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, presentationState.failure.message);
        }
      },
    );

    return Material(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Labs'),
          ),
          SliverFillRemaining(
            child: IllustrationWidget(
              type: IllustrationWidgetType.noData,
              actions: [
                FilledButton.tonalIcon(
                  onPressed: () => _notifier.pickModel(),
                  icon: const Icon(Symbols.add_rounded),
                  label: const Text('Add model'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
