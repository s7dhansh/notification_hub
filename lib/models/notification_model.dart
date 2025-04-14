// No imports needed for this model file

class AppNotification {
  final String id;
  final String packageName;
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? iconData; // Can be a Base64 string representing the app icon
  final bool isRemoved;

  AppNotification({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.iconData,
    this.isRemoved = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? 'Unknown App',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
      iconData: map['iconData'],
      isRemoved: map['isRemoved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'iconData': iconData,
      'isRemoved': isRemoved,
    };
  }

  AppNotification copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? title,
    String? body,
    DateTime? timestamp,
    String? iconData,
    bool? isRemoved,
  }) {
    return AppNotification(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      iconData: iconData ?? this.iconData,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }
}