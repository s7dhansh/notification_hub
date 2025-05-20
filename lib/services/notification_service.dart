import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'icon_cache_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final _notificationsStreamController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationsStream =>
      _notificationsStreamController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  // Set of excluded package names
  Set<String> _excludedApps = {};

  static final MethodChannel _notificationChannel = MethodChannel(
    'notification_capture',
  );

  // Initialize notification service
  Future<void> initialize() async {
    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotificationsPlugin.initialize(initializationSettings);

    // Load excluded apps
    await getExcludedApps();

    // Request notification permission
    bool hasPermission = await requestPermission();

    // Start listening if permission is granted
    if (hasPermission) {
      await startListening();
    }

    initNativeNotificationListener();
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    // Request notification permission for Android 13+
    final notificationPermissionStatus =
        await Permission.notification.request();

    return notificationPermissionStatus.isGranted;
  }

  // Start listening to notifications
  Future<void> startListening() async {
    if (_isListening) {
      return; // Already listening or an attempt is in progress.
    }

    _isListening = true; // Set flag to indicate an attempt to start.

    try {
      bool hasPermission = await requestPermission();

      if (hasPermission) {
        // Listening to NotificationListenerService.notificationsStream handles service startup implicitly.
        // _isListening remains true, indicating service is active or start was successful.
      } else {
        // Permission was not granted, service cannot start.
        _isListening = false; // Reset flag.
        // Optionally, log this situation or inform the user through other means.
        // print("Notification listener permission not granted. Service not started.");
      }
    } catch (e, s) {
      // An error occurred during the startup process.
      _isListening = false; // Reset flag as startup failed.
      // Log the error for debugging. Consider using a proper logging framework.
      debugPrint('Failed to start notification listener: $e\nStackTrace: $s');
      // Consider rethrowing if the caller needs to handle failures.
      // rethrow;
    }
  }

  // Stop listening to notifications
  Future<void> stopListening() async {
    _isListening = false;

    // Stop the notification listener service
    // Unsubscribing from NotificationListenerService.notificationsStream (if a subscription is stored)
    // or simply setting _isListening to false and cancelling timers should suffice.
    // The package does not offer an explicit stopService method.
    // The service lifecycle is managed by the Android system based on bound clients (the stream listener).
    // If no one is listening, the service can be stopped by the system.
  }

  // Save notification to shared preferences
  Future<void> _saveNotification(AppNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      final notifications =
          notificationsJson
              .map((jsonStr) => AppNotification.fromMap(json.decode(jsonStr)))
              .toList();

      // Add new notification (or update if it exists by ID)
      final existingIndex = notifications.indexWhere(
        (n) => n.id == notification.id,
      );
      if (existingIndex >= 0) {
        notifications[existingIndex] = notification;
      } else {
        notifications.add(notification);
      }

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Limit to 100 notifications to avoid storage issues
      final limitedNotifications = notifications.take(100).toList();

      // Save back to shared preferences
      final updatedJsonList =
          limitedNotifications
              .map((notification) => json.encode(notification.toMap()))
              .toList();
      await prefs.setStringList('notifications', updatedJsonList);
    } catch (e) {
      // Log error but don't crash
    }
  }

  // Get all stored notifications
  Future<List<AppNotification>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      debugPrint(
        'Loaded ${notificationsJson.length} notifications from storage',
      );
      final notifications =
          notificationsJson
              .map((jsonStr) => AppNotification.fromMap(json.decode(jsonStr)))
              .toList();

      // Sort by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    } catch (e) {
      return [];
    }
  }

  // Clear all stored notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notifications');
    } catch (e) {
      // Log error but don't crash
    }
  }

  Future<void> clearAppNotifications(String packageName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      final notifications =
          notificationsJson
              .map((jsonStr) => AppNotification.fromMap(json.decode(jsonStr)))
              .where((n) => n.packageName != packageName)
              .toList();

      final updatedJsonList =
          notifications
              .map((notification) => json.encode(notification.toMap()))
              .toList();
      await prefs.setStringList('notifications', updatedJsonList);
    } catch (e) {
      // Log error but don't crash
    }
  }

  Future<void> removeNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      final notifications =
          notificationsJson
              .map((jsonStr) => AppNotification.fromMap(json.decode(jsonStr)))
              .where((n) => n.id != id)
              .toList();

      final updatedJsonList =
          notifications
              .map((notification) => json.encode(notification.toMap()))
              .toList();
      await prefs.setStringList('notifications', updatedJsonList);
    } catch (e) {
      // Log error but don't crash
    }
  }

  // Manage excluded apps
  Future<Set<String>> getExcludedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final excludedList = prefs.getStringList('excludedApps') ?? [];
      return _excludedApps = excludedList.toSet();
    } catch (e) {
      return _excludedApps;
    }
  }

  Future<bool> isAppExcluded(String packageName) async {
    await getExcludedApps();
    return _excludedApps.contains(packageName);
  }

  Future<void> excludeApp(String packageName) async {
    try {
      await getExcludedApps();
      _excludedApps.add(packageName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('excludedApps', _excludedApps.toList());
    } catch (e) {
      // Log error but don't crash
    }
  }

  Future<void> includeApp(String packageName) async {
    try {
      await getExcludedApps();
      _excludedApps.remove(packageName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('excludedApps', _excludedApps.toList());
    } catch (e) {
      // Log error but don't crash
    }
  }

  // Send a test notification
  Future<void> sendTestNotification({
    String title = 'Test Notification',
    String body = 'This is a test notification',
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Send the remove system tray notification setting to the native side
  Future<void> updateRemoveSystemTraySetting(bool remove) async {
    try {
      await _notificationChannel.invokeMethod('updateRemoveSystemTraySetting', {
        'remove': remove,
      });
      debugPrint(
        'Sent removeSystemTrayNotification setting to native: $remove',
      );
    } on PlatformException catch (e) {
      debugPrint(
        'Failed to send removeSystemTrayNotification setting: ${e.message}',
      );
    }
  }

  // Dispose resources
  void dispose() {
    _notificationsStreamController.close();
    stopListening();
  }

  void initNativeNotificationListener() {
    debugPrint('Setting up native notification listener channel');
    _notificationChannel.setMethodCallHandler((call) async {
      debugPrint(
        'Received method call from native: ${call.method} with arguments: ${call.arguments} (type: ${call.arguments.runtimeType})',
      );

      if (call.method == 'onNotificationPosted') {
        try {
          debugPrint('Captured notification: ${call.arguments}');
          final args = call.arguments as Map;

          final packageName = args['packageName']?.toString() ?? '';
          final appName = args['appName']?.toString() ?? packageName;
          final title = args['title']?.toString() ?? '';
          final body = args['body']?.toString() ?? '';
          final iconData = args['iconData']?.toString();

          await getExcludedApps(); // Ensure _excludedApps is up to date
          if (_excludedApps.contains(packageName)) {
            debugPrint('Notification from excluded app $packageName ignored.');
            return;
          }

          // Cache the icon if available
          if (iconData != null && iconData.isNotEmpty) {
            await IconCacheService().cacheIcon(packageName, iconData);
          }

          final appNotification = AppNotification(
            id: '${packageName}_${DateTime.now().millisecondsSinceEpoch}',
            packageName: packageName,
            appName: appName,
            title: title,
            body: body,
            timestamp: DateTime.now(),
            iconData: iconData,
            isRemoved: false,
          );

          await _saveNotification(appNotification);
          _notificationsStreamController.add(appNotification);
        } catch (e, stackTrace) {
          debugPrint('Error handling onNotificationPosted: $e\n$stackTrace');
        }
      }
    });
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
