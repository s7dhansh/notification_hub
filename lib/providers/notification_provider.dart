import 'dart:async' show StreamSubscription;
import 'package:flutter/foundation.dart'
    show
        ChangeNotifier; // Already uses show, no change needed but included for completeness of the block
import '../models/notification_model.dart' show AppNotification;
import '../services/notification_service.dart' show NotificationService;
import '../services/icon_cache_service.dart' show IconCacheService;

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final _iconCacheService = IconCacheService();
  List<AppNotification> _notifications = [];
  bool _isInitialized = false;
  StreamSubscription<AppNotification>? _subscription;

  // Getters
  List<AppNotification> get notifications => _notifications;
  bool get isListening => _notificationService.isListening;
  bool get isInitialized => _isInitialized;

  // Constructor
  NotificationProvider() {
    _initialize();
  }

  // Initialize the provider
  Future<void> _initialize() async {
    await _notificationService.initialize();
    await loadNotifications();
    _startListeningToNotifications();
    _isInitialized = true;
    notifyListeners();
  }

  // Make method public
  Future<void> loadNotifications() async {
    _notifications = await _notificationService.getNotifications();
    notifyListeners();
  }

  // Start listening to notification stream
  void _startListeningToNotifications() {
    _subscription?.cancel();
    _subscription = _notificationService.notificationsStream.listen((
      notification,
    ) async {
      if (notification.iconData != null) {
        await _iconCacheService.cacheIcon(
          notification.packageName,
          notification.iconData!,
        );
      }

      if (notification.isRemoved) {
        // If notification is removed, update existing notifications
        _notifications =
            _notifications.map((n) {
              if (n.packageName == notification.packageName && !n.isRemoved) {
                return n.copyWith(isRemoved: true);
              }
              return n;
            }).toList();
      } else {
        // Deduplicate by ID
        if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications.insert(0, notification);
        }
      }
      notifyListeners();
    });
  }

  // Request notification listening permission
  Future<bool> requestPermission() async {
    final permissionGranted = await _notificationService.requestPermission();
    if (permissionGranted) {
      await _notificationService.startListening();
      notifyListeners();
    }
    return permissionGranted;
  }

  // Start notification listening
  Future<void> startListening() async {
    await _notificationService.startListening();
    notifyListeners();
  }

  // Stop notification listening
  Future<void> stopListening() async {
    await _notificationService.stopListening();
    notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _notificationService.clearAllNotifications();
    _notifications = [];
    notifyListeners();
  }

  // Get list of excluded app package names
  Future<Set<String>> getExcludedApps() async {
    return await _notificationService.getExcludedApps();
  }

  // Check if an app is excluded
  Future<bool> isAppExcluded(String packageName) async {
    return await _notificationService.isAppExcluded(packageName);
  }

  // Exclude an app from notification capture
  Future<void> excludeApp(String packageName) async {
    await _notificationService.excludeApp(packageName);
    notifyListeners();
  }

  // Include a previously excluded app
  Future<void> includeApp(String packageName) async {
    await _notificationService.includeApp(packageName);
    notifyListeners();
  }

  // Add pagination support
  Future<List<AppNotification>> getPaginatedNotifications(
    int page,
    int pageSize,
  ) async {
    final allNotifications = await _notificationService.getNotifications();
    final start = page * pageSize;
    final end = start + pageSize;

    if (start >= allNotifications.length) {
      return [];
    }

    return allNotifications.sublist(
      start,
      end.clamp(0, allNotifications.length),
    );
  }

  // Add method to clear notifications for a specific app
  Future<void> clearAppNotifications(String packageName) async {
    _notifications.removeWhere((n) => n.packageName == packageName);
    await _notificationService.clearAppNotifications(packageName);
    notifyListeners();
  }

  // Add method to remove a single notification
  Future<void> removeNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _notificationService.removeNotification(id);
    notifyListeners();
  }

  // Get notifications grouped by app with pagination
  Map<String, List<AppNotification>> getNotificationsByApp({
    int page = 0,
    int pageSize = 20,
  }) {
    final groupedNotifications = <String, List<AppNotification>>{};
    final startIndex = page * pageSize;

    final paginatedNotifications =
        _notifications
            .where((n) => !n.isRemoved)
            .skip(startIndex)
            .take(pageSize)
            .toList();

    for (final notification in paginatedNotifications) {
      if (!notification.isRemoved) {
        final appName = notification.appName;
        if (!groupedNotifications.containsKey(appName)) {
          groupedNotifications[appName] = [];
        }
        groupedNotifications[appName]!.add(notification);
      }
    }

    // Sort notifications within each app by timestamp (newest first)
    groupedNotifications.forEach((key, list) {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });

    return groupedNotifications;
  }

  Future<bool> getUseMockNotifications() async {
    return _notificationService.getUseMockNotifications();
  }

  Future<void> setUseMockNotifications(bool value) async {
    await _notificationService.setUseMockNotifications(value);
    notifyListeners();
  }

  // Add load more notifications method
  Future<bool> loadMoreNotifications() async {
    final currentLength = _notifications.length;
    final pageSize = 20;

    final moreNotifications = await getPaginatedNotifications(
      (currentLength ~/ pageSize),
      pageSize,
    );

    if (moreNotifications.isEmpty) {
      return false;
    }

    _notifications.addAll(moreNotifications);
    notifyListeners();
    return true;
  }

  // Send a test notification
  Future<void> sendTestNotification({
    String title = 'Test Notification',
    String body = 'This is a test notification',
  }) async {
    await _notificationService.sendTestNotification(
      title: title,
      body: body,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}
