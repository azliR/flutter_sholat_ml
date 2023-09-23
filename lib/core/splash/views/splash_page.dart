import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:flutter_sholat_ml/utils/ui/dialogs.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  late final AuthDeviceNotifier _authDeviceNotifier;

  Future<void> _connectToSavedDevice() async {
    final device = await _authDeviceNotifier.getPrimaryDevice();
    if (device == null) {
      if (!context.mounted) return;
      await context.router.replace(const DeviceListRoute());
      return;
    }
    await _authDeviceNotifier.connectToSavedDevice(device);
  }

  @override
  void initState() {
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await LocalStorageService.initialise();
      await _connectToSavedDevice();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(authDeviceProvider, (previous, next) {
      if (previous?.presentationState != next.presentationState) {
        switch (next.presentationState) {
          case AuthDeviceLoadingState():
            showLoadingDialog(context);
          case AuthDeviceSuccessState():
            context.router.replace(const HomeRoute());
          case AuthDeviceFailureState():
            showErrorSnackbar(context, 'Failed to connect to saved device');
            context.router.replace(const DeviceListRoute());
          case AuthDeviceResponseFailureState():
            showErrorSnackbar(context, 'Failed to connect to saved device');
            context.router.replace(const DeviceListRoute());
          case AuthDeviceInitialState():
            break;
        }
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Icon(
              Symbols.watch_rounded,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
