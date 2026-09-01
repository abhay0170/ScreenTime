import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/providers.dart';

/// Whether limit threshold notifications are enabled — the UI-facing
/// counterpart to SettingsService, which LimitsRepositoryImpl reads
/// directly (it isn't always running inside a ProviderContainer, e.g. the
/// background isolate). Mirrors ThemeNotifier's restore-then-write shape.
class NotificationPreferenceNotifier extends Notifier<bool> {
  @override
  bool build() {
    _restore();
    return true;
  }

  Future<void> _restore() async {
    final enabled = await ref
        .read(settingsServiceProvider)
        .isThresholdNotificationsEnabled();
    state = enabled;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref
        .read(settingsServiceProvider)
        .setThresholdNotificationsEnabled(enabled);
  }
}

final notificationPreferenceProvider =
    NotifierProvider<NotificationPreferenceNotifier, bool>(
      NotificationPreferenceNotifier.new,
    );
