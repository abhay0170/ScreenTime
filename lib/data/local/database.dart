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
  TextColumn get packageName => text().unique()();
  IntColumn get dailyLimitMinutes => integer()();
  BoolColumn get notifyAt80 => boolean().withDefault(const Constant(true))();
  BoolColumn get notifyAt100 => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [AppUsageRecords, TimeLimits])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'screentime.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
