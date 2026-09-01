// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AppUsageRecordsTable extends AppUsageRecords
    with TableInfo<$AppUsageRecordsTable, AppUsageRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppUsageRecordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSecondsMeta = const VerificationMeta(
    'totalSeconds',
  );
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
    'total_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedMeta = const VerificationMeta(
    'lastSynced',
  );
  @override
  late final GeneratedColumn<DateTime> lastSynced = GeneratedColumn<DateTime>(
    'last_synced',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packageName,
    date,
    totalSeconds,
    lastSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_usage_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppUsageRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
        _totalSecondsMeta,
        totalSeconds.isAcceptableOrUnknown(
          data['total_seconds']!,
          _totalSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSecondsMeta);
    }
    if (data.containsKey('last_synced')) {
      context.handle(
        _lastSyncedMeta,
        lastSynced.isAcceptableOrUnknown(data['last_synced']!, _lastSyncedMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSyncedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packageName, date};
  @override
  AppUsageRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppUsageRecordRow(
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      totalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seconds'],
      )!,
      lastSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced'],
      )!,
    );
  }

  @override
  $AppUsageRecordsTable createAlias(String alias) {
    return $AppUsageRecordsTable(attachedDatabase, alias);
  }
}

class AppUsageRecordRow extends DataClass
    implements Insertable<AppUsageRecordRow> {
  final String packageName;
  final DateTime date;
  final int totalSeconds;
  final DateTime lastSynced;
  const AppUsageRecordRow({
    required this.packageName,
    required this.date,
    required this.totalSeconds,
    required this.lastSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['package_name'] = Variable<String>(packageName);
    map['date'] = Variable<DateTime>(date);
    map['total_seconds'] = Variable<int>(totalSeconds);
    map['last_synced'] = Variable<DateTime>(lastSynced);
    return map;
  }

  AppUsageRecordsCompanion toCompanion(bool nullToAbsent) {
    return AppUsageRecordsCompanion(
      packageName: Value(packageName),
      date: Value(date),
      totalSeconds: Value(totalSeconds),
      lastSynced: Value(lastSynced),
    );
  }

  factory AppUsageRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppUsageRecordRow(
      packageName: serializer.fromJson<String>(json['packageName']),
      date: serializer.fromJson<DateTime>(json['date']),
      totalSeconds: serializer.fromJson<int>(json['totalSeconds']),
      lastSynced: serializer.fromJson<DateTime>(json['lastSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packageName': serializer.toJson<String>(packageName),
      'date': serializer.toJson<DateTime>(date),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
      'lastSynced': serializer.toJson<DateTime>(lastSynced),
    };
  }

  AppUsageRecordRow copyWith({
    String? packageName,
    DateTime? date,
    int? totalSeconds,
    DateTime? lastSynced,
  }) => AppUsageRecordRow(
    packageName: packageName ?? this.packageName,
    date: date ?? this.date,
    totalSeconds: totalSeconds ?? this.totalSeconds,
    lastSynced: lastSynced ?? this.lastSynced,
  );
  AppUsageRecordRow copyWithCompanion(AppUsageRecordsCompanion data) {
    return AppUsageRecordRow(
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      date: data.date.present ? data.date.value : this.date,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
      lastSynced: data.lastSynced.present
          ? data.lastSynced.value
          : this.lastSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageRecordRow(')
          ..write('packageName: $packageName, ')
          ..write('date: $date, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('lastSynced: $lastSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(packageName, date, totalSeconds, lastSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppUsageRecordRow &&
          other.packageName == this.packageName &&
          other.date == this.date &&
          other.totalSeconds == this.totalSeconds &&
          other.lastSynced == this.lastSynced);
}

class AppUsageRecordsCompanion extends UpdateCompanion<AppUsageRecordRow> {
  final Value<String> packageName;
  final Value<DateTime> date;
  final Value<int> totalSeconds;
  final Value<DateTime> lastSynced;
  final Value<int> rowid;
  const AppUsageRecordsCompanion({
    this.packageName = const Value.absent(),
    this.date = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.lastSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppUsageRecordsCompanion.insert({
    required String packageName,
    required DateTime date,
    required int totalSeconds,
    required DateTime lastSynced,
    this.rowid = const Value.absent(),
  }) : packageName = Value(packageName),
       date = Value(date),
       totalSeconds = Value(totalSeconds),
       lastSynced = Value(lastSynced);
  static Insertable<AppUsageRecordRow> custom({
    Expression<String>? packageName,
    Expression<DateTime>? date,
    Expression<int>? totalSeconds,
    Expression<DateTime>? lastSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packageName != null) 'package_name': packageName,
      if (date != null) 'date': date,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (lastSynced != null) 'last_synced': lastSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppUsageRecordsCompanion copyWith({
    Value<String>? packageName,
    Value<DateTime>? date,
    Value<int>? totalSeconds,
    Value<DateTime>? lastSynced,
    Value<int>? rowid,
  }) {
    return AppUsageRecordsCompanion(
      packageName: packageName ?? this.packageName,
      date: date ?? this.date,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      lastSynced: lastSynced ?? this.lastSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    if (lastSynced.present) {
      map['last_synced'] = Variable<DateTime>(lastSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppUsageRecordsCompanion(')
          ..write('packageName: $packageName, ')
          ..write('date: $date, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('lastSynced: $lastSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeLimitsTable extends TimeLimits
    with TableInfo<$TimeLimitsTable, TimeLimitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeLimitsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _dailyLimitMinutesMeta = const VerificationMeta(
    'dailyLimitMinutes',
  );
  @override
  late final GeneratedColumn<int> dailyLimitMinutes = GeneratedColumn<int>(
    'daily_limit_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifyAt80Meta = const VerificationMeta(
    'notifyAt80',
  );
  @override
  late final GeneratedColumn<bool> notifyAt80 = GeneratedColumn<bool>(
    'notify_at80',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_at80" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _notifyAt100Meta = const VerificationMeta(
    'notifyAt100',
  );
  @override
  late final GeneratedColumn<bool> notifyAt100 = GeneratedColumn<bool>(
    'notify_at100',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notify_at100" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    packageName,
    dailyLimitMinutes,
    notifyAt80,
    notifyAt100,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_limits';
  @override
  VerificationContext validateIntegrity(
    Insertable<TimeLimitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    if (data.containsKey('daily_limit_minutes')) {
      context.handle(
        _dailyLimitMinutesMeta,
        dailyLimitMinutes.isAcceptableOrUnknown(
          data['daily_limit_minutes']!,
          _dailyLimitMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyLimitMinutesMeta);
    }
    if (data.containsKey('notify_at80')) {
      context.handle(
        _notifyAt80Meta,
        notifyAt80.isAcceptableOrUnknown(data['notify_at80']!, _notifyAt80Meta),
      );
    }
    if (data.containsKey('notify_at100')) {
      context.handle(
        _notifyAt100Meta,
        notifyAt100.isAcceptableOrUnknown(
          data['notify_at100']!,
          _notifyAt100Meta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  TimeLimitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeLimitRow(
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      dailyLimitMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_limit_minutes'],
      )!,
      notifyAt80: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_at80'],
      )!,
      notifyAt100: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notify_at100'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TimeLimitsTable createAlias(String alias) {
    return $TimeLimitsTable(attachedDatabase, alias);
  }
}

class TimeLimitRow extends DataClass implements Insertable<TimeLimitRow> {
  final String packageName;
  final int dailyLimitMinutes;
  final bool notifyAt80;
  final bool notifyAt100;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TimeLimitRow({
    required this.packageName,
    required this.dailyLimitMinutes,
    required this.notifyAt80,
    required this.notifyAt100,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['package_name'] = Variable<String>(packageName);
    map['daily_limit_minutes'] = Variable<int>(dailyLimitMinutes);
    map['notify_at80'] = Variable<bool>(notifyAt80);
    map['notify_at100'] = Variable<bool>(notifyAt100);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TimeLimitsCompanion toCompanion(bool nullToAbsent) {
    return TimeLimitsCompanion(
      packageName: Value(packageName),
      dailyLimitMinutes: Value(dailyLimitMinutes),
      notifyAt80: Value(notifyAt80),
      notifyAt100: Value(notifyAt100),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimeLimitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeLimitRow(
      packageName: serializer.fromJson<String>(json['packageName']),
      dailyLimitMinutes: serializer.fromJson<int>(json['dailyLimitMinutes']),
      notifyAt80: serializer.fromJson<bool>(json['notifyAt80']),
      notifyAt100: serializer.fromJson<bool>(json['notifyAt100']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packageName': serializer.toJson<String>(packageName),
      'dailyLimitMinutes': serializer.toJson<int>(dailyLimitMinutes),
      'notifyAt80': serializer.toJson<bool>(notifyAt80),
      'notifyAt100': serializer.toJson<bool>(notifyAt100),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TimeLimitRow copyWith({
    String? packageName,
    int? dailyLimitMinutes,
    bool? notifyAt80,
    bool? notifyAt100,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TimeLimitRow(
    packageName: packageName ?? this.packageName,
    dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    notifyAt80: notifyAt80 ?? this.notifyAt80,
    notifyAt100: notifyAt100 ?? this.notifyAt100,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TimeLimitRow copyWithCompanion(TimeLimitsCompanion data) {
    return TimeLimitRow(
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      dailyLimitMinutes: data.dailyLimitMinutes.present
          ? data.dailyLimitMinutes.value
          : this.dailyLimitMinutes,
      notifyAt80: data.notifyAt80.present
          ? data.notifyAt80.value
          : this.notifyAt80,
      notifyAt100: data.notifyAt100.present
          ? data.notifyAt100.value
          : this.notifyAt100,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeLimitRow(')
          ..write('packageName: $packageName, ')
          ..write('dailyLimitMinutes: $dailyLimitMinutes, ')
          ..write('notifyAt80: $notifyAt80, ')
          ..write('notifyAt100: $notifyAt100, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    packageName,
    dailyLimitMinutes,
    notifyAt80,
    notifyAt100,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeLimitRow &&
          other.packageName == this.packageName &&
          other.dailyLimitMinutes == this.dailyLimitMinutes &&
          other.notifyAt80 == this.notifyAt80 &&
          other.notifyAt100 == this.notifyAt100 &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TimeLimitsCompanion extends UpdateCompanion<TimeLimitRow> {
  final Value<String> packageName;
  final Value<int> dailyLimitMinutes;
  final Value<bool> notifyAt80;
  final Value<bool> notifyAt100;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TimeLimitsCompanion({
    this.packageName = const Value.absent(),
    this.dailyLimitMinutes = const Value.absent(),
    this.notifyAt80 = const Value.absent(),
    this.notifyAt100 = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeLimitsCompanion.insert({
    required String packageName,
    required int dailyLimitMinutes,
    this.notifyAt80 = const Value.absent(),
    this.notifyAt100 = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : packageName = Value(packageName),
       dailyLimitMinutes = Value(dailyLimitMinutes),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TimeLimitRow> custom({
    Expression<String>? packageName,
    Expression<int>? dailyLimitMinutes,
    Expression<bool>? notifyAt80,
    Expression<bool>? notifyAt100,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packageName != null) 'package_name': packageName,
      if (dailyLimitMinutes != null) 'daily_limit_minutes': dailyLimitMinutes,
      if (notifyAt80 != null) 'notify_at80': notifyAt80,
      if (notifyAt100 != null) 'notify_at100': notifyAt100,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeLimitsCompanion copyWith({
    Value<String>? packageName,
    Value<int>? dailyLimitMinutes,
    Value<bool>? notifyAt80,
    Value<bool>? notifyAt100,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TimeLimitsCompanion(
      packageName: packageName ?? this.packageName,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      notifyAt80: notifyAt80 ?? this.notifyAt80,
      notifyAt100: notifyAt100 ?? this.notifyAt100,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (dailyLimitMinutes.present) {
      map['daily_limit_minutes'] = Variable<int>(dailyLimitMinutes.value);
    }
    if (notifyAt80.present) {
      map['notify_at80'] = Variable<bool>(notifyAt80.value);
    }
    if (notifyAt100.present) {
      map['notify_at100'] = Variable<bool>(notifyAt100.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeLimitsCompanion(')
          ..write('packageName: $packageName, ')
          ..write('dailyLimitMinutes: $dailyLimitMinutes, ')
          ..write('notifyAt80: $notifyAt80, ')
          ..write('notifyAt100: $notifyAt100, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppUsageRecordsTable appUsageRecords = $AppUsageRecordsTable(
    this,
  );
  late final $TimeLimitsTable timeLimits = $TimeLimitsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appUsageRecords,
    timeLimits,
  ];
}

typedef $$AppUsageRecordsTableCreateCompanionBuilder =
    AppUsageRecordsCompanion Function({
      required String packageName,
      required DateTime date,
      required int totalSeconds,
      required DateTime lastSynced,
      Value<int> rowid,
    });
typedef $$AppUsageRecordsTableUpdateCompanionBuilder =
    AppUsageRecordsCompanion Function({
      Value<String> packageName,
      Value<DateTime> date,
      Value<int> totalSeconds,
      Value<DateTime> lastSynced,
      Value<int> rowid,
    });

class $$AppUsageRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $AppUsageRecordsTable> {
  $$AppUsageRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppUsageRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppUsageRecordsTable> {
  $$AppUsageRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppUsageRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppUsageRecordsTable> {
  $$AppUsageRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSynced => $composableBuilder(
    column: $table.lastSynced,
    builder: (column) => column,
  );
}

class $$AppUsageRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppUsageRecordsTable,
          AppUsageRecordRow,
          $$AppUsageRecordsTableFilterComposer,
          $$AppUsageRecordsTableOrderingComposer,
          $$AppUsageRecordsTableAnnotationComposer,
          $$AppUsageRecordsTableCreateCompanionBuilder,
          $$AppUsageRecordsTableUpdateCompanionBuilder,
          (
            AppUsageRecordRow,
            BaseReferences<
              _$AppDatabase,
              $AppUsageRecordsTable,
              AppUsageRecordRow
            >,
          ),
          AppUsageRecordRow,
          PrefetchHooks Function()
        > {
  $$AppUsageRecordsTableTableManager(
    _$AppDatabase db,
    $AppUsageRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppUsageRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppUsageRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppUsageRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packageName = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> totalSeconds = const Value.absent(),
                Value<DateTime> lastSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppUsageRecordsCompanion(
                packageName: packageName,
                date: date,
                totalSeconds: totalSeconds,
                lastSynced: lastSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packageName,
                required DateTime date,
                required int totalSeconds,
                required DateTime lastSynced,
                Value<int> rowid = const Value.absent(),
              }) => AppUsageRecordsCompanion.insert(
                packageName: packageName,
                date: date,
                totalSeconds: totalSeconds,
                lastSynced: lastSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppUsageRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppUsageRecordsTable,
      AppUsageRecordRow,
      $$AppUsageRecordsTableFilterComposer,
      $$AppUsageRecordsTableOrderingComposer,
      $$AppUsageRecordsTableAnnotationComposer,
      $$AppUsageRecordsTableCreateCompanionBuilder,
      $$AppUsageRecordsTableUpdateCompanionBuilder,
      (
        AppUsageRecordRow,
        BaseReferences<_$AppDatabase, $AppUsageRecordsTable, AppUsageRecordRow>,
      ),
      AppUsageRecordRow,
      PrefetchHooks Function()
    >;
typedef $$TimeLimitsTableCreateCompanionBuilder =
    TimeLimitsCompanion Function({
      required String packageName,
      required int dailyLimitMinutes,
      Value<bool> notifyAt80,
      Value<bool> notifyAt100,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TimeLimitsTableUpdateCompanionBuilder =
    TimeLimitsCompanion Function({
      Value<String> packageName,
      Value<int> dailyLimitMinutes,
      Value<bool> notifyAt80,
      Value<bool> notifyAt100,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TimeLimitsTableFilterComposer
    extends Composer<_$AppDatabase, $TimeLimitsTable> {
  $$TimeLimitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyAt80 => $composableBuilder(
    column: $table.notifyAt80,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notifyAt100 => $composableBuilder(
    column: $table.notifyAt100,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TimeLimitsTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeLimitsTable> {
  $$TimeLimitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyAt80 => $composableBuilder(
    column: $table.notifyAt80,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notifyAt100 => $composableBuilder(
    column: $table.notifyAt100,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TimeLimitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeLimitsTable> {
  $$TimeLimitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyAt80 => $composableBuilder(
    column: $table.notifyAt80,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notifyAt100 => $composableBuilder(
    column: $table.notifyAt100,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TimeLimitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TimeLimitsTable,
          TimeLimitRow,
          $$TimeLimitsTableFilterComposer,
          $$TimeLimitsTableOrderingComposer,
          $$TimeLimitsTableAnnotationComposer,
          $$TimeLimitsTableCreateCompanionBuilder,
          $$TimeLimitsTableUpdateCompanionBuilder,
          (
            TimeLimitRow,
            BaseReferences<_$AppDatabase, $TimeLimitsTable, TimeLimitRow>,
          ),
          TimeLimitRow,
          PrefetchHooks Function()
        > {
  $$TimeLimitsTableTableManager(_$AppDatabase db, $TimeLimitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeLimitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeLimitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeLimitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packageName = const Value.absent(),
                Value<int> dailyLimitMinutes = const Value.absent(),
                Value<bool> notifyAt80 = const Value.absent(),
                Value<bool> notifyAt100 = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TimeLimitsCompanion(
                packageName: packageName,
                dailyLimitMinutes: dailyLimitMinutes,
                notifyAt80: notifyAt80,
                notifyAt100: notifyAt100,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packageName,
                required int dailyLimitMinutes,
                Value<bool> notifyAt80 = const Value.absent(),
                Value<bool> notifyAt100 = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TimeLimitsCompanion.insert(
                packageName: packageName,
                dailyLimitMinutes: dailyLimitMinutes,
                notifyAt80: notifyAt80,
                notifyAt100: notifyAt100,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TimeLimitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TimeLimitsTable,
      TimeLimitRow,
      $$TimeLimitsTableFilterComposer,
      $$TimeLimitsTableOrderingComposer,
      $$TimeLimitsTableAnnotationComposer,
      $$TimeLimitsTableCreateCompanionBuilder,
      $$TimeLimitsTableUpdateCompanionBuilder,
      (
        TimeLimitRow,
        BaseReferences<_$AppDatabase, $TimeLimitsTable, TimeLimitRow>,
      ),
      TimeLimitRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppUsageRecordsTableTableManager get appUsageRecords =>
      $$AppUsageRecordsTableTableManager(_db, _db.appUsageRecords);
  $$TimeLimitsTableTableManager get timeLimits =>
      $$TimeLimitsTableTableManager(_db, _db.timeLimits);
}
