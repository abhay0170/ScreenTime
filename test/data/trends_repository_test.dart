import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/platform_type.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/data/local/database.dart';
import 'package:flutter_app_usage_tracker/data/repositories/trends_repository.dart';
import 'package:flutter_app_usage_tracker/data/services/app_info_resolver.dart';

class MockAppInfoResolver extends Mock implements AppInfoResolver {}

AppInfo _appInfo(String name, String packageName) {
  return AppInfo(
    name: name,
    icon: null,
    packageName: packageName,
    versionName: '1.0.0',
    versionCode: 1,
    platformType: PlatformType.nativeOrOthers,
    installedTimestamp: 0,
    isSystemApp: false,
    isLaunchableApp: true,
    category: AppCategory.undefined,
  );
}

DateTime _day(int daysAgo) {
  final today = DateTime.now();
  final startOfToday = DateTime(today.year, today.month, today.day);
  return startOfToday.subtract(Duration(days: daysAgo));
}

void main() {
  late AppDatabase database;
  late MockAppInfoResolver appInfoResolver;
  late TrendsRepository repository;

  Future<void> insertRecord({
    required String packageName,
    required DateTime date,
    required int totalSeconds,
  }) {
    return database
        .into(database.appUsageRecords)
        .insertOnConflictUpdate(
          AppUsageRecordsCompanion.insert(
            packageName: packageName,
            date: date,
            totalSeconds: totalSeconds,
            lastSynced: DateTime.now(),
          ),
        );
  }

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    appInfoResolver = MockAppInfoResolver();
    repository = TrendsRepositoryImpl(
      database: database,
      appInfoResolver: appInfoResolver,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('getDailyTotals', () {
    test(
      'fills every day in range, summing across apps on the same day',
      () async {
        await insertRecord(
          packageName: 'com.social',
          date: _day(2),
          totalSeconds: 600,
        );
        await insertRecord(
          packageName: 'com.game',
          date: _day(2),
          totalSeconds: 900,
        );
        await insertRecord(
          packageName: 'com.social',
          date: _day(0),
          totalSeconds: 300,
        );

        final result = await repository.getDailyTotals(
          _day(2),
          _day(0).add(const Duration(days: 1)),
        );

        expect(result, hasLength(3));
        expect(result[0].date, _day(2));
        expect(result[0].total, const Duration(seconds: 1500));
        // Middle day has no records at all — still present, zeroed.
        expect(result[1].date, _day(1));
        expect(result[1].total, Duration.zero);
        expect(result[2].date, _day(0));
        expect(result[2].total, const Duration(seconds: 300));
      },
    );

    test('excludes records outside the requested range', () async {
      await insertRecord(
        packageName: 'com.social',
        date: _day(10),
        totalSeconds: 600,
      );

      final result = await repository.getDailyTotals(
        _day(2),
        _day(0).add(const Duration(days: 1)),
      );

      expect(result.every((d) => d.total == Duration.zero), isTrue);
    });
  });

  group('getDailyTotalsForApp', () {
    test(
      'only sums the requested package, ignoring others on the same day',
      () async {
        await insertRecord(
          packageName: 'com.social',
          date: _day(1),
          totalSeconds: 600,
        );
        await insertRecord(
          packageName: 'com.game',
          date: _day(1),
          totalSeconds: 900,
        );

        final result = await repository.getDailyTotalsForApp(
          'com.social',
          _day(1),
          _day(0).add(const Duration(days: 1)),
        );

        expect(result[0].total, const Duration(seconds: 600));
      },
    );
  });

  group('getTopAppsForRange', () {
    test('sums per app across the range and sorts descending', () async {
      await insertRecord(
        packageName: 'com.social',
        date: _day(2),
        totalSeconds: 300,
      );
      await insertRecord(
        packageName: 'com.social',
        date: _day(1),
        totalSeconds: 300,
      );
      await insertRecord(
        packageName: 'com.game',
        date: _day(1),
        totalSeconds: 1000,
      );

      when(
        () => appInfoResolver.resolve('com.social'),
      ).thenAnswer((_) async => _appInfo('Social', 'com.social'));
      when(
        () => appInfoResolver.resolve('com.game'),
      ).thenAnswer((_) async => _appInfo('Game', 'com.game'));

      final result = await repository.getTopAppsForRange(
        _day(2),
        _day(0).add(const Duration(days: 1)),
      );

      expect(result.map((a) => a.packageName), ['com.game', 'com.social']);
      expect(result[0].totalTime, const Duration(seconds: 1000));
      // The two com.social records (300s each) are summed, not left separate.
      expect(result[1].totalTime, const Duration(seconds: 600));
    });

    test('skips apps that no longer resolve (e.g. uninstalled)', () async {
      await insertRecord(
        packageName: 'com.gone',
        date: _day(1),
        totalSeconds: 500,
      );

      when(
        () => appInfoResolver.resolve('com.gone'),
      ).thenAnswer((_) async => null);

      final result = await repository.getTopAppsForRange(
        _day(2),
        _day(0).add(const Duration(days: 1)),
      );

      expect(result, isEmpty);
    });
  });

  group('getEarliestRecordedDate', () {
    test('returns null when there is no history at all', () async {
      expect(await repository.getEarliestRecordedDate(), isNull);
    });

    test('returns the earliest date across all packages', () async {
      await insertRecord(
        packageName: 'com.social',
        date: _day(3),
        totalSeconds: 100,
      );
      await insertRecord(
        packageName: 'com.game',
        date: _day(10),
        totalSeconds: 100,
      );
      await insertRecord(
        packageName: 'com.social',
        date: _day(1),
        totalSeconds: 100,
      );

      expect(await repository.getEarliestRecordedDate(), _day(10));
    });
  });
}
