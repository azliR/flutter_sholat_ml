import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final AuthDeviceNotifier _authDeviceNotifier;

  Future<void> _connectToSavedDevice() async {
    final device = await _authDeviceNotifier.getPrimaryDevice();
    if (device == null) {
      if (!context.mounted) return;
      await context.router.replace(const SavedDevicesPage());
      return;
    }
    await _authDeviceNotifier.connectToSavedDevice(device);
  }

  Future<void> onFailure() async {
    showErrorSnackbar(context, 'Failed to connect to saved device');
    await context.router.pushAndPopUntil(
      const SavedDevicesPage(),
      predicate: (_) => false,
    );
  }

  Future<void> onSuccess() async {
    await context.router.pushAndPopUntil(
      const DatasetsPage(),
      predicate: (_) => false,
    );
  }

  @override
  void initState() {
    _authDeviceNotifier = ref.read(authDeviceProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
        onConnectDeviceLoading: () {},
        onConnectDeviceFailure: (failure) => onFailure(),
        onConnectDeviceSuccess: () {},
        onSelectDeviceLoading: () {},
        onSelectDeviceSuccess: () {},
        onSelectDeviceFailure: (failure) => onFailure(),
        onAuthDeviceSuccess: onSuccess,
        onAuthDeviceLoading: () {},
        onAuthDeviceFailure: (failure) => onFailure(),
        onAuthDeviceResponseFailure: onFailure,
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
                    AuthDeviceFailureState() => 'Authentication failed',
                    AuthDeviceResponseFailureState() => 'Authentication failed',
                    AuthWithXiaomiAccountLoadingState() =>
                      'Authenticating with xiaomi account...',
                    AuthWithXiaomiAccountSuccessState() =>
                      'Authenticated  with xiaomi account',
                    AuthWithXiaomiAccountFailureState() =>
                      'Authentication  with xiaomi account failed',
                    AuthWithXiaomiAccountResponseFailureState() =>
                      'Authentication  with xiaomi account failed',
                    DisconnectDeviceFailureState() =>
                      'Failed to disconnect device',
                    GetPrimaryDeviceFailureState() =>
                      'Failed to get primary device',
                    RemoveDeviceFailureState() => 'Failed to remove device',
                    GetDeviceNameLoadingState() => 'Getting device name...',
                    GetDeviceNameFailureState() => 'Failed to get device name',
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
