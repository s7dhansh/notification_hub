import 'dart:typed_data';

import 'package:flutter/material.dart'
    show
        AlertDialog,
        Alignment,
        AppBar,
        BorderRadius,
        BoxDecoration,
        BuildContext,
        Builder,
        Card,
        CircleAvatar,
        Colors,
        Column,
        Container,
        CrossAxisAlignment,
        DismissDirection,
        Dismissible,
        EdgeInsets,
        ElevatedButton,
        Expanded,
        FloatingActionButton,
        FontWeight,
        FutureBuilder,
        Icon,
        IconButton,
        Icons,
        InkWell,
        ListTile,
        ListView,
        MainAxisAlignment,
        MainAxisSize,
        MaterialPageRoute,
        MemoryImage,
        Navigator,
        Padding,
        RefreshIndicator,
        RoundedRectangleBorder,
        Row,
        Scaffold,
        ScaffoldMessenger,
        ScrollController,
        SizedBox,
        SnackBar,
        SnackBarAction,
        State,
        StatefulWidget,
        Text,
        TextButton,
        TextOverflow,
        TextStyle,
        Theme,
        ValueKey,
        Widget,
        debugPrint,
        showDialog;
import 'package:notihub/services/icon_cache_service.dart';
import 'package:provider/provider.dart' show Consumer, Provider;
import 'package:intl/intl.dart' show DateFormat;
import 'dart:convert' show base64Decode;

import '../providers/notification_provider.dart' show NotificationProvider;
import '../models/notification_model.dart' show AppNotification;
import '../widgets/empty_state.dart' show EmptyState;
import 'notification_detail_screen.dart' show NotificationDetailScreen;
import 'notification_history_screen.dart' show NotificationHistoryScreen;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  AppNotification? _lastDismissed;

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
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Notification History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryScreen(),
                ),
              );
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
          final granted = await provider.requestPermission();
          if (!mounted) return;
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
                final packageName = apps[index];
                final appNotifications = groupedNotifications[packageName]!;
                if (appNotifications.isEmpty) return const SizedBox.shrink();

                // Use appName from the most recent notification, fallback to package name's last segment
                final mostRecentNotification = appNotifications.first;
                final appName =
                    (mostRecentNotification.appName.isNotEmpty &&
                            mostRecentNotification.appName !=
                                mostRecentNotification.packageName)
                        ? mostRecentNotification.appName
                        : packageName.split('.').last;

                // Build the leading widget with the app icon
                return FutureBuilder<Uint8List?>(
                  future: IconCacheService().getIcon(packageName),
                  builder: (context, snapshot) {
                    Widget leadingWidget;

                    if (snapshot.hasData && snapshot.data != null) {
                      // Use cached icon if available
                      leadingWidget = CircleAvatar(
                        backgroundImage: MemoryImage(snapshot.data!),
                        backgroundColor: Colors.transparent,
                        radius: 22,
                      );
                    } else if (mostRecentNotification.iconData?.isNotEmpty ==
                        true) {
                      // Fallback to the icon from the notification
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
                      // Default icon if no icon is available
                      leadingWidget = _buildDefaultIcon();
                    }

                    return _buildNotificationCard(
                      appName: appName,
                      packageName: packageName,
                      appNotifications: appNotifications,
                      leadingWidget: leadingWidget,
                    );
                  },
                );
              },
            ),
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

  Widget _buildNotificationCard({
    required String appName,
    required String packageName,
    required List<AppNotification> appNotifications,
    required Widget leadingWidget,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
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
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${appNotifications.length}',
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
                      _showClearAppNotificationsDialog(packageName);
                    },
                  ),
                ],
              ),
              onLongPress: () {
                _showExcludeAppDialog(packageName);
              },
            ),
            ...appNotifications.map(
              (notification) => Dismissible(
                key: ValueKey(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  if (!context.mounted) return;

                  setState(() {
                    _lastDismissed = notification;
                  });
                  await Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  ).removeNotification(notification.id);

                  if (!mounted) return;
                  await Provider.of<NotificationProvider>(
                    context,
                    listen: false,
                  ).addToHistory(notification);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification deleted'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () async {
                          if (_lastDismissed != null) {
                            await Provider.of<NotificationProvider>(
                              context,
                              listen: false,
                            ).restoreNotification(_lastDismissed!);
                            if (context.mounted) {
                              setState(() {
                                _lastDismissed = null;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
                child: _buildNotificationItem(notification),
              ),
            ),
          ],
        ),
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
      timeText = 'Today, \\${timeFormat.format(notification.timestamp)}';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      timeText = 'Yesterday, \\${timeFormat.format(notification.timestamp)}';
    } else {
      timeText =
          '\\${dateFormat.format(notification.timestamp)}, \\${timeFormat.format(notification.timestamp)}';
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
