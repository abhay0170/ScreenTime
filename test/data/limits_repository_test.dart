import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/data/local/database.dart';
import 'package:flutter_app_usage_tracker/data/repositories/limits_repository.dart';
import 'package:flutter_app_usage_tracker/data/repositories/usage_repository.dart';
import 'package:flutter_app_usage_tracker/data/services/app_info_resolver.dart';
import 'package:flutter_app_usage_tracker/data/services/notification_service.dart';
import 'package:flutter_app_usage_tracker/domain/models/app_usage_info.dart';
import 'package:flutter_app_usage_tracker/domain/models/time_limit.dart';

class MockUsageRepository extends Mock implements UsageRepository {}

class MockNotificationService extends Mock implements NotificationService {}

const _packageName = 'com.example.social';
const _appName = 'Chatter';
// A 2-hour limit -> 80% = 96 min, 100% = 120 min.
const _limitMinutes = 120;

AppUsageInfo _usageOf(Duration duration) {
  return AppUsageInfo(
    packageName: _packageName,
    appName: _appName,
    iconBytes: null,
    totalTimeToday: duration,
  );
}

void main() {
  late MockUsageRepository usageRepository;
  late MockNotificationService notificationService;
  late AppDatabase database;
  late LimitsRepository repository;

  setUp(() async {
    usageRepository = MockUsageRepository();
    notificationService = MockNotificationService();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LimitsRepositoryImpl(
      database: database,
      usageRepository: usageRepository,
      appInfoResolver: AppInfoResolver(),
      notificationService: notificationService,
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
}
