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
  final String _excludedAppsKey = 'excludedApps'; // Key for SharedPreferences

  static final MethodChannel _notificationChannel = MethodChannel(
    'notification_capture',
  );

  // Initialize notification service
  Future<void> initialize() async {
    debugPrint('NotificationService: Initializing...');
    await _loadExcludedApps(); // Load excluded apps on initialization
    debugPrint(
      'NotificationService: Initialized. Excluded apps loaded: $_excludedApps',
    );
  }

  // Start listening to platform notifications
  Future<void> startListening() async {
    if (!_isListening) {
      debugPrint('NotificationService: Starting listening...');
      try {
        final bool? success = await _notificationChannel.invokeMethod(
          'startListening',
        );
        if (success == true) {
          _isListening = true;
          debugPrint('NotificationService: Listening started.');
        } else {
          debugPrint(
            'NotificationService: Failed to start listening: Method returned false.',
          );
        }
      } on PlatformException catch (e) {
        debugPrint(
          'NotificationService: Failed to start listening: ${e.message}',
        );
      }
      _notificationChannel.setMethodCallHandler(_handleMethodCall);
    }
  }

  // Stop listening to platform notifications
  Future<void> stopListening() async {
    if (_isListening) {
      debugPrint('NotificationService: Stopping listening...');
      try {
        final bool? success = await _notificationChannel.invokeMethod(
          'stopListening',
        );
        if (success == true) {
          _isListening = false;
          debugPrint('NotificationService: Listening stopped.');
        } else {
          debugPrint(
            'NotificationService: Failed to stop listening: Method returned false.',
          );
        }
      } on PlatformException catch (e) {
        debugPrint(
          'NotificationService: Failed to stop listening: ${e.message}',
        );
      }
      _notificationChannel.setMethodCallHandler(null);
    }
  }

  // Handle method calls from the platform side
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint('NotificationService: Received method call: ${call.method}');
    switch (call.method) {
      case 'onNotificationReceived':
        try {
          final Map<dynamic, dynamic> notificationData =
              Map<dynamic, dynamic>.from(call.arguments);
          final AppNotification notification = AppNotification.fromMap(
            Map<String, dynamic>.from(notificationData),
          );

          debugPrint(
            'NotificationService: Received notification: ${notification.title} from ${notification.packageName}',
          );

          // Filter out excluded apps
          if (!_excludedApps.contains(notification.packageName)) {
            _notificationsStreamController.add(notification);
          } else {
            debugPrint(
              'NotificationService: Notification from excluded app ${notification.packageName} ignored.',
            );
          }
        } catch (e) {
          debugPrint('NotificationService: Error handling notification: $e');
        }
        break;
      case 'onNotificationRemoved':
        try {
          final Map<dynamic, dynamic> notificationData =
              Map<dynamic, dynamic>.from(call.arguments);
          final AppNotification notification = AppNotification.fromMap(
            Map<String, dynamic>.from(notificationData),
          );
          // Assuming the platform sends the full notification data including ID
          debugPrint(
            'NotificationService: Received notification removed: ${notification.id} from ${notification.packageName}',
          );
          // Create a copy with isRemoved set to true
          final removedNotification = notification.copyWith(isRemoved: true);
          _notificationsStreamController.add(removedNotification);
        } catch (e) {
          debugPrint('NotificationService: Error handling removal: $e');
        }
        break;
      default:
        debugPrint(
          'NotificationService: Ignoring unknown method call: ${call.method}',
        );
        // Should return something for unhandled calls
        return Future.value();
    }
  }

  // Request notification listening permission (Platform level)
  Future<bool> requestPermission() async {
    debugPrint('NotificationService: Requesting permission...');
    // Check if already granted first
    final isGranted = await isPermissionGranted();
    if (isGranted) {
      debugPrint('NotificationService: Permission already granted.');
      return true;
    }

    try {
      final bool? granted = await _notificationChannel.invokeMethod(
        'requestPermission',
      );
      debugPrint('NotificationService: Permission request result: $granted');
      return granted ?? false;
    } on PlatformException catch (e) {
      debugPrint(
        'NotificationService: Failed to request permission: ${e.message}',
      );
      return false;
    }
  }

  // Check if notification listening permission is granted (Platform level)
  Future<bool> isPermissionGranted() async {
    try {
      final bool? granted = await _notificationChannel.invokeMethod(
        'isPermissionGranted',
      );
      return granted ?? false;
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to check permission: ${e.toString()}',
      );
      return false;
    }
  }

  // Excluded apps management using SharedPreferences
  Future<void> _loadExcludedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _excludedApps = prefs.getStringList(_excludedAppsKey)?.toSet() ?? {};
    } catch (e) {
      debugPrint('NotificationService: Error loading excluded apps: $e');
    }
  }

  Future<void> _saveExcludedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_excludedAppsKey, _excludedApps.toList());
    } catch (e) {
      debugPrint('NotificationService: Error saving excluded apps: $e');
    }
  }

  Future<Set<String>> getExcludedApps() async {
    await _loadExcludedApps(); // Ensure latest are loaded
    return _excludedApps;
  }

  Future<bool> isAppExcluded(String packageName) async {
    await _loadExcludedApps(); // Ensure latest are loaded
    return _excludedApps.contains(packageName);
  }

  Future<void> excludeApp(String packageName) async {
    if (_excludedApps.add(packageName)) {
      // Add returns true if the element was not already in the set
      await _saveExcludedApps();
      debugPrint('NotificationService: Excluded app: $packageName');
    }
  }

  Future<void> includeApp(String packageName) async {
    if (_excludedApps.remove(packageName)) {
      // Remove returns true if the element was in the set
      await _saveExcludedApps();
      debugPrint('NotificationService: Included app: $packageName');
    }
  }

  // Send a test notification (Platform level)
  Future<void> sendTestNotification({
    String title = 'Test Notification',
    String body = 'This is a test notification',
  }) async {
    try {
      await _notificationChannel.invokeMethod(
        'sendTestNotification',
        <String, dynamic>{'title': title, 'body': body},
      );
      debugPrint('NotificationService: Test notification sent.');
    } on PlatformException catch (e) {
      debugPrint(
        'NotificationService: Failed to send test notification: ${e.message}',
      );
    }
  }

  // No longer needed as persistence is handled by Provider/Drift
  // Future<void> _saveNotification(AppNotification notification) async { ... }
  // Future<List<AppNotification>> getNotifications() async { ... }
  // Future<void> clearAllStoredNotifications() async { ... }
  // Future<void> clearAppNotifications(String packageName) async { ... }
  // Future<void> removeNotification(String id) async { ... }

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

  // Dispose the stream controller
  void dispose() {
    _notificationsStreamController.close();
    debugPrint('NotificationService: Disposed.');
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
