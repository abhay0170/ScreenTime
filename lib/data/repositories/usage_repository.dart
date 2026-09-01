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
    final startOfDay = DateTime(now.year, now.month, now.day);

    final rawUsage = await _usageStatsService.queryUsageForRange(
      startOfDay,
      now,
    );

    final result = <AppUsageInfo>[];

    for (final entry in rawUsage.entries) {
      final packageName = entry.key;
      final seconds = entry.value;
      if (seconds < minTrackedUsageSeconds) continue;

      final appInfo = await _appInfoResolver.resolve(packageName);
      if (appInfo == null) continue;
      if (appInfo.isSystemApp || !appInfo.isLaunchableApp) continue;

      await _database
          .into(_database.appUsageRecords)
          .insertOnConflictUpdate(
            AppUsageRecordsCompanion.insert(
              packageName: packageName,
              date: startOfDay,
              totalSeconds: seconds,
              lastSynced: now,
            ),
          );

      result.add(
        AppUsageInfo(
          packageName: packageName,
          appName: appInfo.name,
          iconBytes: appInfo.icon,
          totalTimeToday: Duration(seconds: seconds),
        ),
      );
    }

    result.sort((a, b) => b.totalTimeToday.compareTo(a.totalTimeToday));
    return result;
  }
}
