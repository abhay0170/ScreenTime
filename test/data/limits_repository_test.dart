import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/platform_type.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app_usage_tracker/data/local/database.dart';
import 'package:flutter_app_usage_tracker/data/repositories/limits_repository.dart';
import 'package:flutter_app_usage_tracker/data/repositories/usage_repository.dart';
import 'package:flutter_app_usage_tracker/data/services/app_info_resolver.dart';
import 'package:flutter_app_usage_tracker/data/services/notification_service.dart';
import 'package:flutter_app_usage_tracker/data/services/settings_service.dart';
import 'package:flutter_app_usage_tracker/domain/models/app_usage_info.dart';
import 'package:flutter_app_usage_tracker/domain/models/time_limit.dart';

class MockUsageRepository extends Mock implements UsageRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAppInfoResolver extends Mock implements AppInfoResolver {}

AppInfo _appInfoFor(String name, String packageName) {
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

const _packageName = 'com.example.social';
const _appName = 'Chatter';
// A 2-hour limit -> 80% = 96 min, 100% = 120 min.
const _limitMinutes = 120;

AppUsageInfo _usageOf(Duration duration) {
  return AppUsageInfo(
    packageName: _packageName,
    appName: _appName,
    iconBytes: null,
    totalTime: duration,
  );
}

void main() {
  late MockUsageRepository usageRepository;
  late MockNotificationService notificationService;
  late MockAppInfoResolver appInfoResolver;
  late AppDatabase database;
  late LimitsRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    usageRepository = MockUsageRepository();
    notificationService = MockNotificationService();
    appInfoResolver = MockAppInfoResolver();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LimitsRepositoryImpl(
      database: database,
      usageRepository: usageRepository,
      appInfoResolver: appInfoResolver,
      notificationService: notificationService,
      settingsService: SettingsService(),
    );

    when(
      () => notificationService.showThresholdNotification(
        packageName: any(named: 'packageName'),
        appName: any(named: 'appName'),
        percent: any(named: 'percent'),
        limitMinutes: any(named: 'limitMinutes'),
      ),
    ).thenAnswer((_) async {});

    await repository.upsertLimit(
      TimeLimit(
        packageName: _packageName,
        dailyLimitMinutes: _limitMinutes,
        notifyAt80: true,
        notifyAt100: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('notifies at 80%', () async {
    when(
      () => usageRepository.getTodayUsage(),
    ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 96))]);

    await repository.checkAndNotifyThresholds();

    verify(
      () => notificationService.showThresholdNotification(
        packageName: _packageName,
        appName: _appName,
        percent: 80,
        limitMinutes: _limitMinutes,
      ),
    ).called(1);
    verifyNever(
      () => notificationService.showThresholdNotification(
        packageName: _packageName,
        appName: _appName,
        percent: 100,
        limitMinutes: _limitMinutes,
      ),
    );
  });

  test('notifies at 100%', () async {
    // 80% was already notified earlier today, so this run isolates the
    // 100% crossing.
    await database
        .into(database.limitNotificationState)
        .insertOnConflictUpdate(
          LimitNotificationStateCompanion.insert(
            packageName: _packageName,
            lastNotifiedAt80Date: Value(DateTime.now()),
          ),
        );

    when(
      () => usageRepository.getTodayUsage(),
    ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 125))]);

    await repository.checkAndNotifyThresholds();

    verify(
      () => notificationService.showThresholdNotification(
        packageName: _packageName,
        appName: _appName,
        percent: 100,
        limitMinutes: _limitMinutes,
      ),
    ).called(1);
    verifyNever(
      () => notificationService.showThresholdNotification(
        packageName: _packageName,
        appName: _appName,
        percent: 80,
        limitMinutes: _limitMinutes,
      ),
    );
  });

  test('does not re-notify the same threshold twice on the same day', () async {
    when(
      () => usageRepository.getTodayUsage(),
    ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 100))]);

    await repository.checkAndNotifyThresholds();
    await repository.checkAndNotifyThresholds();

    verify(
      () => notificationService.showThresholdNotification(
        packageName: _packageName,
        appName: _appName,
        percent: 80,
        limitMinutes: _limitMinutes,
      ),
    ).called(1);
  });

  test('notifies again the next day', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await database
        .into(database.limitNotificationState)
        .insertOnConflictUpdate(
          LimitNotificationStateCompanion.insert(
            packageName: _packageName,
            lastNotifiedAt80Date: Value(yesterday),
          ),
        );

    when(
      () => usageRepository.getTodayUsage(),
    ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 100))]);

    await repository.checkAndNotifyThresholds();

    verify(
      () => notificationService.showThresholdNotification(
        packageName: _packageName,
        appName: _appName,
        percent: 80,
        limitMinutes: _limitMinutes,
      ),
    ).called(1);
  });

  test(
    'does not notify at 80% when notifyAt80 is disabled for that limit',
    () async {
      await repository.upsertLimit(
        TimeLimit(
          packageName: _packageName,
          dailyLimitMinutes: _limitMinutes,
          notifyAt80: false,
          notifyAt100: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      when(
        () => usageRepository.getTodayUsage(),
      ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 100))]);

      await repository.checkAndNotifyThresholds();

      verifyNever(
        () => notificationService.showThresholdNotification(
          packageName: any(named: 'packageName'),
          appName: any(named: 'appName'),
          percent: any(named: 'percent'),
          limitMinutes: any(named: 'limitMinutes'),
        ),
      );
    },
  );

  test(
    'does not notify for a zero-minute limit (guards a divide-by-zero)',
    () async {
      await repository.upsertLimit(
        TimeLimit(
          packageName: _packageName,
          dailyLimitMinutes: 0,
          notifyAt80: true,
          notifyAt100: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );
      when(
        () => usageRepository.getTodayUsage(),
      ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 5))]);

      await repository.checkAndNotifyThresholds();

      verifyNever(
        () => notificationService.showThresholdNotification(
          packageName: any(named: 'packageName'),
          appName: any(named: 'appName'),
          percent: any(named: 'percent'),
          limitMinutes: any(named: 'limitMinutes'),
        ),
      );
    },
  );

  test('skips a limit for an app that has no usage today', () async {
    when(() => usageRepository.getTodayUsage()).thenAnswer((_) async => []);

    await repository.checkAndNotifyThresholds();

    verifyNever(
      () => notificationService.showThresholdNotification(
        packageName: any(named: 'packageName'),
        appName: any(named: 'appName'),
        percent: any(named: 'percent'),
        limitMinutes: any(named: 'limitMinutes'),
      ),
    );
  });

  test(
    'does nothing when threshold notifications are disabled in settings',
    () async {
      SharedPreferences.setMockInitialValues({
        'threshold_notifications_enabled': false,
      });
      when(
        () => usageRepository.getTodayUsage(),
      ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 125))]);

      await repository.checkAndNotifyThresholds();

      verifyNever(
        () => notificationService.showThresholdNotification(
          packageName: any(named: 'packageName'),
          appName: any(named: 'appName'),
          percent: any(named: 'percent'),
          limitMinutes: any(named: 'limitMinutes'),
        ),
      );
    },
  );

  group('getLimitsWithUsage', () {
    test('returns empty when there are no limits', () async {
      await repository.deleteLimit(_packageName);

      expect(await repository.getLimitsWithUsage(), isEmpty);
    });

    test('uses today\'s usage for an app that was used today', () async {
      when(
        () => usageRepository.getTodayUsage(),
      ).thenAnswer((_) async => [_usageOf(const Duration(minutes: 45))]);

      final result = await repository.getLimitsWithUsage();

      expect(result, hasLength(1));
      expect(result.single.appName, _appName);
      expect(result.single.usedToday, const Duration(minutes: 45));
    });

    test("falls back to resolving the app's info directly when it wasn't used "
        'today', () async {
      when(() => usageRepository.getTodayUsage()).thenAnswer((_) async => []);
      when(
        () => appInfoResolver.resolve(_packageName),
      ).thenAnswer((_) async => _appInfoFor(_appName, _packageName));

      final result = await repository.getLimitsWithUsage();

      expect(result, hasLength(1));
      expect(result.single.appName, _appName);
      expect(result.single.usedToday, Duration.zero);
    });

    test(
      'falls back to the raw package name when the app fails to resolve',
      () async {
        when(() => usageRepository.getTodayUsage()).thenAnswer((_) async => []);
        when(
          () => appInfoResolver.resolve(_packageName),
        ).thenAnswer((_) async => null);

        final result = await repository.getLimitsWithUsage();

        expect(result.single.appName, _packageName);
      },
    );
  });

  group('getLimitForPackage', () {
    test('returns the limit when one is configured', () async {
      final limit = await repository.getLimitForPackage(_packageName);

      expect(limit, isNotNull);
      expect(limit!.dailyLimitMinutes, _limitMinutes);
    });

    test('returns null when no limit is configured for the package', () async {
      final limit = await repository.getLimitForPackage('com.no.limit');

      expect(limit, isNull);
    });
  });

  group('deleteLimit', () {
    test('removes the limit so it no longer appears in getAllLimits', () async {
      await repository.deleteLimit(_packageName);

      expect(await repository.getAllLimits(), isEmpty);
    });

    test('also clears any notification state for that package', () async {
      await database
          .into(database.limitNotificationState)
          .insertOnConflictUpdate(
            LimitNotificationStateCompanion.insert(
              packageName: _packageName,
              lastNotifiedAt80Date: Value(DateTime.now()),
            ),
          );

      await repository.deleteLimit(_packageName);

      final states = await database
          .select(database.limitNotificationState)
          .get();
      expect(states, isEmpty);
    });
  });
}
