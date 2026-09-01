import 'package:drift/drift.dart';

import '../../domain/models/app_usage_info.dart';
import '../../domain/models/daily_total.dart';
import '../local/database.dart';
import '../services/app_info_resolver.dart';

/// Historical trend data, read entirely from the local Drift cache
/// (AppUsageRecords) rather than a live usage_stats query.
///
/// Android's UsageStatsManager query window is unreliable for anything
/// beyond roughly the last week and varies by OS/OEM. AppUsageRecords is
/// upserted with real daily totals every time usage is queried (from the
/// Today screen and the periodic background check), so it accumulates
/// genuine historical coverage from whenever the app was first installed
/// — including days it wasn't manually opened.
abstract class TrendsRepository {
  /// Total screen time per day in `[start, end)` across all tracked apps.
  /// Includes an entry (possibly zero) for every day in the range.
  Future<List<DailyTotal>> getDailyTotals(DateTime start, DateTime end);

  /// Per-app totals summed across `[start, end)`, sorted descending.
  Future<List<AppUsageInfo>> getTopAppsForRange(DateTime start, DateTime end);

  /// Same as [getDailyTotals], scoped to a single app.
  Future<List<DailyTotal>> getDailyTotalsForApp(
    String packageName,
    DateTime start,
    DateTime end,
  );
}

class TrendsRepositoryImpl implements TrendsRepository {
  final AppDatabase _database;
  final AppInfoResolver _appInfoResolver;

  TrendsRepositoryImpl({
    required AppDatabase database,
    required AppInfoResolver appInfoResolver,
  }) : _database = database,
       _appInfoResolver = appInfoResolver;

  @override
  Future<List<DailyTotal>> getDailyTotals(DateTime start, DateTime end) {
    return _dailyTotals(start, end, packageName: null);
  }

  @override
  Future<List<DailyTotal>> getDailyTotalsForApp(
    String packageName,
    DateTime start,
    DateTime end,
  ) {
    return _dailyTotals(start, end, packageName: packageName);
  }

  Future<List<DailyTotal>> _dailyTotals(
    DateTime start,
    DateTime end, {
    required String? packageName,
  }) async {
    final records = _database.appUsageRecords;
    final totalSecondsSum = records.totalSeconds.sum();

    final query = _database.selectOnly(records)
      ..addColumns([records.date, totalSecondsSum])
      ..where(
        records.date.isBiggerOrEqualValue(start) &
            records.date.isSmallerThanValue(end),
      )
      ..groupBy([records.date]);

    if (packageName != null) {
      query.where(records.packageName.equals(packageName));
    }

    final rows = await query.get();
    final totalsByDate = <DateTime, int>{
      for (final row in rows)
        _dateOnly(row.read(records.date)!): row.read(totalSecondsSum) ?? 0,
    };

    // Fill in every day in the range, even ones with no usage, so the
    // chart always shows a full week/month of bars.
    final days = <DailyTotal>[];
    for (
      var day = _dateOnly(start);
      day.isBefore(end);
      day = day.add(const Duration(days: 1))
    ) {
      days.add(
        DailyTotal(
          date: day,
          total: Duration(seconds: totalsByDate[day] ?? 0),
        ),
      );
    }
    return days;
  }

  @override
  Future<List<AppUsageInfo>> getTopAppsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final records = _database.appUsageRecords;
    final totalSecondsSum = records.totalSeconds.sum();

    final query = _database.selectOnly(records)
      ..addColumns([records.packageName, totalSecondsSum])
      ..where(
        records.date.isBiggerOrEqualValue(start) &
            records.date.isSmallerThanValue(end),
      )
      ..groupBy([records.packageName])
      ..orderBy([OrderingTerm.desc(totalSecondsSum)]);

    final rows = await query.get();

    final result = <AppUsageInfo>[];
    for (final row in rows) {
      final packageName = row.read(records.packageName)!;
      final totalSeconds = row.read(totalSecondsSum) ?? 0;
      if (totalSeconds <= 0) continue;

      // Skip apps that no longer resolve (e.g. uninstalled since then) —
      // there's no name/icon left to show for them.
      final appInfo = await _appInfoResolver.resolve(packageName);
      if (appInfo == null) continue;

      result.add(
        AppUsageInfo(
          packageName: packageName,
          appName: appInfo.name,
          iconBytes: appInfo.icon,
          totalTime: Duration(seconds: totalSeconds),
        ),
      );
    }
    return result;
  }

  static DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
