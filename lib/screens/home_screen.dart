import 'package:flutter/material.dart'
    show
        AlertDialog,
        AppBar,
        BuildContext,
        Builder,
        Card,
        Column,
        CrossAxisAlignment,
        EdgeInsets,
        ElevatedButton,
        Expanded,
        FloatingActionButton,
        FontWeight,
        Icon,
        IconButton,
        Icons,
        Image,
        InkWell,
        ListTile,
        ListView,
        MainAxisAlignment,
        MainAxisSize,
        MaterialPageRoute,
        Navigator,
        NeverScrollableScrollPhysics,
        Padding,
        RefreshIndicator,
        Row,
        Scaffold,
        ScaffoldMessenger,
        ScrollController,
        SnackBar,
        SnackBarAction,
        State,
        StatefulWidget,
        Text,
        TextButton,
        TextOverflow,
        TextStyle,
        Theme,
        Widget,
        showDialog,
        debugPrint;
import 'package:provider/provider.dart' show Consumer, Provider;
import 'package:intl/intl.dart' show DateFormat;
import 'dart:convert' show base64Decode;

import '../providers/notification_provider.dart' show NotificationProvider;
import '../models/notification_model.dart' show AppNotification;
import '../widgets/empty_state.dart' show EmptyState;
import 'notification_detail_screen.dart' show NotificationDetailScreen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreData = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onScroll() async {
    if (!_isLoadingMore &&
        _hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      _isLoadingMore = true;
      final hasMore =
          await Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).loadMoreNotifications();

      setState(() {
        _hasMoreData = hasMore;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Hub'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.dashboard),
          //   onPressed: () {
          //     // Navigate to dashmon page
          //     Navigator.pushNamed(context, '/dashmon');
          //   },
          // ),
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
          debugPrint(
            'HomeScreen: notifications count = \\${provider.notifications.length}',
          );
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
      floatingActionButton: Builder(
        builder:
            (context) => FloatingActionButton.extended(
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Notification'),
              onPressed: () async {
                await Provider.of<NotificationProvider>(
                  context,
                  listen: false,
                ).sendTestNotification(
                  title: 'Test Notification',
                  body:
                      'This is a test notification sent from Notification Hub',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
      ),
    );
  }

  Widget _buildPermissionRequest(NotificationProvider provider) {
    return EmptyState(
      icon: Icons.notifications_active,
      title: 'Notification Access Required',
      message:
          'This app needs notification access permissions to capture and display notifications.',
      action: ElevatedButton(
        onPressed: () async {
          if (!context.mounted) return;
          final granted = await provider.requestPermission();
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

  Widget _buildNotificationList(
    Map<String, List<AppNotification>> groupedNotifications,
  ) {
    final apps = groupedNotifications.keys.toList();

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).loadNotifications();
      },
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
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
                    leadingWidget = Image.memory(
                      base64Decode(iconData),
                      width: 24,
                      height: 24,
                    );
                  } catch (e) {
                    // If decoding fails, show fallback icon
                    leadingWidget = const Icon(Icons.notifications);
                  }
                } else {
                  // If no icon data, show fallback icon
                  leadingWidget = const Icon(Icons.notifications);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: leadingWidget,
                        title: Text(
                          appName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${appNotifications.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showClearAppNotificationsDialog(packageName);
                              },
                            ),
                          ],
                        ),
                        onLongPress: () {
                          _showExcludeAppDialog(packageName);
                        },
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: appNotifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationItem(
                            appNotifications[index],
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
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
                  child: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

  void _confirmClearNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Notifications'),
            content: const Text(
              'Are you sure you want to clear all notifications?',
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
                  ).clearAllNotifications();
                  Navigator.pop(context);
                },
                child: const Text('Clear'),
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
}
