// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $NotificationsTable extends Notifications
    with TableInfo<$NotificationsTable, Notification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconDataMeta = const VerificationMeta(
    'iconData',
  );
  @override
  late final GeneratedColumn<String> iconData = GeneratedColumn<String>(
    'icon_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRemovedMeta = const VerificationMeta(
    'isRemoved',
  );
  @override
  late final GeneratedColumn<bool> isRemoved = GeneratedColumn<bool>(
    'is_removed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_removed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    appName,
    title,
    body,
    timestamp,
    iconData,
    isRemoved,
    key,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Notification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('icon_data')) {
      context.handle(
        _iconDataMeta,
        iconData.isAcceptableOrUnknown(data['icon_data']!, _iconDataMeta),
      );
    }
    if (data.containsKey('is_removed')) {
      context.handle(
        _isRemovedMeta,
        isRemoved.isAcceptableOrUnknown(data['is_removed']!, _isRemovedMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notification(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      packageName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}package_name'],
          )!,
      appName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}app_name'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      body:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}body'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      iconData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_data'],
      ),
      isRemoved:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_removed'],
          )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      ),
    );
  }

  @override
  $NotificationsTable createAlias(String alias) {
    return $NotificationsTable(attachedDatabase, alias);
  }
}

class Notification extends DataClass implements Insertable<Notification> {
  final String id;
  final String packageName;
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? iconData;
  final bool isRemoved;
  final String? key;
  const Notification({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.iconData,
    required this.isRemoved,
    this.key,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || iconData != null) {
      map['icon_data'] = Variable<String>(iconData);
    }
    map['is_removed'] = Variable<bool>(isRemoved);
    if (!nullToAbsent || key != null) {
      map['key'] = Variable<String>(key);
    }
    return map;
  }

  NotificationsCompanion toCompanion(bool nullToAbsent) {
    return NotificationsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      appName: Value(appName),
      title: Value(title),
      body: Value(body),
      timestamp: Value(timestamp),
      iconData:
          iconData == null && nullToAbsent
              ? const Value.absent()
              : Value(iconData),
      isRemoved: Value(isRemoved),
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
    );
  }

  factory Notification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notification(
      id: serializer.fromJson<String>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      iconData: serializer.fromJson<String?>(json['iconData']),
      isRemoved: serializer.fromJson<bool>(json['isRemoved']),
      key: serializer.fromJson<String?>(json['key']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'iconData': serializer.toJson<String?>(iconData),
      'isRemoved': serializer.toJson<bool>(isRemoved),
      'key': serializer.toJson<String?>(key),
    };
  }

  Notification copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? title,
    String? body,
    DateTime? timestamp,
    Value<String?> iconData = const Value.absent(),
    bool? isRemoved,
    Value<String?> key = const Value.absent(),
  }) => Notification(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    title: title ?? this.title,
    body: body ?? this.body,
    timestamp: timestamp ?? this.timestamp,
    iconData: iconData.present ? iconData.value : this.iconData,
    isRemoved: isRemoved ?? this.isRemoved,
    key: key.present ? key.value : this.key,
  );
  Notification copyWithCompanion(NotificationsCompanion data) {
    return Notification(
      id: data.id.present ? data.id.value : this.id,
      packageName:
          data.packageName.present ? data.packageName.value : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      iconData: data.iconData.present ? data.iconData.value : this.iconData,
      isRemoved: data.isRemoved.present ? data.isRemoved.value : this.isRemoved,
      key: data.key.present ? data.key.value : this.key,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notification(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('timestamp: $timestamp, ')
          ..write('iconData: $iconData, ')
          ..write('isRemoved: $isRemoved, ')
          ..write('key: $key')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packageName,
    appName,
    title,
    body,
    timestamp,
    iconData,
    isRemoved,
    key,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notification &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.title == this.title &&
          other.body == this.body &&
          other.timestamp == this.timestamp &&
          other.iconData == this.iconData &&
          other.isRemoved == this.isRemoved &&
          other.key == this.key);
}

class NotificationsCompanion extends UpdateCompanion<Notification> {
  final Value<String> id;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> timestamp;
  final Value<String?> iconData;
  final Value<bool> isRemoved;
  final Value<String?> key;
  final Value<int> rowid;
  const NotificationsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.iconData = const Value.absent(),
    this.isRemoved = const Value.absent(),
    this.key = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationsCompanion.insert({
    required String id,
    required String packageName,
    required String appName,
    required String title,
    required String body,
    required DateTime timestamp,
    this.iconData = const Value.absent(),
    this.isRemoved = const Value.absent(),
    this.key = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packageName = Value(packageName),
       appName = Value(appName),
       title = Value(title),
       body = Value(body),
       timestamp = Value(timestamp);
  static Insertable<Notification> custom({
    Expression<String>? id,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? timestamp,
    Expression<String>? iconData,
    Expression<bool>? isRemoved,
    Expression<String>? key,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (timestamp != null) 'timestamp': timestamp,
      if (iconData != null) 'icon_data': iconData,
      if (isRemoved != null) 'is_removed': isRemoved,
      if (key != null) 'key': key,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? packageName,
    Value<String>? appName,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? timestamp,
    Value<String?>? iconData,
    Value<bool>? isRemoved,
    Value<String?>? key,
    Value<int>? rowid,
  }) {
    return NotificationsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      iconData: iconData ?? this.iconData,
      isRemoved: isRemoved ?? this.isRemoved,
      key: key ?? this.key,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (iconData.present) {
      map['icon_data'] = Variable<String>(iconData.value);
    }
    if (isRemoved.present) {
      map['is_removed'] = Variable<bool>(isRemoved.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('timestamp: $timestamp, ')
          ..write('iconData: $iconData, ')
          ..write('isRemoved: $isRemoved, ')
          ..write('key: $key, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationHistoryTable extends NotificationHistory
    with TableInfo<$NotificationHistoryTable, NotificationHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconDataMeta = const VerificationMeta(
    'iconData',
  );
  @override
  late final GeneratedColumn<String> iconData = GeneratedColumn<String>(
    'icon_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRemovedMeta = const VerificationMeta(
    'isRemoved',
  );
  @override
  late final GeneratedColumn<bool> isRemoved = GeneratedColumn<bool>(
    'is_removed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_removed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    appName,
    title,
    body,
    timestamp,
    iconData,
    isRemoved,
    key,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('icon_data')) {
      context.handle(
        _iconDataMeta,
        iconData.isAcceptableOrUnknown(data['icon_data']!, _iconDataMeta),
      );
    }
    if (data.containsKey('is_removed')) {
      context.handle(
        _isRemovedMeta,
        isRemoved.isAcceptableOrUnknown(data['is_removed']!, _isRemovedMeta),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotificationHistoryData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationHistoryData(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      packageName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}package_name'],
          )!,
      appName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}app_name'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      body:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}body'],
          )!,
      timestamp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}timestamp'],
          )!,
      iconData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_data'],
      ),
      isRemoved:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}is_removed'],
          )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      ),
    );
  }

  @override
  $NotificationHistoryTable createAlias(String alias) {
    return $NotificationHistoryTable(attachedDatabase, alias);
  }
}

class NotificationHistoryData extends DataClass
    implements Insertable<NotificationHistoryData> {
  final String id;
  final String packageName;
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  final String? iconData;
  final bool isRemoved;
  final String? key;
  const NotificationHistoryData({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.iconData,
    required this.isRemoved,
    this.key,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['package_name'] = Variable<String>(packageName);
    map['app_name'] = Variable<String>(appName);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || iconData != null) {
      map['icon_data'] = Variable<String>(iconData);
    }
    map['is_removed'] = Variable<bool>(isRemoved);
    if (!nullToAbsent || key != null) {
      map['key'] = Variable<String>(key);
    }
    return map;
  }

  NotificationHistoryCompanion toCompanion(bool nullToAbsent) {
    return NotificationHistoryCompanion(
      id: Value(id),
      packageName: Value(packageName),
      appName: Value(appName),
      title: Value(title),
      body: Value(body),
      timestamp: Value(timestamp),
      iconData:
          iconData == null && nullToAbsent
              ? const Value.absent()
              : Value(iconData),
      isRemoved: Value(isRemoved),
      key: key == null && nullToAbsent ? const Value.absent() : Value(key),
    );
  }

  factory NotificationHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationHistoryData(
      id: serializer.fromJson<String>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      appName: serializer.fromJson<String>(json['appName']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      iconData: serializer.fromJson<String?>(json['iconData']),
      isRemoved: serializer.fromJson<bool>(json['isRemoved']),
      key: serializer.fromJson<String?>(json['key']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'packageName': serializer.toJson<String>(packageName),
      'appName': serializer.toJson<String>(appName),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'iconData': serializer.toJson<String?>(iconData),
      'isRemoved': serializer.toJson<bool>(isRemoved),
      'key': serializer.toJson<String?>(key),
    };
  }

  NotificationHistoryData copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? title,
    String? body,
    DateTime? timestamp,
    Value<String?> iconData = const Value.absent(),
    bool? isRemoved,
    Value<String?> key = const Value.absent(),
  }) => NotificationHistoryData(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    appName: appName ?? this.appName,
    title: title ?? this.title,
    body: body ?? this.body,
    timestamp: timestamp ?? this.timestamp,
    iconData: iconData.present ? iconData.value : this.iconData,
    isRemoved: isRemoved ?? this.isRemoved,
    key: key.present ? key.value : this.key,
  );
  NotificationHistoryData copyWithCompanion(NotificationHistoryCompanion data) {
    return NotificationHistoryData(
      id: data.id.present ? data.id.value : this.id,
      packageName:
          data.packageName.present ? data.packageName.value : this.packageName,
      appName: data.appName.present ? data.appName.value : this.appName,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      iconData: data.iconData.present ? data.iconData.value : this.iconData,
      isRemoved: data.isRemoved.present ? data.isRemoved.value : this.isRemoved,
      key: data.key.present ? data.key.value : this.key,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationHistoryData(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('timestamp: $timestamp, ')
          ..write('iconData: $iconData, ')
          ..write('isRemoved: $isRemoved, ')
          ..write('key: $key')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packageName,
    appName,
    title,
    body,
    timestamp,
    iconData,
    isRemoved,
    key,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationHistoryData &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.appName == this.appName &&
          other.title == this.title &&
          other.body == this.body &&
          other.timestamp == this.timestamp &&
          other.iconData == this.iconData &&
          other.isRemoved == this.isRemoved &&
          other.key == this.key);
}

class NotificationHistoryCompanion
    extends UpdateCompanion<NotificationHistoryData> {
  final Value<String> id;
  final Value<String> packageName;
  final Value<String> appName;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> timestamp;
  final Value<String?> iconData;
  final Value<bool> isRemoved;
  final Value<String?> key;
  final Value<int> rowid;
  const NotificationHistoryCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.appName = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.iconData = const Value.absent(),
    this.isRemoved = const Value.absent(),
    this.key = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationHistoryCompanion.insert({
    required String id,
    required String packageName,
    required String appName,
    required String title,
    required String body,
    required DateTime timestamp,
    this.iconData = const Value.absent(),
    this.isRemoved = const Value.absent(),
    this.key = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       packageName = Value(packageName),
       appName = Value(appName),
       title = Value(title),
       body = Value(body),
       timestamp = Value(timestamp);
  static Insertable<NotificationHistoryData> custom({
    Expression<String>? id,
    Expression<String>? packageName,
    Expression<String>? appName,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? timestamp,
    Expression<String>? iconData,
    Expression<bool>? isRemoved,
    Expression<String>? key,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (appName != null) 'app_name': appName,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (timestamp != null) 'timestamp': timestamp,
      if (iconData != null) 'icon_data': iconData,
      if (isRemoved != null) 'is_removed': isRemoved,
      if (key != null) 'key': key,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? packageName,
    Value<String>? appName,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? timestamp,
    Value<String?>? iconData,
    Value<bool>? isRemoved,
    Value<String?>? key,
    Value<int>? rowid,
  }) {
    return NotificationHistoryCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      iconData: iconData ?? this.iconData,
      isRemoved: isRemoved ?? this.isRemoved,
      key: key ?? this.key,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (iconData.present) {
      map['icon_data'] = Variable<String>(iconData.value);
    }
    if (isRemoved.present) {
      map['is_removed'] = Variable<bool>(isRemoved.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationHistoryCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('appName: $appName, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('timestamp: $timestamp, ')
          ..write('iconData: $iconData, ')
          ..write('isRemoved: $isRemoved, ')
          ..write('key: $key, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotificationsTable notifications = $NotificationsTable(this);
  late final $NotificationHistoryTable notificationHistory =
      $NotificationHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notifications,
    notificationHistory,
  ];
}

typedef $$NotificationsTableCreateCompanionBuilder =
    NotificationsCompanion Function({
      required String id,
      required String packageName,
      required String appName,
      required String title,
      required String body,
      required DateTime timestamp,
      Value<String?> iconData,
      Value<bool> isRemoved,
      Value<String?> key,
      Value<int> rowid,
    });
typedef $$NotificationsTableUpdateCompanionBuilder =
    NotificationsCompanion Function({
      Value<String> id,
      Value<String> packageName,
      Value<String> appName,
      Value<String> title,
      Value<String> body,
      Value<DateTime> timestamp,
      Value<String?> iconData,
      Value<bool> isRemoved,
      Value<String?> key,
      Value<int> rowid,
    });

class $$NotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconData => $composableBuilder(
    column: $table.iconData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRemoved => $composableBuilder(
    column: $table.isRemoved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconData => $composableBuilder(
    column: $table.iconData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRemoved => $composableBuilder(
    column: $table.isRemoved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationsTable> {
  $$NotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get iconData =>
      $composableBuilder(column: $table.iconData, builder: (column) => column);

  GeneratedColumn<bool> get isRemoved =>
      $composableBuilder(column: $table.isRemoved, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);
}

class $$NotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationsTable,
          Notification,
          $$NotificationsTableFilterComposer,
          $$NotificationsTableOrderingComposer,
          $$NotificationsTableAnnotationComposer,
          $$NotificationsTableCreateCompanionBuilder,
          $$NotificationsTableUpdateCompanionBuilder,
          (
            Notification,
            BaseReferences<_$AppDatabase, $NotificationsTable, Notification>,
          ),
          Notification,
          PrefetchHooks Function()
        > {
  $$NotificationsTableTableManager(_$AppDatabase db, $NotificationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$NotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () =>
                  $$NotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$NotificationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> iconData = const Value.absent(),
                Value<bool> isRemoved = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion(
                id: id,
                packageName: packageName,
                appName: appName,
                title: title,
                body: body,
                timestamp: timestamp,
                iconData: iconData,
                isRemoved: isRemoved,
                key: key,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String packageName,
                required String appName,
                required String title,
                required String body,
                required DateTime timestamp,
                Value<String?> iconData = const Value.absent(),
                Value<bool> isRemoved = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationsCompanion.insert(
                id: id,
                packageName: packageName,
                appName: appName,
                title: title,
                body: body,
                timestamp: timestamp,
                iconData: iconData,
                isRemoved: isRemoved,
                key: key,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationsTable,
      Notification,
      $$NotificationsTableFilterComposer,
      $$NotificationsTableOrderingComposer,
      $$NotificationsTableAnnotationComposer,
      $$NotificationsTableCreateCompanionBuilder,
      $$NotificationsTableUpdateCompanionBuilder,
      (
        Notification,
        BaseReferences<_$AppDatabase, $NotificationsTable, Notification>,
      ),
      Notification,
      PrefetchHooks Function()
    >;
typedef $$NotificationHistoryTableCreateCompanionBuilder =
    NotificationHistoryCompanion Function({
      required String id,
      required String packageName,
      required String appName,
      required String title,
      required String body,
      required DateTime timestamp,
      Value<String?> iconData,
      Value<bool> isRemoved,
      Value<String?> key,
      Value<int> rowid,
    });
typedef $$NotificationHistoryTableUpdateCompanionBuilder =
    NotificationHistoryCompanion Function({
      Value<String> id,
      Value<String> packageName,
      Value<String> appName,
      Value<String> title,
      Value<String> body,
      Value<DateTime> timestamp,
      Value<String?> iconData,
      Value<bool> isRemoved,
      Value<String?> key,
      Value<int> rowid,
    });

class $$NotificationHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconData => $composableBuilder(
    column: $table.iconData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRemoved => $composableBuilder(
    column: $table.isRemoved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconData => $composableBuilder(
    column: $table.iconData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRemoved => $composableBuilder(
    column: $table.isRemoved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationHistoryTable> {
  $$NotificationHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get iconData =>
      $composableBuilder(column: $table.iconData, builder: (column) => column);

  GeneratedColumn<bool> get isRemoved =>
      $composableBuilder(column: $table.isRemoved, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);
}

class $$NotificationHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationHistoryTable,
          NotificationHistoryData,
          $$NotificationHistoryTableFilterComposer,
          $$NotificationHistoryTableOrderingComposer,
          $$NotificationHistoryTableAnnotationComposer,
          $$NotificationHistoryTableCreateCompanionBuilder,
          $$NotificationHistoryTableUpdateCompanionBuilder,
          (
            NotificationHistoryData,
            BaseReferences<
              _$AppDatabase,
              $NotificationHistoryTable,
              NotificationHistoryData
            >,
          ),
          NotificationHistoryData,
          PrefetchHooks Function()
        > {
  $$NotificationHistoryTableTableManager(
    _$AppDatabase db,
    $NotificationHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$NotificationHistoryTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$NotificationHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$NotificationHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> iconData = const Value.absent(),
                Value<bool> isRemoved = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationHistoryCompanion(
                id: id,
                packageName: packageName,
                appName: appName,
                title: title,
                body: body,
                timestamp: timestamp,
                iconData: iconData,
                isRemoved: isRemoved,
                key: key,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String packageName,
                required String appName,
                required String title,
                required String body,
                required DateTime timestamp,
                Value<String?> iconData = const Value.absent(),
                Value<bool> isRemoved = const Value.absent(),
                Value<String?> key = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationHistoryCompanion.insert(
                id: id,
                packageName: packageName,
                appName: appName,
                title: title,
                body: body,
                timestamp: timestamp,
                iconData: iconData,
                isRemoved: isRemoved,
                key: key,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationHistoryTable,
      NotificationHistoryData,
      $$NotificationHistoryTableFilterComposer,
      $$NotificationHistoryTableOrderingComposer,
      $$NotificationHistoryTableAnnotationComposer,
      $$NotificationHistoryTableCreateCompanionBuilder,
      $$NotificationHistoryTableUpdateCompanionBuilder,
      (
        NotificationHistoryData,
        BaseReferences<
          _$AppDatabase,
          $NotificationHistoryTable,
          NotificationHistoryData
        >,
      ),
      NotificationHistoryData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotificationsTableTableManager get notifications =>
      $$NotificationsTableTableManager(_db, _db.notifications);
  $$NotificationHistoryTableTableManager get notificationHistory =>
      $$NotificationHistoryTableTableManager(_db, _db.notificationHistory);
}
