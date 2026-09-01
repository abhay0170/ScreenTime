import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';

import '../../data/local/database.dart';
import '../../data/repositories/limits_repository.dart';
import '../../data/repositories/trends_repository.dart';
import '../../data/repositories/usage_repository.dart';
import '../../data/services/app_info_resolver.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/usage_stats_service.dart';
import '../../data/services/widget_service.dart';
import '../../domain/models/app_usage_info.dart';
import '../../domain/models/daily_total.dart';
import '../../domain/models/limit_with_usage.dart';
import '../../domain/models/time_limit.dart';
import '../utils/duration_formatter.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final usageStatsServiceProvider = Provider<UsageStatsService>((ref) {
  return UsageStatsService();
});

final appInfoResolverProvider = Provider<AppInfoResolver>((ref) {
  return AppInfoResolver();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  // Fire-and-forget: creates the Android notification channel and readies
  // the plugin. Providers must build synchronously, so this isn't awaited.
  service.initialize();
  return service;
});

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepositoryImpl(
    usageStatsService: ref.watch(usageStatsServiceProvider),
    appInfoResolver: ref.watch(appInfoResolverProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final limitsRepositoryProvider = Provider<LimitsRepository>((ref) {
  return LimitsRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    usageRepository: ref.watch(usageRepositoryProvider),
    appInfoResolver: ref.watch(appInfoResolverProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final trendsRepositoryProvider = Provider<TrendsRepository>((ref) {
  return TrendsRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    appInfoResolver: ref.watch(appInfoResolverProvider),
  );
});

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return WidgetService();
});

/// Today's real per-app usage, fetched (and upserted into Drift) on demand.
final todayUsageProvider = FutureProvider.autoDispose<List<AppUsageInfo>>((
  ref,
) {
  return ref.watch(usageRepositoryProvider).getTodayUsage();
});

/// Yesterday's total foreground time, for the "vs. yesterday" trend.
final yesterdayTotalProvider = FutureProvider.autoDispose<Duration>((ref) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return ref.watch(usageRepositoryProvider).getTotalForDate(yesterday);
});

/// All configured time limits, used to flag apps nearing their limit on
/// the Today screen. Empty until the user sets any on the Limits screen.
final allLimitsProvider = FutureProvider.autoDispose<List<TimeLimit>>((ref) {
  return ref.watch(limitsRepositoryProvider).getAllLimits();
});

/// Configured limits enriched with display info and today's usage, for the
/// Limits screen's "Active limits" section.
final limitsWithUsageProvider =
    FutureProvider.autoDispose<List<LimitWithUsage>>((ref) {
      return ref.watch(limitsRepositoryProvider).getLimitsWithUsage();
    });

/// The limit configured for one specific app, if any — used by App Detail.
final limitForPackageProvider = FutureProvider.autoDispose
    .family<TimeLimit?, String>((ref, packageName) {
      return ref
          .watch(limitsRepositoryProvider)
          .getLimitForPackage(packageName);
    });

/// Apps used today that don't have a limit yet — the pool the Add Limit
/// app picker and the Limits screen's "Other apps" section draw from.
final unlimitedTrackedAppsProvider =
    FutureProvider.autoDispose<List<AppUsageInfo>>((ref) async {
      final usage = await ref.watch(todayUsageProvider.future);
      final limits = await ref.watch(allLimitsProvider.future);
      final limitedPackages = limits.map((limit) => limit.packageName).toSet();
      return usage
          .where((app) => !limitedPackages.contains(app.packageName))
          .toList();
    });

/// Runs the threshold check from the UI isolate whenever today's usage is
/// (re)loaded, so limit feedback feels responsive while actively using the
/// app rather than waiting on the ~15 minute background cadence. Reuses
/// the usage already fetched by [todayUsageProvider] instead of querying
/// usage_stats again.
final thresholdCheckProvider = FutureProvider.autoDispose<void>((ref) async {
  final usage = await ref.watch(todayUsageProvider.future);
  await ref
      .read(limitsRepositoryProvider)
      .checkAndNotifyThresholds(usage: usage);
});

/// Pushes today's total and top app to the native "Today Overview" home
/// screen widget whenever usage is (re)loaded, so the widget stays fresh
/// while the app is open (the background task covers the rest of the
/// time). Reuses the same usage as [thresholdCheckProvider].
final todayOverviewWidgetSyncProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  final usage = await ref.watch(todayUsageProvider.future);
  final total = usage.fold<Duration>(
    Duration.zero,
    (sum, app) => sum + app.totalTime,
  );
  final topAppName = usage.isEmpty ? 'No usage yet' : usage.first.appName;
  await ref
      .read(widgetServiceProvider)
      .updateTodayOverviewWidget(formatDuration(total), topAppName);
});

/// A named recent date range, resolved to `[start, end)` at read time so
/// "today" always means the actual current day.
enum TrendsRange {
  weekly(7),
  monthly(30);

  const TrendsRange(this.days);

  final int days;

  (DateTime start, DateTime end) resolve() {
    final now = DateTime.now();
    final endExclusive = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    return (endExclusive.subtract(Duration(days: days)), endExclusive);
  }
}

/// Daily totals for the Trends chart, over the selected range.
final dailyTotalsProvider = FutureProvider.autoDispose
    .family<List<DailyTotal>, TrendsRange>((ref, range) {
      final (start, end) = range.resolve();
      return ref.watch(trendsRepositoryProvider).getDailyTotals(start, end);
    });

/// Per-app totals for the Trends ranked list, over the selected range.
final topAppsForRangeProvider = FutureProvider.autoDispose
    .family<List<AppUsageInfo>, TrendsRange>((ref, range) {
      final (start, end) = range.resolve();
      return ref.watch(trendsRepositoryProvider).getTopAppsForRange(start, end);
    });

/// The last 7 days of usage for one app, for App Detail's chart.
final appDetailDailyTotalsProvider = FutureProvider.autoDispose
    .family<List<DailyTotal>, String>((ref, packageName) {
      final (start, end) = TrendsRange.weekly.resolve();
      return ref
          .watch(trendsRepositoryProvider)
          .getDailyTotalsForApp(packageName, start, end);
    });

/// Resolves a package's display name/icon directly, regardless of whether
/// it shows up in today's usage — needed by App Detail when opened from a
/// Trends entry for an app that wasn't used today.
final appInfoForPackageProvider = FutureProvider.autoDispose
    .family<AppInfo?, String>((ref, packageName) {
      return ref.watch(appInfoResolverProvider).resolve(packageName);
    });
