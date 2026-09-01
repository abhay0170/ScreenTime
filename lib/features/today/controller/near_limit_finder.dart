import '../../../data/local/database.dart';
import '../../../domain/models/app_usage_info.dart';

/// Apps whose remaining time before hitting their daily limit is at or
/// below [threshold]. Returns an empty list when no limits are configured
/// yet, which is expected until the Limits feature exists.
List<AppUsageInfo> findNearLimitApps(
  List<AppUsageInfo> usage,
  List<TimeLimitRow> limits, {
  Duration threshold = const Duration(minutes: 15),
}) {
  final nearLimit = <AppUsageInfo>[];

  for (final limit in limits) {
    AppUsageInfo? app;
    for (final candidate in usage) {
      if (candidate.packageName == limit.packageName) {
        app = candidate;
        break;
      }
    }
    if (app == null) continue;

    final remaining =
        Duration(minutes: limit.dailyLimitMinutes) - app.totalTimeToday;
    if (remaining <= threshold) {
      nearLimit.add(app);
    }
  }

  return nearLimit;
}
