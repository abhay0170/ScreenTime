import 'package:home_widget/home_widget.dart';

import '../../core/utils/duration_formatter.dart';
import '../../domain/models/app_usage_info.dart';
import '../../domain/models/time_limit.dart';
import 'widget_config_service.dart';

const _totalTimeKey = 'today_overview_total_time';
const _topAppNameKey = 'today_overview_top_app_name';

/// The native AppWidgetProviders live in the `widgets` sub-package (see
/// android/.../widgets/*.kt). HomeWidget.updateWidget resolves `name` as
/// `<applicationId>.<name>`, so the sub-package must be included here —
/// passing just the bare class name would resolve to a nonexistent
/// top-level class and fail with a silent ClassNotFoundException on the
/// native side. getActiveWidgetIds (our own channel) uses the same
/// convention for consistency.
const _todayOverviewProviderName = 'widgets.TodayOverviewWidgetProvider';
const _appUsageProviderName = 'widgets.AppUsageWidgetProvider';
const _limitCountdownProviderName = 'widgets.LimitCountdownWidgetProvider';

/// Pushes data to the native home screen widgets and asks Android to
/// refresh them immediately, on top of their own ~30 minute automatic
/// update cycle.
class WidgetService {
  final WidgetConfigService _configService;

  WidgetService({WidgetConfigService? configService})
    : _configService = configService ?? WidgetConfigService();

  Future<void> updateTodayOverviewWidget(
    String formattedTotal,
    String topAppName,
  ) async {
    await HomeWidget.saveWidgetData<String>(_totalTimeKey, formattedTotal);
    await HomeWidget.saveWidgetData<String>(_topAppNameKey, topAppName);
    await HomeWidget.updateWidget(name: _todayOverviewProviderName);
  }

  /// Refreshes every placed App Usage widget instance with its selected
  /// app's current name/icon/today's usage, sourced from [usage].
  Future<void> updateAppUsageWidgets(List<AppUsageInfo> usage) async {
    final ids = await _configService.getActiveWidgetIds(_appUsageProviderName);
    if (ids.isEmpty) return;

    final usageByPackage = {for (final app in usage) app.packageName: app};

    for (final id in ids) {
      // Written natively by WidgetConfigChannel.completeConfiguration when
      // this instance was placed.
      final packageName = await HomeWidget.getWidgetData<String>(
        'app_usage_widget_$id',
      );
      if (packageName == null) continue;

      final app = usageByPackage[packageName];
      await HomeWidget.saveWidgetData<String>(
        'app_usage_widget_${id}_name',
        app?.appName ?? packageName,
      );
      await HomeWidget.saveWidgetData<String>(
        'app_usage_widget_${id}_usage',
        formatDuration(app?.totalTime ?? Duration.zero),
      );

      final iconBytes = app?.iconBytes;
      if (iconBytes != null) {
        await HomeWidget.saveFile(
          'app_usage_widget_${id}_icon',
          iconBytes,
          extension: 'png',
        );
      }
    }

    await HomeWidget.updateWidget(name: _appUsageProviderName);
  }

  /// Refreshes every placed Limit Countdown widget instance with a fresh
  /// countdown base for its selected app's limit, given [usage] and
  /// [limits]. Call whenever either changes: a new day resetting usage,
  /// the periodic sync, or the user editing the limit.
  Future<void> updateLimitCountdownWidgets(
    List<AppUsageInfo> usage,
    List<TimeLimit> limits,
  ) async {
    final ids = await _configService.getActiveWidgetIds(
      _limitCountdownProviderName,
    );
    if (ids.isEmpty) return;

    final usageByPackage = {for (final app in usage) app.packageName: app};
    final limitByPackage = {
      for (final limit in limits) limit.packageName: limit,
    };

    for (final id in ids) {
      final packageName = await HomeWidget.getWidgetData<String>(
        'limit_countdown_widget_$id',
      );
      if (packageName == null) continue;

      final appName = usageByPackage[packageName]?.appName ?? packageName;
      await HomeWidget.saveWidgetData<String>(
        'limit_countdown_widget_${id}_name',
        appName,
      );

      final limit = limitByPackage[packageName];
      if (limit == null) {
        // Clears the key so the provider shows its "no limit" state.
        await HomeWidget.saveWidgetData<String>(
          'limit_countdown_widget_${id}_remaining_ms',
          null,
        );
        continue;
      }

      final used = usageByPackage[packageName]?.totalTime ?? Duration.zero;
      final remaining = Duration(minutes: limit.dailyLimitMinutes) - used;
      final remainingMs = remaining.isNegative ? 0 : remaining.inMilliseconds;
      await HomeWidget.saveWidgetData<String>(
        'limit_countdown_widget_${id}_remaining_ms',
        '$remainingMs',
      );
    }

    await HomeWidget.updateWidget(name: _limitCountdownProviderName);
  }
}
