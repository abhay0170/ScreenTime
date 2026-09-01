import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/duration_formatter.dart';

const _channelId = 'limit_alerts';
const _channelName = 'Limit alerts';
const _channelDescription =
    'Notifications when an app nears or reaches its daily limit.';

/// Wraps flutter_local_notifications for the app's one notification use
/// case: threshold alerts. A fresh instance must be created (and
/// [initialize]d) per isolate — the plugin doesn't carry across isolates,
/// which matters for the WorkManager background isolate.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);

    await _androidPlugin()?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Requests POST_NOTIFICATIONS on Android 13+. No-op (returns null) on
  /// versions that don't need it.
  Future<bool?> requestPermission() async {
    return await _androidPlugin()?.requestNotificationsPermission();
  }

  Future<void> showThresholdNotification({
    required String packageName,
    required String appName,
    required int percent,
    required int limitMinutes,
  }) async {
    final limitLabel = formatDuration(Duration(minutes: limitMinutes));
    final title = percent >= 100
        ? 'Daily limit reached'
        : 'Approaching daily limit';
    final body = percent >= 100
        ? '$appName has reached its daily limit.'
        : '$appName is at $percent% of its $limitLabel limit.';

    await _plugin.show(
      // Stable per-app id so a later threshold notification (e.g. 100%)
      // replaces an earlier one (e.g. 80%) instead of stacking.
      id: packageName.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? _androidPlugin() {
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }
}
