import '../../domain/models/app_usage_info.dart';
import '../local/database.dart';
import '../services/app_info_resolver.dart';
import '../services/usage_stats_service.dart';

/// Foreground time below this is noise (e.g. a notification tap that
/// briefly focused an app) rather than meaningful usage.
const minTrackedUsageSeconds = 10;

abstract class UsageRepository {
  /// Today's per-app foreground usage, sorted by time spent descending.
  Future<List<AppUsageInfo>> getTodayUsage();

  /// Total foreground time across all tracked apps on [date].
  Future<Duration> getTotalForDate(DateTime date);
}

class UsageRepositoryImpl implements UsageRepository {
  final UsageStatsService _usageStatsService;
  final AppInfoResolver _appInfoResolver;
  final AppDatabase _database;

  UsageRepositoryImpl({
    required UsageStatsService usageStatsService,
    required AppInfoResolver appInfoResolver,
    required AppDatabase database,
  }) : _usageStatsService = usageStatsService,
       _appInfoResolver = appInfoResolver,
       _database = database;

  @override
  Future<List<AppUsageInfo>> getTodayUsage() async {
    final now = DateTime.now();
    final startOfDay = _startOfDay(now);
    final usage = await _resolveFilteredUsage(startOfDay, now);

    for (final app in usage) {
      await _database
          .into(_database.appUsageRecords)
          .insertOnConflictUpdate(
            AppUsageRecordsCompanion.insert(
              packageName: app.packageName,
              date: startOfDay,
              totalSeconds: app.totalTimeToday.inSeconds,
              lastSynced: now,
            ),
          );
    }

    usage.sort((a, b) => b.totalTimeToday.compareTo(a.totalTimeToday));
    return usage;
  }

  @override
  Future<Duration> getTotalForDate(DateTime date) async {
    final startOfDay = _startOfDay(date);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final usage = await _resolveFilteredUsage(startOfDay, endOfDay);
    return usage.fold<Duration>(
      Duration.zero,
      (total, app) => total + app.totalTimeToday,
    );
  }

  /// Queries raw usage for [start, end), resolves each package's app info,
  /// and drops noise, system, and non-launchable packages. Does not persist
  /// anything — callers decide whether the range represents "today".
  Future<List<AppUsageInfo>> _resolveFilteredUsage(
    DateTime start,
    DateTime end,
  ) async {
    final rawUsage = await _usageStatsService.queryUsageForRange(start, end);

    final result = <AppUsageInfo>[];
    for (final entry in rawUsage.entries) {
      final packageName = entry.key;
      final seconds = entry.value;
      if (seconds < minTrackedUsageSeconds) continue;

      final appInfo = await _appInfoResolver.resolve(packageName);
      if (appInfo == null) continue;
      if (appInfo.isSystemApp || !appInfo.isLaunchableApp) continue;

      result.add(
        AppUsageInfo(
          packageName: packageName,
          appName: appInfo.name,
          iconBytes: appInfo.icon,
          totalTimeToday: Duration(seconds: seconds),
        ),
      );
    }
    return result;
  }

  static DateTime _startOfDay(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
