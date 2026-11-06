import 'package:flutter/cupertino.dart';

import 'package:hybrid_app/core/l10n/app_text.dart';

/// In-app question shown before the system notification prompt.
Future<bool> showNotificationSoftPrompt(BuildContext context) {
  return showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return CupertinoAlertDialog(
        title: Text(dialogContext.tr('Allow alerts?')),
        content: Text(
          dialogContext.tr(
            'The system prompt appears only after you agree. Alerts stay off until then.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            key: const Key('push-soft-deny'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('Not now')),
          ),
          CupertinoDialogAction(
            key: const Key('push-soft-allow'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('Allow')),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
