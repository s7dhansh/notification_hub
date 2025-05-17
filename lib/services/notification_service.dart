import 'dart:async' show Future, Stream, StreamController, Timer;
import 'dart:convert' show base64Encode, json;
import 'dart:math' as math show Random;

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    show
        AndroidInitializationSettings,
        DarwinInitializationSettings,
        FlutterLocalNotificationsPlugin,
        InitializationSettings,
        AndroidNotificationDetails,
        DarwinNotificationDetails,
        NotificationDetails,
        Importance,
        Priority;
import 'package:notification_listener_service/notification_event.dart'
    show ServiceNotificationEvent;
import 'package:notification_listener_service/notification_listener_service.dart'
    show NotificationListenerService;
import 'package:permission_handler/permission_handler.dart'
    show Permission, PermissionActions, PermissionStatusGetters;
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:installed_apps/app_info.dart' show AppInfo;
import 'package:installed_apps/installed_apps.dart' show InstalledApps;
import 'package:flutter/services.dart';

import '../models/notification_model.dart' show AppNotification;

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _mockTimer;
  final _random = math.Random();

  final _notificationsStreamController =
      StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationsStream =>
      _notificationsStreamController.stream;

  bool _isListening = false;
  bool get isListening => _isListening;

  // Set of excluded package names
  Set<String> _excludedApps = {};

  // List of apps that might send notifications
  final List<String> _apps = [
    'com.whatsapp',
    'com.facebook.katana',
    'com.instagram.android',
    'com.twitter.android',
    'com.google.android.gm',
    'com.slack',
    'com.discord',
    'com.spotify.music',
  ];

  bool _useMockNotifications = false;

  static const MethodChannel _notificationChannel = MethodChannel(
    'notification_capture',
  );

  Future<bool> getUseMockNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    _useMockNotifications = prefs.getBool('useMockNotifications') ?? false;
    return _useMockNotifications;
  }

  Future<void> setUseMockNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useMockNotifications', value);
    _useMockNotifications = value;

    if (!value) {
      _mockTimer?.cancel();
      _mockTimer = null;
    } else if (_isListening) {
      _startMockNotifications();
    }
  }

  void _startMockNotifications() {
    if (_useMockNotifications && _isListening) {
      _mockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _generateMockNotification();
      });
    }
  }

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

    // Initialize notification listener service
    await _initializeNotificationListener();

    // Start listening if permission is granted
    if (hasPermission) {
      await startListening();
    }

    initNativeNotificationListener();
  }

  // Initialize notification listener service
  Future<void> _initializeNotificationListener() async {
    try {
      // Listen for notification events
      NotificationListenerService.notificationsStream.listen(
        _onNotificationReceived,
      );
      // The service starts implicitly when the stream is listened to
      // and permission is granted. Explicit startService call is handled in startListening.
    } catch (e) {
      print('Error initializing notification listener: $e');
    }
  }

  // Handle received notifications from the system
  Future<void> _onNotificationReceived(ServiceNotificationEvent event) async {
    // Skip if this app is excluded
    if (await isAppExcluded(event.packageName ?? '')) return;

    // Get app info
    String appName = 'Unknown App';
    String? iconData;

    try {
      // Try to get app info
      List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);
      AppInfo? appInfo = apps.firstWhere(
        (app) => app.packageName == event.packageName,
        orElse: () => throw StateError('App not found'),
      );

      appName = appInfo.name;
      // Convert app icon to base64 if available
      if (appInfo.icon != null) {
        iconData = base64Encode(appInfo.icon!);
      }
    } catch (e) {
      // Fallback to package name parsing if app info fails
      appName = _getAppNameFromPackage(event.packageName ?? '');
    }

    // Create notification object
    final appNotification = AppNotification(
      id: '${event.packageName}_${DateTime.now().millisecondsSinceEpoch}',
      packageName: event.packageName ?? '',
      appName: appName,
      title: event.title ?? '',
      body: event.content ?? '',
      timestamp: DateTime.now(),
      iconData: iconData,
      isRemoved: false,
    );

    // Save notification to storage
    await _saveNotification(appNotification);

    // Broadcast notification to listeners
    _notificationsStreamController.add(appNotification);
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    // Request notification permission for Android 13+
    final notificationPermissionStatus =
        await Permission.notification.request();

    // Then, handle notification listener permission
    bool hasListenerPermission =
        await NotificationListenerService.isPermissionGranted();
    if (!hasListenerPermission) {
      hasListenerPermission =
          await NotificationListenerService.requestPermission();
    }

    return notificationPermissionStatus.isGranted && hasListenerPermission;
  }

  // Start listening to notifications
  Future<void> startListening() async {
    if (_isListening) {
      return; // Already listening or an attempt is in progress.
    }

    _isListening = true; // Set flag to indicate an attempt to start.

    try {
      bool hasPermission =
          await NotificationListenerService.isPermissionGranted();

      if (!hasPermission) {
        await requestPermission(); // Request permission.
        hasPermission =
            await NotificationListenerService.isPermissionGranted(); // Re-check after request.
      }

      if (hasPermission) {
        // Listening to NotificationListenerService.notificationsStream handles service startup implicitly.
        // _isListening remains true, indicating service is active or start was successful.

        // Continue with other setup tasks if service started.
        if (await getUseMockNotifications()) {
          _startMockNotifications();
        }
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
      print('Failed to start notification listener: $e\nStackTrace: $s');
      // Consider rethrowing if the caller needs to handle failures.
      // rethrow;
    }
  }

  // Stop listening to notifications
  Future<void> stopListening() async {
    _isListening = false;
    _mockTimer?.cancel();
    _mockTimer = null;

    // Stop the notification listener service
    // Unsubscribing from NotificationListenerService.notificationsStream (if a subscription is stored)
    // or simply setting _isListening to false and cancelling timers should suffice.
    // The package does not offer an explicit stopService method.
    // The service lifecycle is managed by the Android system based on bound clients (the stream listener).
    // If no one is listening, the service can be stopped by the system.
  }

  // Generate a mock notification for testing
  void _generateMockNotification() async {
    if (!_isListening) return;

    // Randomly select an app
    final appIndex = _random.nextInt(_apps.length);
    final packageName = _apps[appIndex];

    // Skip if this app is excluded
    if (await isAppExcluded(packageName)) return;

    final appName = _getAppNameFromPackage(packageName);

    // Create mock notification content
    String title;
    String body;

    switch (appName.toLowerCase()) {
      case 'whatsapp':
        title = 'New message from ${_getRandomName()}';
        body = 'Hey, how are you doing today?';
        break;
      case 'facebook':
        title = '${_getRandomName()} mentioned you in a comment';
        body = 'Check out this new post';
        break;
      case 'instagram':
        title = '${_getRandomName()} liked your photo';
        body = 'Your recent post got 25 likes';
        break;
      case 'twitter':
        title = 'New activity on your tweet';
        body = '${_getRandomName()} and others retweeted your post';
        break;
      case 'gmail':
        title = 'New email from ${_getRandomName()}';
        body = 'Project update: Latest changes ready for review';
        break;
      default:
        title = 'New notification from $appName';
        body = 'You have a new update to check';
    }

    final appNotification = AppNotification(
      id: '${packageName}_${DateTime.now().millisecondsSinceEpoch}',
      packageName: packageName,
      appName: appName,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      iconData: null,
      isRemoved: false,
    );

    // Save notification to storage
    _saveNotification(appNotification);

    // Broadcast notification to listeners
    _notificationsStreamController.add(appNotification);
  }

  // Get a random name for mock notifications
  String _getRandomName() {
    final names = [
      'Alice',
      'Bob',
      'Charlie',
      'David',
      'Emma',
      'Frank',
      'Grace',
      'Henry',
    ];
    return names[_random.nextInt(names.length)];
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

  // Get readable app name from package name
  String _getAppNameFromPackage(String packageName) {
    // In a real app, you would use package info to get the app name
    // This is a simple implementation
    final parts = packageName.split('.');
    if (parts.isEmpty) return 'Unknown';
    return parts.last.capitalize();
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
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
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

  // Dispose resources
  void dispose() {
    _notificationsStreamController.close();
    stopListening();
  }

  void initNativeNotificationListener() {
    _notificationChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationPosted') {
        // Handle the captured notification here
        // Example: print or process notification data
        print('Captured notification: \\${call.arguments}');
        // You can parse call.arguments and add to your notification stream if needed
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
