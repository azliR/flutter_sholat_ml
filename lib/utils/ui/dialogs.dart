import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      icon: const Icon(Symbols.error_rounded),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> showLoadingDialog(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return showDialog(
    context: context,
    barrierColor: colorScheme.surface.withOpacity(0.6),
    barrierDismissible: false,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: const Align(
          alignment: Alignment.topCenter,
          child: LinearProgressIndicator(),
        ),
      );
    },
  );
}
