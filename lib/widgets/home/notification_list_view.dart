import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'app_notification_card.dart'; // Will create this next

class NotificationListView extends StatefulWidget {
  final Map<String, List<AppNotification>> groupedNotifications;

  const NotificationListView({Key? key, required this.groupedNotifications})
    : super(key: key);

  @override
  _NotificationListViewState createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
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
    final apps = widget.groupedNotifications.keys.toList();
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
                final appNotifications =
                    widget.groupedNotifications[packageName]!;
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
