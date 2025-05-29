import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'app_notification_card.dart'; // Will create this next

class NotificationListView extends StatefulWidget {
  const NotificationListView({super.key});

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
  final Set<String> _dismissedApps = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final groupedNotifications = provider.getNotificationsByApp();
        final apps =
            groupedNotifications.keys
                .where(
                  (k) =>
                      (groupedNotifications[k]?.isNotEmpty ?? false) &&
                      !_dismissedApps.contains(k),
                )
                .toList();
        debugPrint('NotificationListView: apps = $apps');

        final DateTime veryEarlyDateTime = DateTime.fromMillisecondsSinceEpoch(
          0,
        );
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
                    debugPrint(
                      'Building AppNotificationCard for $packageName with ${appNotifications.length} notifications',
                    );
                    if (appNotifications.isEmpty) {
                      debugPrint('Skipping $packageName because it is empty');
                      return const SizedBox.shrink();
                    }
                    return AppNotificationCard(
                      packageName: packageName,
                      appNotifications: appNotifications,
                      onDismissed: () {
                        setState(() {
                          _dismissedApps.add(packageName);
                        });
                        Provider.of<NotificationProvider>(
                          context,
                          listen: false,
                        ).clearAppNotifications(packageName);
                      },
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
      },
    );
  }
}
