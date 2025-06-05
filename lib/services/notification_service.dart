import 'dart:async';

import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter/services.dart'
    show MethodChannel, PlatformException, MethodCall;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  final _notificationsStreamController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationsStream =>
      _notificationsStreamController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  // Set of excluded package names
  Set<String> _excludedApps = {};
  final String _excludedAppsKey = 'excludedApps'; // Key for SharedPreferences

  // Track programmatic removals
  final Set<String> _programmaticallyRemovedKeys = {};

  // Default excluded app package names (WhatsApp, SMS, call apps)
  static const List<String> _defaultExcludedApps = [
    'com.whatsapp', // WhatsApp
    'com.google.android.apps.messaging', // Google Messages
    'com.android.mms', // Default SMS/MMS
    'com.android.dialer', // Default Phone/Dialer
    'com.truecaller', // Truecaller (calls/SMS)
  ];

  static final MethodChannel _notificationChannel = MethodChannel(
    'notification_capture',
  );

  bool _removeSystemTrayNotification = true;
  bool get removeSystemTrayNotification => _removeSystemTrayNotification;

  // New setting: remove notification from app if source app removes it
  static const String _removeIfSourceAppRemovesKey = 'removeIfSourceAppRemoves';
  bool _removeIfSourceAppRemoves = false;
  bool get removeIfSourceAppRemoves => _removeIfSourceAppRemoves;

  Future<void> setRemoveIfSourceAppRemoves(bool value) async {
    _removeIfSourceAppRemoves = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_removeIfSourceAppRemovesKey, value);
  }

  // Initialize notification service
  Future<void> initialize() async {
    debugPrint('NotificationService: Initializing...');
    await _loadExcludedApps(); // Load excluded apps on initialization
    // Load removeSystemTrayNotification setting from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _removeSystemTrayNotification =
        prefs.getBool('removeSystemTrayNotification') ?? true;
    _removeIfSourceAppRemoves =
        prefs.getBool(_removeIfSourceAppRemovesKey) ?? false;
    // Sync the setting to the Android service on app start
    await updateRemoveSystemTraySetting(_removeSystemTrayNotification);
    debugPrint(
      'NotificationService: Initialized. Excluded apps loaded: $_excludedApps',
    );
    await _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(initializationSettings);
    _localNotificationsInitialized = true;
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
          if (notificationData['programmatic'] == true) {
            debugPrint(
              'NotificationService: Ignoring programmatic removal for key: \\${notificationData['key']}',
            );
            return;
          }
          final AppNotification notification = AppNotification.fromMap(
            Map<String, dynamic>.from(notificationData),
          );
          debugPrint(
            'NotificationService: Received notification removed: \\${notification.id} from \\${notification.packageName}',
          );
          // Create a copy with isRemoved set to true
          final removedNotification = notification.copyWith(isRemoved: true);
          _notificationsStreamController.add(removedNotification);
        } catch (e) {
          debugPrint('NotificationService: Error handling removal: \\$e');
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
      final loaded = prefs.getStringList(_excludedAppsKey)?.toSet() ?? {};
      // If exclusion list is empty, populate with defaults
      if (loaded.isEmpty) {
        _excludedApps = _defaultExcludedApps.toSet();
        await prefs.setStringList(_excludedAppsKey, _defaultExcludedApps);
        debugPrint(
          'NotificationService: Set default excluded apps: $_excludedApps',
        );
      } else {
        _excludedApps = loaded;
      }
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
      if (remove) {
        // Remove all notifications from system tray, but keep them in the app
        await clearAllNotificationsFromSystemTrayOnly();
      }
      _removeSystemTrayNotification = remove;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('removeSystemTrayNotification', remove);
    } on PlatformException catch (e) {
      debugPrint(
        'Failed to send removeSystemTrayNotification setting: ${e.message}',
      );
    }
  }

  /// Removes all notifications from the system tray, but keeps them in the app list
  Future<void> clearAllNotificationsFromSystemTrayOnly() async {
    try {
      // Instead, just call the platform to clear all notifications
      await _notificationChannel.invokeMethod('clearAllNotifications');
      debugPrint(
        'NotificationService: Cleared all notifications from system tray only.',
      );
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to clear all notifications from system tray: $e',
      );
    }
  }

  // Dispose the stream controller
  void dispose() {
    _notificationsStreamController.close();
    debugPrint('NotificationService: Disposed.');
  }

  Future<void> clearAllNotifications() async {
    try {
      await _notificationChannel.invokeMethod('clearAllNotifications');
    } catch (e) {
      debugPrint(
        'NotificationService: Failed to clear all notifications: \\${e.toString()}',
      );
    }
  }

  Future<void> removeNotificationFromSystemTray(String? key) async {
    if (key == null) return;
    try {
      _programmaticallyRemovedKeys.add(key);
      await _notificationChannel.invokeMethod('removeNotification', {
        'key': key,
      });
    } catch (e) {
      debugPrint('NotificationService: Failed to remove notification: \\$e');
    }
  }

  Future<void> showPersistentSummaryNotification({
    required int appCount,
    required int notifCount,
  }) async {
    await _initializeLocalNotifications();
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'summary_channel',
          'Notification Summary',
          channelDescription: 'Shows a persistent summary of notifications',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          onlyAlertOnce: true,
          showWhen: false,
          playSound: false,
          enableVibration: false,
          autoCancel: false,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _localNotificationsPlugin.show(
      9999, // Arbitrary id for summary notification
      'Notification Hub',
      '$appCount app${appCount == 1 ? '' : 's'} with $notifCount notification${notifCount == 1 ? '' : 's'}',
      platformChannelSpecifics,
      payload: null,
    );
  }

  Future<void> cancelPersistentSummaryNotification() async {
    await _initializeLocalNotifications();
    await _localNotificationsPlugin.cancel(9999);
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
