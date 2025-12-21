import 'package:flutter/material.dart';

/// Shows a custom dialog with title, message and optional actions
Future<void> showCustomDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) async {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel?.call();
            },
            child: Text(cancelText),
          ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          child: Text(confirmText ?? 'OK'),
        ),
      ],
    ),
  );
}

/// Shows an error dialog
Future<void> showErrorDialog({
  required BuildContext context,
  required String message,
  String title = 'Error',
}) async {
  return showCustomDialog(
    context: context,
    title: title,
    message: message,
  );
}

/// Shows a success dialog
Future<void> showSuccessDialog({
  required BuildContext context,
  required String message,
  String title = 'Success',
}) async {
  return showCustomDialog(
    context: context,
    title: title,
    message: message,
  );
}
