import 'dart:async';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
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
    await _loadNotifications();
    _startListeningToNotifications();
    _isInitialized = true;
    notifyListeners();
  }

  // Load stored notifications
  Future<void> _loadNotifications() async {
    _notifications = await _notificationService.getNotifications();
    notifyListeners();
  }

  // Start listening to notification stream
  void _startListeningToNotifications() {
    _subscription = _notificationService.notificationsStream.listen((notification) {
      if (notification.isRemoved) {
        // If notification is removed, update existing notifications
        _notifications = _notifications.map((n) {
          if (n.packageName == notification.packageName && !n.isRemoved) {
            return n.copyWith(isRemoved: true);
          }
          return n;
        }).toList();
      } else {
        // Add new notification
        _notifications.insert(0, notification);
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

  // Get notifications grouped by app
  Map<String, List<AppNotification>> getNotificationsByApp() {
    final groupedNotifications = <String, List<AppNotification>>{};
    
    for (final notification in _notifications) {
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

  @override
  void dispose() {
    _subscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}