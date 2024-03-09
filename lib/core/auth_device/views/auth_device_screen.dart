import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/utils/state_handlers/auth_device_state_handler.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

@RoutePage()
class AuthDeviceScreen extends ConsumerStatefulWidget {
  const AuthDeviceScreen({
    required this.device,
    required this.services,
    super.key,
  });

  final BluetoothDevice device;
  final List<BluetoothService> services;

  @override
  ConsumerState<AuthDeviceScreen> createState() => _AuthDeviceScreenState();
}

class _AuthDeviceScreenState extends ConsumerState<AuthDeviceScreen> {
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
    ref.listen(
      authDeviceProvider,
      (previous, next) => handleAuthDeviceState(
        context,
        previous,
        next,
        onAuthDeviceSuccess: () {
          context.router.popUntilRoot();
        },
      ),
    );

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar.large(
            title: Text('Authentication'),
          ),
        ],
        body: Column(
          children: [
            Padding(
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
                ),
              ),
            ),
            Align(
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
            // const Spacer(),
            // Text(
            //   'Or connect with',
            //   style: textTheme.bodySmall,
            // ),
            // SizedBox(
            //   width: double.infinity,
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: FilledButton.tonalIcon(
            //       style: FilledButton.styleFrom(
            //         padding: const EdgeInsets.symmetric(
            //           horizontal: 16,
            //           vertical: 12,
            //         ),
            //       ),
            //       onPressed: () async {
            //         await _notifier.authWithXiaomiAccount(
            //           'ALSG_CLOUDSRV_7E295D13FCBFA43B2120F90342153C20',
            //         );
            //         return;
            //         await context.router.push(
            //           AuthWithXiaomiAccountRoute(
            //             uri: Uri.parse(Urls.loginXiaomi),
            //             onAuthenticated: (accessToken) async {
            //               log(accessToken);
            //               await _notifier.authWithXiaomiAccount(accessToken);
            //             },
            //           ),
            //         );
            //       },
            //       icon: const Icon(
            //         CustomIcons.xiaomi_logo,
            //         color: Color(0xFFFF6900),
            //       ),
            //       label: const Text('Xiaomi Account'),
            //     ),
            //   ),
            // ),
            // SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
