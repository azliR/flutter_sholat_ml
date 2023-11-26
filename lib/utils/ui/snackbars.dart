import 'package:flutter/material.dart';

void showErrorSnackbar(BuildContext context, String message) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onError,
        ),
      ),
      backgroundColor: colorScheme.error,
    ),
  );
}

void showSnackbar(
  BuildContext context,
  String message, {
  bool hidePreviousSnackbar = false,
}) {
  if (hidePreviousSnackbar) ScaffoldMessenger.of(context).hideCurrentSnackBar();

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
