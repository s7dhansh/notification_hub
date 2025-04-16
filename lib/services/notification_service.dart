import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

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
    await requestPermission();

    // Start listening if permission is granted
    if (await Permission.notification.isGranted) {
      await startListening();
    }
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Start listening to notifications
  Future<void> startListening() async {
    if (_isListening) return;

    _isListening = true;

    // Check if mock notifications should be used
    if (await getUseMockNotifications()) {
      _startMockNotifications();
    }

    // Load existing notifications
    final notifications = await getNotifications();
    for (final notification in notifications) {
      _notificationsStreamController.add(notification);
    }
  }

  // Stop listening to notifications
  Future<void> stopListening() async {
    _isListening = false;
    _mockTimer?.cancel();
    _mockTimer = null;
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

  // Dispose resources
  void dispose() {
    _notificationsStreamController.close();
    stopListening();
  }
}

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
