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

// Import the new widgets
import '../widgets/home/permission_request_widget.dart';
import '../widgets/home/notification_list_view.dart';
// The following two imports are needed in the other files, not here anymore
// import '../widgets/home/app_notification_card.dart';
// import '../widgets/home/notification_item_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Remove infinite scrolling state from here
  // final ScrollController _scrollController = ScrollController();
  // bool _hasMoreData = true;
  // bool _isLoadingMore = false;
  AppNotification? _lastDismissed;

  @override
  void initState() {
    super.initState();
    // Remove infinite scrolling listener from here
    // _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Remove infinite scrolling controller disposal from here
    // _scrollController.dispose();
    super.dispose();
  }

  // Remove infinite scrolling logic from here
  // Future<void> _onScroll() async {
  //   if (!_isLoadingMore &&
  //       _hasMoreData &&
  //       _scrollController.position.pixels >=
  //           _scrollController.position.maxScrollExtent * 0.8) {
  //     _isLoadingMore = true;
  //     final hasMore =
  //         await Provider.of<NotificationProvider>(
  //           context,
  //           listen: false,
  //         ).loadMoreNotifications();

  //     setState(() {
  //       _hasMoreData = hasMore;
  //       _isLoadingMore = false;
  //     });
  //   }
  // }

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
            'HomeScreen: notifications count = ${provider.notifications.length}',
          );
          // Show permission request if not listening
          if (!provider.isListening) {
            // Use the new PermissionRequestWidget
            return const PermissionRequestWidget();
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

          // Use the new NotificationListView
          return NotificationListView(
            groupedNotifications: groupedNotifications,
          );
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

  // Remove extracted widget build methods
  // Widget _buildPermissionRequest(NotificationProvider provider) {...}
  // Widget _buildNotificationList(...) {...}
  // Widget _buildDefaultIcon() {...}
  // Widget _buildNotificationCard({...}) {...}
  // Widget _buildNotificationItem(AppNotification notification) {...}

  // Remove extracted dialog methods
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
