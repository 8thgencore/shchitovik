import 'package:common_translations/common_translations.dart';
import 'package:flutter/material.dart';

/// Asks to confirm a destructive action; `true` only when the user confirmed.
///
/// [title] names the exact entity, [confirmLabel] is the destructive verb. «Отмена» gets the
/// initial focus, so Enter or Escape never delete anything by accident.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.translations.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
