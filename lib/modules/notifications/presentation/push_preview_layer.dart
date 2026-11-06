import 'package:flutter/material.dart';

import 'package:hybrid_app/modules/notifications/presentation/push_notification_service.dart';

/// Shows the local test alert above [child] until it is tapped.
class PushPreviewLayer extends StatelessWidget {
  const PushPreviewLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final push = PushNotificationService.maybeOf(context);
    final preview = push?.preview;
    return Stack(
      children: [
        child,
        if (preview != null && push != null)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: _LocalNotificationBanner(
                title: preview.title,
                body: preview.body,
                onTap: () => push.onNotificationOpened(preview.payloadUrl),
              ),
            ),
          ),
      ],
    );
  }
}

class _LocalNotificationBanner extends StatelessWidget {
  const _LocalNotificationBanner({
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xF01C1C1E),
      elevation: 8,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('local-notification'),
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
