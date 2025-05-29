import 'package:flutter/material.dart'
    show
        AlertDialog,
        BorderRadius,
        BoxDecoration,
        BuildContext,
        Card,
        CircleAvatar,
        Colors,
        Column,
        Container,
        EdgeInsets,
        FontWeight,
        FutureBuilder,
        Icon,
        Icons,
        ListTile,
        MemoryImage,
        Navigator,
        Padding,
        RoundedRectangleBorder,
        ScaffoldMessenger,
        SnackBar,
        SnackBarAction,
        State,
        StatefulWidget,
        Text,
        TextButton,
        TextStyle,
        ValueKey,
        Widget,
        showDialog,
        Dismissible,
        DismissDirection,
        Alignment;
import 'package:provider/provider.dart' show Provider;
import 'package:flutter/foundation.dart' show Uint8List, VoidCallback;
import 'dart:convert' show base64Decode;

import '../../models/notification_model.dart' show AppNotification;
import '../../providers/notification_provider.dart' show NotificationProvider;
import '../../services/icon_cache_service.dart' show IconCacheService;
import 'notification_item.dart' show DismissibleNotificationItem;

class AppNotificationCard extends StatefulWidget {
  final String packageName;
  final List<AppNotification> appNotifications;
  final VoidCallback? onDismissed;

  const AppNotificationCard({
    super.key,
    required this.packageName,
    required this.appNotifications,
    this.onDismissed,
  });

  @override
  AppNotificationCardState createState() => AppNotificationCardState();
}

class AppNotificationCardState extends State<AppNotificationCard> {
  // final bool _isDismissed = false;

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

  // void _showClearAppNotificationsDialog(String packageName) {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (context) => AlertDialog(
  //           title: const Text('Clear Notifications'),
  //           content: const Text(
  //             'Are you sure you want to clear all notifications for this app?',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text('Cancel'),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 Provider.of<NotificationProvider>(
  //                   context,
  //                   listen: false,
  //                 ).clearAppNotifications(packageName);
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('Clear'),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  Widget _buildDefaultIcon() {
    return CircleAvatar(
      backgroundColor: Colors.grey[200],
      child: const Icon(Icons.notifications, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostRecentNotification = widget.appNotifications.first;
    final appName =
        (mostRecentNotification.appName.isNotEmpty &&
                mostRecentNotification.appName !=
                    mostRecentNotification.packageName)
            ? mostRecentNotification.appName
            : widget.packageName.split('.').last;

    return Dismissible(
      key: ValueKey(widget.packageName),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      onDismissed: (direction) async {
        if (widget.onDismissed != null) {
          widget.onDismissed!();
        }
        final messenger = ScaffoldMessenger.of(context);
        await Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).clearAppNotifications(widget.packageName);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('All notifications for $appName cleared')),
        );
      },
      child: Card(
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
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
