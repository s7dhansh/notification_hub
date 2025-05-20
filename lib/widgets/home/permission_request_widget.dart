import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../empty_state.dart';

class PermissionRequestWidget extends StatelessWidget {
  const PermissionRequestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return EmptyState(
      icon: Icons.notifications_active,
      title: 'Notification Access Required',
      message:
          'This app needs notification access permissions to capture and display notifications.',
      action: ElevatedButton(
        onPressed: () async {
          final granted = await provider.requestPermission();
          if (!context.mounted) return;
          if (!granted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permission denied. Please enable in settings.'),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: const Text('Grant Permission'),
      ),
    );
  }
}
