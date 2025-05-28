import 'package:flutter/material.dart'
    show
        MaterialPageRoute,
        Padding,
        Column,
        Row,
        Expanded,
        Navigator,
        Text,
        TextOverflow,
        Widget,
        BuildContext,
        StatelessWidget,
        Theme,
        EdgeInsets,
        MainAxisAlignment,
        CrossAxisAlignment,
        InkWell,
        TextStyle;
import 'package:intl/intl.dart' show DateFormat;

import '../../models/notification_model.dart' show AppNotification;
import '../../screens/notification_detail_screen.dart'
    show NotificationDetailScreen;

class NotificationItemWidget extends StatelessWidget {
  final AppNotification notification;

  const NotificationItemWidget({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
      notification.timestamp.year,
      notification.timestamp.month,
      notification.timestamp.day,
    );

    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM/yyyy');
    String timeText;

    if (notificationDate == today) {
      timeText = 'Today, ${timeFormat.format(notification.timestamp)}';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      timeText = 'Yesterday, ${timeFormat.format(notification.timestamp)}';
    } else {
      timeText =
          '${dateFormat.format(notification.timestamp)}, ${timeFormat.format(notification.timestamp)}';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    NotificationDetailScreen(notification: notification),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification.title.isNotEmpty)
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  timeText,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (notification.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
