import 'dart:async' show StreamSubscription;
import 'package:flutter/foundation.dart'
    show
        ChangeNotifier,
        debugPrint; // Already uses show, no change needed but included for completeness of the block
import '../models/notification_model.dart' show AppNotification;
import '../services/notification_service.dart' show NotificationService;
import '../services/icon_cache_service.dart' show IconCacheService;
import '../database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' show Value;
import 'package:collection/collection.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final _iconCacheService = IconCacheService();
  List<AppNotification> _notifications = [];
  List<AppNotification> _notificationHistory = [];
  final AppDatabase _db = AppDatabase();
  int _historyDays = 7;
  bool _isInitialized = false;
  StreamSubscription<AppNotification>? _subscription;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get notificationHistory => _notificationHistory;
  bool get isListening => _notificationService.isListening;
  bool get isInitialized => _isInitialized;

  bool _isLoadingMore = false;
  bool _hasMoreData = true; // Assuming initially there's more data to load

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;

  // Constructor
  NotificationProvider() {
    _initialize();
  }

  // Initialize the provider
  Future<void> _initialize() async {
    debugPrint('NotificationProvider: Initializing...');
    final prefs = await SharedPreferences.getInstance();
    _historyDays = prefs.getInt('historyDays') ?? 7;
    await _notificationService.initialize();
    await loadNotifications();
    await loadHistory();
    _startListeningToNotifications();
    _isInitialized = true;
    debugPrint(
      'NotificationProvider: Initialization complete. isInitialized: $_isInitialized',
    );
    notifyListeners();
  }

  // Make method public
  Future<void> loadNotifications() async {
    debugPrint('NotificationProvider: Loading notifications from database...');
    final dbNotifs = await _db.getAllNotifications();
    _notifications = dbNotifs.map(_fromDbNotification).toList();
    debugPrint(
      'NotificationProvider: Loaded ${dbNotifs.length} notifications from database.',
    );
    notifyListeners();
  }

  Future<void> loadHistory() async {
    debugPrint('NotificationProvider: Loading history from database...');
    final cutoff = DateTime.now().subtract(Duration(days: _historyDays));
    // Remove old history
    await _db.deleteHistoryOlderThan(cutoff);
    _notificationHistory =
        (await _db.getAllHistory())
            .where((h) => h.timestamp.isAfter(cutoff))
            .map(_fromDbNotificationHistory)
            .toList();
    debugPrint(
      'NotificationProvider: Loaded ${_notificationHistory.length} history entries from database.',
    );
    notifyListeners();
  }

  // Start listening to notification stream
  void _startListeningToNotifications() {
    debugPrint(
      'NotificationProvider: Starting to listen to notification stream...',
    );
    _subscription?.cancel();
    _subscription = _notificationService.notificationsStream.listen((
      notification,
    ) async {
      debugPrint(
        'Provider received notification: ${notification.title} from ${notification.packageName}',
      );
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
        // Also move the removed notification to history in the database
        final removedNotif = _notifications.firstWhereOrNull(
          (n) => n.packageName == notification.packageName && n.isRemoved,
        );
        if (removedNotif != null) {
          await addToHistory(removedNotif);
          debugPrint(
            'NotificationProvider: Deleting notification ${removedNotif.id} from active database...',
          );
          await _db.deleteNotification(
            removedNotif.id,
          ); // Delete from active notifications
          debugPrint(
            'NotificationProvider: Notification ${removedNotif.id} deleted from active database.',
          );
        }
      } else {
        // Deduplicate by ID
        if (!_notifications.any((n) => n.id == notification.id)) {
          _notifications.insert(0, notification);
          debugPrint(
            'NotificationProvider: Inserting new notification ${notification.id} into database...',
          );
          // Save the new notification to the database
          await _db.insertNotification(_toDbNotification(notification));
          debugPrint(
            'NotificationProvider: Notification ${notification.id} inserted into database.',
          );
        }
      }
      debugPrint(
        'Provider notifications list now has ${_notifications.length} items',
      );
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
    debugPrint('NotificationProvider: Clearing all notifications...');
    // Add all current notifications to history in the database
    for (final notification in _notifications) {
      await addToHistory(notification);
    }

    // Clear all notifications from the database
    debugPrint(
      'NotificationProvider: Clearing all notifications from database...',
    );
    await _db.clearNotifications();
    debugPrint(
      'NotificationProvider: All notifications cleared from database.',
    );

    // Clear all notifications from the in-memory list
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
    // final allNotifications = await _notificationService.getNotifications(); // Remove this line
    // Use the database to get paginated notifications instead
    final newNotifications = await _db.getPaginatedNotifications(
      page * pageSize, // Offset
      pageSize, // Limit
    );
    return newNotifications
        .map(_fromDbNotification)
        .toList(); // Map DB results to AppNotification
  }

  // Add method to clear notifications for a specific app
  Future<void> clearAppNotifications(String packageName) async {
    debugPrint(
      'NotificationProvider: Clearing notifications for app: $packageName...',
    );
    // Find all notifications for this app
    final appNotifications =
        _notifications.where((n) => n.packageName == packageName).toList();

    // Add all to history
    for (final notification in appNotifications) {
      await addToHistory(notification);
      // Delete from active notifications in the database
      debugPrint(
        'NotificationProvider: Deleting notification ${notification.id} for app $packageName from active database...',
      );
      await _db.deleteNotification(notification.id);
      debugPrint(
        'NotificationProvider: Notification ${notification.id} for app $packageName deleted from active database.',
      );
    }

    // Remove from active notifications
    _notifications.removeWhere((n) => n.packageName == packageName);
    notifyListeners();
  }

  // Add method to remove a single notification
  Future<void> removeNotification(String id) async {
    debugPrint('NotificationProvider: Removing notification with id: $id...');
    // Find the notification before removing it
    final notification = _notifications.firstWhere(
      (n) => n.id == id,
      orElse: () => throw Exception('Notification not found'),
    );

    // Add to history before removing
    await addToHistory(notification);

    // Remove from active notifications
    _notifications.removeWhere((n) => n.id == id);
    // Delete from active notifications in the database
    debugPrint(
      'NotificationProvider: Deleting notification $id from active database...',
    );
    await _db.deleteNotification(id);
    debugPrint(
      'NotificationProvider: Notification $id deleted from active database.',
    );
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

  void setLoadingMore(bool value) {
    _isLoadingMore = value;
    notifyListeners();
  }

  void setHasMoreData(bool value) {
    _hasMoreData = value;
    notifyListeners();
  }

  // Add load more notifications method
  Future<bool> loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreData) return false;

    _isLoadingMore = true;
    notifyListeners();

    final currentLength = _notifications.length;
    final pageSize = 20;

    final newNotifications = await _db.getPaginatedNotifications(
      currentLength, // Start from the current number of notifications
      pageSize,
    );

    _notifications.addAll(newNotifications.map(_fromDbNotification));

    _isLoadingMore = false;
    _hasMoreData =
        newNotifications.length ==
        pageSize; // Assume more data if we got a full page
    notifyListeners();

    return _hasMoreData;
  }

  // Send a test notification
  Future<void> sendTestNotification({
    String title = 'Test Notification',
    String body = 'This is a test notification',
  }) async {
    await _notificationService.sendTestNotification(title: title, body: body);
  }

  // Add to notification history
  Future<void> addToHistory(AppNotification notification) async {
    debugPrint(
      'NotificationProvider: Adding notification ${notification.id} to history database...',
    );
    await _db.insertHistory(_toDbHistory(notification));
    debugPrint(
      'NotificationProvider: Notification ${notification.id} added to history database.',
    );
  }

  // Restore a notification from history (undo)
  Future<void> restoreNotification(AppNotification notification) async {
    debugPrint(
      'NotificationProvider: Restoring notification ${notification.id} from history...',
    );
    await _db.insertNotification(
      NotificationsCompanion(
        id: Value(notification.id),
        packageName: Value(notification.packageName),
        appName: Value(notification.appName),
        title: Value(notification.title),
        body: Value(notification.body),
        timestamp: Value(notification.timestamp),
        iconData: Value(notification.iconData),
        isRemoved: Value(notification.isRemoved),
      ),
    );
    await _db.deleteHistory(notification.id);
    debugPrint(
      'NotificationProvider: Notification ${notification.id} deleted from history database.',
    );
    await loadNotifications();
    await loadHistory();
    debugPrint(
      'NotificationProvider: Notification ${notification.id} restored and lists reloaded.',
    );
  }

  // Helper to convert DB row to AppNotification
  AppNotification _fromDbNotification(Notification n) => AppNotification(
    id: n.id,
    packageName: n.packageName,
    appName: n.appName,
    title: n.title,
    body: n.body,
    timestamp: n.timestamp,
    iconData: n.iconData,
    isRemoved: n.isRemoved,
  );
  AppNotification _fromDbNotificationHistory(NotificationHistoryData n) =>
      AppNotification(
        id: n.id,
        packageName: n.packageName,
        appName: n.appName,
        title: n.title,
        body: n.body,
        timestamp: n.timestamp,
        iconData: n.iconData,
        isRemoved: n.isRemoved,
      );

  // Helper to convert AppNotification to NotificationsCompanion
  NotificationsCompanion _toDbNotification(AppNotification notification) {
    return NotificationsCompanion(
      id: Value(notification.id),
      packageName: Value(notification.packageName),
      appName: Value(notification.appName),
      title: Value(notification.title),
      body: Value(notification.body),
      timestamp: Value(notification.timestamp),
      iconData: Value(notification.iconData),
      isRemoved: Value(notification.isRemoved),
    );
  }

  // Helper to convert AppNotification to NotificationHistoryCompanion
  NotificationHistoryCompanion _toDbHistory(AppNotification notification) {
    return NotificationHistoryCompanion(
      id: Value(notification.id),
      packageName: Value(notification.packageName),
      appName: Value(notification.appName),
      title: Value(notification.title),
      body: Value(notification.body),
      timestamp: Value(notification.timestamp),
      iconData: Value(notification.iconData),
      isRemoved: Value(notification.isRemoved),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notificationService.dispose();
    super.dispose();
  }
}
