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
