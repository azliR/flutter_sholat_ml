import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
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
      await context.router.replace(const DiscoverDeviceRoute());
      return;
    }
    await _authDeviceNotifier.connectToSavedDevice(device);
  }

  Future<void> onFailure() async {
    showErrorSnackbar(context, 'Failed to connect to saved device');
    await context.router.pushAndPopUntil(
      const DiscoverDeviceRoute(),
      predicate: (_) => false,
    );
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

    ref.listen(
      authDeviceProvider,
      (previous, next) => handleAuthDeviceState(
        context,
        previous,
        next,
        onConnectDeviceLoadingState: () {},
        onConnectDeviceFailureState: (failure) => onFailure(),
        onConnectDeviceSuccessState: () {},
        onSelectDeviceLoadingState: () {},
        onSelectDeviceSuccessState: () {},
        onSelectDeviceFailureState: (failure) => onFailure(),
        onAuthDeviceLoadingState: () {},
        onAuthDeviceFailureState: (failure) => onFailure(),
        onAuthDeviceResponseFailureState: onFailure,
        onDisconnectDeviceFailure: (failure) => onFailure(),
        onGetPrimaryDeviceFailure: (failure) => onFailure(),
        onRemoveDeviceFailure: (failure) => onFailure(),
      ),
    );

    final presentationState = ref
        .watch(authDeviceProvider.select((state) => state.presentationState));

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Icon(
                Symbols.watch_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  switch (presentationState) {
                    AuthDeviceInitialState() => 'Initialising...',
                    ConnectDeviceLoadingState() =>
                      'Connecting to saved device...',
                    ConnectDeviceSuccessState() => 'Connected to saved device',
                    ConnectDeviceFailureState() =>
                      'Failed to connect to saved device',
                    SelectDeviceLoadingState() => 'Selecting device...',
                    SelectDeviceSuccessState() => 'Device selected',
                    SelectDeviceFailureState() => 'Failed to select device',
                    AuthDeviceLoadingState() => 'Authenticating...',
                    AuthDeviceSuccessState() => 'Authenticated',
                    AuthDeviceFailureState() => 'Authentication Failed',
                    AuthDeviceResponseFailureState() => 'Authentication Failed',
                    DisconnectDeviceFailure() => 'Failed to disconnect device',
                    GetPrimaryDeviceFailure() => 'Failed to get primary device',
                    RemoveDeviceFailure() => 'Failed to remove device',
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
