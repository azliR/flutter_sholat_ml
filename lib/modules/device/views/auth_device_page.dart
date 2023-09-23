import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/modules/device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/dialogs.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class AuthDevicePage extends ConsumerStatefulWidget {
  const AuthDevicePage({
    required this.device,
    required this.services,
    super.key,
  });

  final BluetoothDevice device;
  final List<BluetoothService> services;

  @override
  ConsumerState<AuthDevicePage> createState() => _AuthDevicePageState();
}

class _AuthDevicePageState extends ConsumerState<AuthDevicePage> {
  late final AuthDeviceNotifier _notifier;

  final _authController = TextEditingController();

  Future<void> _showClipboardDialog() async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (!context.mounted) return;

    if (clipboardData?.text == null || clipboardData?.text?.length != 32) {
      showErrorSnackbar(context, 'Your clipboard does not contain auth key');
      return;
    }

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste auth key?'),
        content: Text(clipboardData?.text ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _authController.text = clipboardData!.text!;
              Navigator.of(context).pop();
            },
            child: const Text('Paste'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    _notifier = ref.read(authDeviceProvider.notifier);
    super.initState();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authDeviceProvider, (previous, next) {
      if (previous?.presentationState != next.presentationState) {
        final presentationState = next.presentationState;
        switch (presentationState) {
          case AuthDeviceFailureState():
            Navigator.pop(context);
            showErrorSnackbar(context, 'Failed authenticating device');
          case AuthDeviceLoadingState():
            showLoadingDialog(context);
          case AuthDeviceSuccessState():
            Navigator.pop(context);
            context.router
                .pushAndPopUntil(const HomeRoute(), predicate: (_) => false);
          case AuthDeviceResponseFailureState():
            Navigator.pop(context);
            showErrorSnackbar(context, 'Failed authenticating device');
          case AuthDeviceInitialState():
            break;
        }
      }
    });

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Authentication'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextFormField(
                autofocus: true,
                controller: _authController,
                maxLength: 32,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) => value?.length != 32
                    ? 'Auth key must be 32 characters long'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Auth key',
                  prefixIcon: const Icon(Symbols.key_rounded),
                  suffixIcon: IconButton(
                    onPressed: _showClipboardDialog,
                    icon: const Icon(Symbols.content_paste_rounded),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: () => _notifier.auth(
                    _authController.text,
                    widget.device,
                    widget.services,
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
