import 'package:flutter/material.dart';

/// Show an app-wide snackbar with consistent styling.
///
/// Use [isError] to show a red background and [isSuccess] for green.
void showAppSnack(BuildContext context, String message, {bool isError = false, bool isSuccess = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError
          ? Colors.red
          : isSuccess
              ? Colors.green
              : null,
    ),
  );
}
