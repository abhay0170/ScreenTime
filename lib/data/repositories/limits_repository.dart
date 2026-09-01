import 'package:drift/drift.dart';

import '../../domain/models/limit_with_usage.dart';
import '../../domain/models/time_limit.dart';
import '../local/database.dart';
import '../services/app_info_resolver.dart';
import '../services/notification_service.dart';
import 'usage_repository.dart';

abstract class LimitsRepository {
  Future<List<TimeLimit>> getAllLimits();

  /// [getAllLimits] enriched with each app's display name/icon and today's
  /// usage, for rendering the Limits screen.
  Future<List<LimitWithUsage>> getLimitsWithUsage();

  Future<TimeLimit?> getLimitForPackage(String packageName);
  Future<void> upsertLimit(TimeLimit limit);
  Future<void> deleteLimit(String packageName);

  /// For each active limit, compares today's usage against the limit and
  /// fires a notification for any threshold (80%/100%) crossed for the
  /// first time today.
  Future<void> checkAndNotifyThresholds();
}

class LimitsRepositoryImpl implements LimitsRepository {
  final AppDatabase _database;
  final UsageRepository _usageRepository;
  final AppInfoResolver _appInfoResolver;
  final NotificationService _notificationService;

  LimitsRepositoryImpl({
    required AppDatabase database,
    required UsageRepository usageRepository,
    required AppInfoResolver appInfoResolver,
    required NotificationService notificationService,
  }) : _database = database,
       _usageRepository = usageRepository,
       _appInfoResolver = appInfoResolver,
       _notificationService = notificationService;

  @override
  Future<List<TimeLimit>> getAllLimits() async {
    final rows = await _database.select(_database.timeLimits).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<LimitWithUsage>> getLimitsWithUsage() async {
    final limits = await getAllLimits();
    if (limits.isEmpty) return const [];

    final usage = await _usageRepository.getTodayUsage();
    final usageByPackage = {for (final app in usage) app.packageName: app};

    final result = <LimitWithUsage>[];
    for (final limit in limits) {
      final app = usageByPackage[limit.packageName];
      if (app != null) {
        result.add(
          LimitWithUsage(
            limit: limit,
            appName: app.appName,
            iconBytes: app.iconBytes,
            usedToday: app.totalTime,
          ),
        );
        continue;
      }

      // The app has a limit but hasn't been used today — fall back to
      // resolving its display info directly.
      final appInfo = await _appInfoResolver.resolve(limit.packageName);
      result.add(
        LimitWithUsage(
          limit: limit,
          appName: appInfo?.name ?? limit.packageName,
          iconBytes: appInfo?.icon,
          usedToday: Duration.zero,
        ),
      );
    }
    return result;
  }

  @override
  Future<TimeLimit?> getLimitForPackage(String packageName) async {
    final row = await (_database.select(
      _database.timeLimits,
    )..where((t) => t.packageName.equals(packageName))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> upsertLimit(TimeLimit limit) async {
    await _database
        .into(_database.timeLimits)
        .insertOnConflictUpdate(
          TimeLimitsCompanion.insert(
            packageName: limit.packageName,
            dailyLimitMinutes: limit.dailyLimitMinutes,
            notifyAt80: Value(limit.notifyAt80),
            notifyAt100: Value(limit.notifyAt100),
            createdAt: limit.createdAt,
            updatedAt: limit.updatedAt,
          ),
        );
  }

  @override
  Future<void> deleteLimit(String packageName) async {
    await (_database.delete(
      _database.timeLimits,
    )..where((t) => t.packageName.equals(packageName))).go();
    await (_database.delete(
      _database.limitNotificationState,
    )..where((s) => s.packageName.equals(packageName))).go();
  }

  @override
  Future<void> checkAndNotifyThresholds() async {
    final limits = await getAllLimits();
    if (limits.isEmpty) return;

    final usage = await _usageRepository.getTodayUsage();
    final usageByPackage = {for (final app in usage) app.packageName: app};
    final today = _startOfDay(DateTime.now());

    for (final limit in limits) {
      final app = usageByPackage[limit.packageName];
      if (app == null) continue;
      if (limit.dailyLimitMinutes <= 0) continue;

      final limitSeconds = limit.dailyLimitMinutes * 60;
      final percent = app.totalTime.inSeconds / limitSeconds * 100;

      final state = await _getState(limit.packageName);
      var newAt80 = state?.lastNotifiedAt80Date;
      var newAt100 = state?.lastNotifiedAt100Date;
      var didNotify = false;

      if (limit.notifyAt80 &&
          percent >= 80 &&
          !_isSameDay(state?.lastNotifiedAt80Date, today)) {
        await _notificationService.showThresholdNotification(
          packageName: limit.packageName,
          appName: app.appName,
          percent: 80,
          limitMinutes: limit.dailyLimitMinutes,
        );
        newAt80 = today;
        didNotify = true;
      }

      if (limit.notifyAt100 &&
          percent >= 100 &&
          !_isSameDay(state?.lastNotifiedAt100Date, today)) {
        await _notificationService.showThresholdNotification(
          packageName: limit.packageName,
          appName: app.appName,
          percent: 100,
          limitMinutes: limit.dailyLimitMinutes,
        );
        newAt100 = today;
        didNotify = true;
      }

      if (didNotify) {
        await _database
            .into(_database.limitNotificationState)
            .insertOnConflictUpdate(
              LimitNotificationStateCompanion.insert(
                packageName: limit.packageName,
                lastNotifiedAt80Date: Value(newAt80),
                lastNotifiedAt100Date: Value(newAt100),
              ),
            );
      }
    }
  }

  Future<LimitNotificationStateRow?> _getState(String packageName) {
    return (_database.select(
      _database.limitNotificationState,
    )..where((s) => s.packageName.equals(packageName))).getSingleOrNull();
  }

  static bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  static TimeLimit _toDomain(TimeLimitRow row) {
    return TimeLimit(
      packageName: row.packageName,
      dailyLimitMinutes: row.dailyLimitMinutes,
      notifyAt80: row.notifyAt80,
      notifyAt100: row.notifyAt100,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
