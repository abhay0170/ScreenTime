import 'package:usage_stats/usage_stats.dart';

/// Per-package foreground usage in seconds, keyed by package name.
typedef PackageUsageSeconds = Map<String, int>;

/// Thin wrapper around the `usage_stats` plugin, which talks to Android's
/// UsageStatsManager over a method channel.
class UsageStatsService {
  Future<bool> checkPermission() async {
    final granted = await UsageStats.checkUsagePermission();
    return granted ?? false;
  }

  /// Opens Android's "Usage Access" settings screen for the user to grant
  /// the permission manually — there is no runtime prompt for this.
  Future<void> requestPermission() async {
    await UsageStats.grantUsagePermission();
  }

  /// Returns each package's total foreground time (in seconds) between
  /// [start] and [end], aggregated per package.
  Future<PackageUsageSeconds> queryUsageForRange(
    DateTime start,
    DateTime end,
  ) async {
    final aggregated = await UsageStats.queryAndAggregateUsageStats(start, end);

    final result = <String, int>{};
    for (final entry in aggregated.entries) {
      final packageName = entry.value.packageName;
      final millis = int.tryParse(entry.value.totalTimeInForeground ?? '');
      if (packageName == null || millis == null || millis <= 0) continue;
      result[packageName] = millis ~/ 1000;
    }
    return result;
  }
}
