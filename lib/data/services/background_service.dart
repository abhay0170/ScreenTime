import 'package:workmanager/workmanager.dart';

import '../../core/utils/duration_formatter.dart';
import '../local/database.dart';
import '../repositories/limits_repository.dart';
import '../repositories/usage_repository.dart';
import 'app_info_resolver.dart';
import 'notification_service.dart';
import 'settings_service.dart';
import 'usage_stats_service.dart';
import 'widget_service.dart';

const limitsCheckTaskName = 'checkLimitThresholds';
const _limitsCheckUniqueName = 'checkLimitThresholds-periodic';

/// WorkManager's minimum periodic interval — shorter durations are clamped
/// (or rejected) by Android.
const backgroundCheckInterval = Duration(minutes: 15);

/// Runs in a separate background isolate that WorkManager spawns to invoke
/// scheduled tasks. Must be a top-level function (or static method) and
/// annotated `@pragma('vm:entry-point')` so it survives tree-shaking in
/// release builds, since Android calls it directly rather than through the
/// normal Dart call graph.
///
/// Neither the UI isolate's Drift connection nor its
/// flutter_local_notifications instance carry across isolates: `AppDatabase()`
/// opens a brand new connection to the same on-disk database file, and
/// `NotificationService` re-initializes the plugin from scratch.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != limitsCheckTaskName) return true;

    final database = AppDatabase();
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();

      final usageRepository = UsageRepositoryImpl(
        usageStatsService: UsageStatsService(),
        appInfoResolver: AppInfoResolver(),
        database: database,
      );
      final limitsRepository = LimitsRepositoryImpl(
        database: database,
        usageRepository: usageRepository,
        appInfoResolver: AppInfoResolver(),
        notificationService: notificationService,
        settingsService: SettingsService(),
      );

      // Fetched once and reused for the threshold check and all three
      // widget updates, rather than querying usage_stats twice.
      final usage = await usageRepository.getTodayUsage();
      await limitsRepository.checkAndNotifyThresholds(usage: usage);

      final total = usage.fold<Duration>(
        Duration.zero,
        (sum, app) => sum + app.totalTime,
      );
      final topAppName = usage.isEmpty ? 'No usage yet' : usage.first.appName;
      final widgetService = WidgetService();
      await widgetService.updateTodayOverviewWidget(
        formatDuration(total),
        topAppName,
      );
      await widgetService.updateAppUsageWidgets(usage);

      final limits = await limitsRepository.getAllLimits();
      await widgetService.updateLimitCountdownWidgets(usage, limits);

      return true;
    } finally {
      await database.close();
    }
  });
}

class BackgroundService {
  Future<void> initialize() {
    return Workmanager().initialize(callbackDispatcher);
  }

  Future<void> registerPeriodicLimitsCheck() {
    return Workmanager().registerPeriodicTask(
      _limitsCheckUniqueName,
      limitsCheckTaskName,
      frequency: backgroundCheckInterval,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
