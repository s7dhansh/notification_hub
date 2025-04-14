import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert' show base64Decode;

import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../widgets/empty_state.dart';
import 'notification_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              // Navigate to dashmon page
              Navigator.pushNamed(context, '/dashmon');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings page
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _confirmClearNotifications(context);
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          // Show permission request if not listening
          if (!provider.isListening) {
            return _buildPermissionRequest(provider);
          }

          // Get grouped notifications
          final groupedNotifications = provider.getNotificationsByApp();

          // Show empty state if no notifications
          if (groupedNotifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off,
              title: 'No notifications yet',
              message: 'Notifications will appear here as they arrive',
            );
          }

          // Build the notification list
          return _buildNotificationList(groupedNotifications);
        },
      ),
    );
  }

  Widget _buildPermissionRequest(NotificationProvider provider) {
    return EmptyState(
      icon: Icons.notifications_active,
      title: 'Notification Access Required',
      message: 'This app needs notification access permissions to capture and display notifications.',
      action: ElevatedButton(
        onPressed: () async {
          final granted = await provider.requestPermission();
          if (!granted && context.mounted) {
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

  Widget _buildNotificationList(Map<String, List<AppNotification>> groupedNotifications) {
    final apps = groupedNotifications.keys.toList();
    
    return ListView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final appName = apps[index];
        final appNotifications = groupedNotifications[appName]!;
        final packageName = appNotifications.first.packageName;
        
        // Get the icon of the first notification for this app
        final iconData = appNotifications.first.iconData;
        Widget leadingWidget;
        
        if (iconData != null && iconData.isNotEmpty) {
          // If we have an icon, decode and display it
          try {
            final iconBytes = base64Decode(iconData);
            leadingWidget = CircleAvatar(
              backgroundImage: MemoryImage(iconBytes),
              backgroundColor: Colors.transparent,
            );
          } catch (e) {
            // Fallback to text avatar if decoding fails
            leadingWidget = CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(appName[0].toUpperCase()),
            );
          }
        } else {
          // No icon available, use text avatar
          leadingWidget = CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(appName[0].toUpperCase()),
          );
        }
        
        return ExpansionTile(
          initiallyExpanded: true,
          leading: leadingWidget,
          title: GestureDetector(
            onLongPress: () => _showExcludeAppDialog(context, appName, packageName),
            child: Text(
              appName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text('${appNotifications.length} notifications'),
          children: appNotifications.map((notification) {
            return _buildNotificationItem(notification);
          }).toList(),
        );
      },
    );
  }
  
  void _showExcludeAppDialog(BuildContext context, String appName, String packageName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exclude $appName'),
        content: Text('Do you want to exclude $appName from notification capture? Notifications from this app will no longer be collected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final provider = Provider.of<NotificationProvider>(context, listen: false);
              provider.excludeApp(packageName);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$appName will no longer be tracked'),
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

  Widget _buildNotificationItem(AppNotification notification) {
    final timeFormat = DateFormat.jm(); // Format time as 3:30 PM
    final dateFormat = DateFormat.yMMMd(); // Format date as Apr 13, 2023
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
        notification.timestamp.year,
        notification.timestamp.month,
        notification.timestamp.day);

    String timeText;
    if (notificationDate == today) {
      timeText = 'Today, ${timeFormat.format(notification.timestamp)}';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      timeText = 'Yesterday, ${timeFormat.format(notification.timestamp)}';
    } else {
      timeText = '${dateFormat.format(notification.timestamp)}, ${timeFormat.format(notification.timestamp)}';
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NotificationDetailScreen(notification: notification),
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
                  child: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  void _confirmClearNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NotificationProvider>(context, listen: false)
                  .clearAllNotifications();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}