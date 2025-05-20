import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import 'notification_item_widget.dart';

class DismissibleNotificationItem extends StatefulWidget {
  final AppNotification notification;
  final Function(String) onDismissed;

  const DismissibleNotificationItem({
    super.key,
    required this.notification,
    required this.onDismissed,
  });

  @override
  State<DismissibleNotificationItem> createState() =>
      _DismissibleNotificationItemState();
}

class _DismissibleNotificationItemState
    extends State<DismissibleNotificationItem> {
  bool _isDismissed = false;
  AppNotification? _lastDismissed;

  @override
  Widget build(BuildContext context) {
    // If already dismissed, return an empty container
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: ValueKey(widget.notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _handleDismiss(),
      child: NotificationItemWidget(notification: widget.notification),
    );
  }

  Future<void> _handleDismiss() async {
    if (_isDismissed) return;

    if (!mounted) return;
    setState(() {
      _isDismissed = true;
      _lastDismissed = widget.notification;
    });

    // Notify parent about the dismissal
    widget.onDismissed(widget.notification.id);

    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    // Remove from active notifications
    await provider.removeNotification(widget.notification.id);

    if (mounted) {
      // Add to history
      await provider.addToHistory(widget.notification);

      // Show undo snackbar
      messenger.clearSnackBars(); // Clear any existing snackbars
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () async {
              if (_lastDismissed != null) {
                await provider.restoreNotification(_lastDismissed!);
                // The parent will handle rebuilding the list
              }
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
