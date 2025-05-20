import 'package:flutter/material.dart'
    show
        AppBar,
        BuildContext,
        Card,
        Center,
        CircleAvatar,
        Colors,
        EdgeInsets,
        FontWeight,
        Icon,
        Icons,
        ListTile,
        ListView,
        MemoryImage,
        NeverScrollableScrollPhysics,
        Opacity,
        Padding,
        Scaffold,
        State,
        StatefulWidget,
        Text,
        TextStyle,
        Widget,
        Column;
import 'package:provider/provider.dart' show Consumer;
import 'dart:convert' show base64Decode;
import '../providers/notification_provider.dart' show NotificationProvider;
import '../models/notification_model.dart' show AppNotification;
import '../widgets/home/notification_item_widget.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification History')),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final history = provider.notificationHistory;
          if (history.isEmpty) {
            return const Center(child: Text('No cleared notifications.'));
          }
          // Group by appName
          final Map<String, List<AppNotification>> grouped = {};
          for (final n in history) {
            grouped.putIfAbsent(n.appName, () => []).add(n);
          }
          final apps = grouped.keys.toList();
          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final appName = apps[index];
              final appNotifications = grouped[appName]!;
              final iconData = appNotifications.first.iconData;
              Widget leadingWidget;
              if (iconData != null && iconData.isNotEmpty) {
                try {
                  leadingWidget = CircleAvatar(
                    backgroundImage: MemoryImage(base64Decode(iconData)),
                    backgroundColor: Colors.white,
                    radius: 22,
                  );
                } catch (e) {
                  leadingWidget = const CircleAvatar(
                    child: Icon(Icons.notifications),
                  );
                }
              } else {
                leadingWidget = const CircleAvatar(
                  child: Icon(Icons.notifications),
                );
              }
              return Opacity(
                opacity: 0.5,
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
                          subtitle: Text('${appNotifications.length} cleared'),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: appNotifications.length,
                          itemBuilder: (context, idx) {
                            final notification = appNotifications[idx];
                            return Opacity(
                              opacity: 0.5,
                              child: NotificationItemWidget(
                                notification: notification,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
