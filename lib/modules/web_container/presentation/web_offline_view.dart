import 'package:flutter/material.dart';

import 'package:hybrid_app/core/l10n/app_text.dart';

class WebOfflineView extends StatelessWidget {
  const WebOfflineView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      key: const Key('web-offline'),
      color: theme.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 42,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('No connection'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('web-retry'),
                  onPressed: onRetry,
                  child: Text(context.tr('Try again')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
