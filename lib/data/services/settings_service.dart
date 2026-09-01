import 'package:shared_preferences/shared_preferences.dart';

const _thresholdNotificationsEnabledKey = 'threshold_notifications_enabled';

/// Wraps small app-wide preferences stored in SharedPreferences — the same
/// store the theme choice uses. A plain class (not a Riverpod Notifier) so
/// it can also be read directly from the WorkManager background isolate,
/// which has no running ProviderContainer — see LimitsRepositoryImpl,
/// which gates checkAndNotifyThresholds on this.
class SettingsService {
  Future<bool> isThresholdNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_thresholdNotificationsEnabledKey) ?? true;
  }

  Future<void> setThresholdNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_thresholdNotificationsEnabledKey, enabled);
  }
}
