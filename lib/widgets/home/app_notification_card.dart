import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../services/icon_cache_service.dart';
import 'dismissible_notification_item.dart';

class AppNotificationCard extends StatefulWidget {
  final String packageName;
  final List<AppNotification> appNotifications;

  const AppNotificationCard({
    super.key,
    required this.packageName,
    required this.appNotifications,
  });

  @override
  AppNotificationCardState createState() => AppNotificationCardState();
}

class AppNotificationCardState extends State<AppNotificationCard> {
  void _showExcludeAppDialog(String packageName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exclude App'),
            content: const Text(
              'Do you want to exclude this app from notification capture? Notifications from this app will no longer be collected.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final provider = Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  );
                  provider.excludeApp(packageName);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('App will no longer be tracked'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () {
                          provider.includeApp(packageName);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Exclude'),
              ),
            ],
          ),
    );
  }

  void _showClearAppNotificationsDialog(String packageName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Notifications'),
            content: const Text(
              'Are you sure you want to clear all notifications for this app?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  ).clearAppNotifications(packageName);
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  Widget _buildDefaultIcon() {
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      child: const Icon(Icons.notifications, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use appName from the most recent notification, fallback to package name's last segment
    final mostRecentNotification = widget.appNotifications.first;
    final appName =
        (mostRecentNotification.appName.isNotEmpty &&
                mostRecentNotification.appName !=
                    mostRecentNotification.packageName)
            ? mostRecentNotification.appName
            : widget.packageName.split('.').last;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            FutureBuilder<Uint8List?>(
              future: IconCacheService().getIcon(widget.packageName),
              builder: (context, snapshot) {
                Widget leadingWidget;

                if (snapshot.hasData && snapshot.data != null) {
                  leadingWidget = CircleAvatar(
                    backgroundImage: MemoryImage(snapshot.data!),
                    backgroundColor: Colors.transparent,
                    radius: 22,
                  );
                } else if (mostRecentNotification.iconData?.isNotEmpty ==
                    true) {
                  try {
                    leadingWidget = CircleAvatar(
                      backgroundImage: MemoryImage(
                        base64Decode(mostRecentNotification.iconData!),
                      ),
                      backgroundColor: Colors.transparent,
                      radius: 22,
                    );
                  } catch (e) {
                    leadingWidget = _buildDefaultIcon();
                  }
                } else {
                  leadingWidget = _buildDefaultIcon();
                }

                return ListTile(
                  leading: leadingWidget,
                  title: Text(
                    appName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.appNotifications.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          _showClearAppNotificationsDialog(widget.packageName);
                        },
                      ),
                    ],
                  ),
                  onLongPress: () {
                    _showExcludeAppDialog(widget.packageName);
                  },
                );
              },
            ),
            ...widget.appNotifications.map(
              (notification) => DismissibleNotificationItem(
                    notification: notification,
                    onDismissed: (notificationId) {
                      // The actual dismissal is handled by DismissibleNotificationItem
                      // This callback is just for notifying the parent if needed
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
