import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/repositories/usage_repository.dart';
import '../../data/services/app_info_resolver.dart';
import '../../data/services/usage_stats_service.dart';
import '../../domain/models/app_usage_info.dart';

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

final usageRepositoryProvider = Provider<UsageRepository>((ref) {
  return UsageRepositoryImpl(
    usageStatsService: ref.watch(usageStatsServiceProvider),
    appInfoResolver: ref.watch(appInfoResolverProvider),
    database: ref.watch(appDatabaseProvider),
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
/// the Today screen. Empty until the Limits feature lets users set any.
final activeTimeLimitsProvider = FutureProvider.autoDispose<List<TimeLimitRow>>(
  (ref) {
    final database = ref.watch(appDatabaseProvider);
    return database.select(database.timeLimits).get();
  },
);
