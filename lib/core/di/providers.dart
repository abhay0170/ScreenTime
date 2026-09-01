import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/repositories/limits_repository.dart';
import '../../data/repositories/usage_repository.dart';
import '../../data/services/app_info_resolver.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/usage_stats_service.dart';
import '../../domain/models/app_usage_info.dart';
import '../../domain/models/limit_with_usage.dart';
import '../../domain/models/time_limit.dart';

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
/// app rather than waiting on the ~15 minute background cadence.
final thresholdCheckProvider = FutureProvider.autoDispose<void>((ref) async {
  await ref.watch(todayUsageProvider.future);
  await ref.read(limitsRepositoryProvider).checkAndNotifyThresholds();
});
