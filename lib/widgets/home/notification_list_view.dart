import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'app_notification_card.dart'; // Will create this next

class NotificationListView extends StatelessWidget {
  const NotificationListView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);
    final groupedNotifications = provider.getNotificationsByApp();
    final apps = groupedNotifications.keys.toList();

    final DateTime veryEarlyDateTime = DateTime.fromMillisecondsSinceEpoch(0);
    apps.sort((a, b) {
      final latestTimestampA = groupedNotifications[a]
          ?.map((n) => n.timestamp)
          .fold<DateTime>(
            veryEarlyDateTime,
            (prev, current) => current.isAfter(prev) ? current : prev,
          );
      final latestTimestampB = groupedNotifications[b]
          ?.map((n) => n.timestamp)
          .fold<DateTime>(
            veryEarlyDateTime,
            (prev, current) => current.isAfter(prev) ? current : prev,
          );
      return (latestTimestampB ?? veryEarlyDateTime).compareTo(
        latestTimestampA ?? veryEarlyDateTime,
      );
    });

    return RefreshIndicator(
      onRefresh: () async => await provider.loadNotifications(),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final packageName = apps[index];
                List<AppNotification> appNotifications =
                    groupedNotifications[packageName]!;
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
          if (provider.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
