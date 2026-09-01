import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('AppUsageRecordRow')
class AppUsageRecords extends Table {
  TextColumn get packageName => text()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalSeconds => integer()();
  DateTimeColumn get lastSynced => dateTime()();

  @override
  Set<Column> get primaryKey => {packageName, date};
}

@DataClassName('TimeLimitRow')
class TimeLimits extends Table {
  TextColumn get packageName => text()();
  IntColumn get dailyLimitMinutes => integer()();
  BoolColumn get notifyAt80 => boolean().withDefault(const Constant(true))();
  BoolColumn get notifyAt100 => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {packageName};
}

/// Tracks whether we've already fired the 80%/100% notification for a
/// package today, so the ~15 minute background check doesn't re-notify on
/// every run.
@DataClassName('LimitNotificationStateRow')
class LimitNotificationState extends Table {
  TextColumn get packageName => text()();
  DateTimeColumn get lastNotifiedAt80Date => dateTime().nullable()();
  DateTimeColumn get lastNotifiedAt100Date => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {packageName};
}

@DriftDatabase(tables: [AppUsageRecords, TimeLimits, LimitNotificationState])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(limitNotificationState);
      }
    },
  );

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'screentime.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
