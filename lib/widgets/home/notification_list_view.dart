import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'app_notification_card.dart'; // Will create this next

class NotificationListView extends StatefulWidget {
  final Map<String, List<AppNotification>> groupedNotifications;

  const NotificationListView({super.key, required this.groupedNotifications});

  @override
  NotificationListViewState createState() => NotificationListViewState();
}

class NotificationListViewState extends State<NotificationListView> {
  final ScrollController _scrollController = ScrollController();

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
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    if (!provider.isLoadingMore &&
        provider.hasMoreData &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      provider.setLoadingMore(true);
      final hasMore = await provider.loadMoreNotifications();
      provider.setHasMoreData(hasMore);
      provider.setLoadingMore(false);
    }
  }

  Future<void> _onRefresh() async {
    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    // Get the package names (apps)
    final apps = widget.groupedNotifications.keys.toList();

    // Define a very early DateTime as an initial value for fold
    final DateTime veryEarlyDateTime = DateTime.fromMillisecondsSinceEpoch(0);

    // Sort the apps based on the latest timestamp of notifications within each app's group.
    // This ensures apps with newer notifications appear higher in the list.
    apps.sort((a, b) {
      final latestTimestampA = widget.groupedNotifications[a]
          ?.map((n) => n.timestamp)
          .fold<DateTime>(
            // Fold over DateTime objects
            veryEarlyDateTime, // Start with a very early date
            (prev, current) =>
                current.isAfter(prev) ? current : prev, // Find the latest date
          );

      final latestTimestampB = widget.groupedNotifications[b]
          ?.map((n) => n.timestamp)
          .fold<DateTime>(
            // Fold over DateTime objects
            veryEarlyDateTime, // Start with a very early date
            (prev, current) =>
                current.isAfter(prev) ? current : prev, // Find the latest date
          );

      // Sort in descending order (latest timestamp first) using DateTime's compareTo
      // If fold result is null (shouldn't happen with veryEarlyDateTime), treat as very early
      return (latestTimestampB ?? veryEarlyDateTime).compareTo(
        latestTimestampA ?? veryEarlyDateTime,
      );
    });

    final provider = Provider.of<NotificationProvider>(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final packageName = apps[index];
                List<AppNotification> appNotifications =
                    widget.groupedNotifications[packageName]!;

                // Sort the notifications within each app group by timestamp in descending order.
                // This ensures the latest notification for a specific app is at the top of its card.
                // This sort method works correctly with DateTime objects
                appNotifications.sort(
                  (a, b) => b.timestamp.compareTo(a.timestamp),
                );

                if (appNotifications.isEmpty) return const SizedBox.shrink();

                return AppNotificationCard(
                  packageName: packageName,
                  appNotifications: appNotifications,
                );
              },
            ),
          ),
          if (provider.isLoadingMore) // Show a loading indicator at the bottom
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
