import 'package:flutter/services.dart';

const _channelName = 'com.example.flutter_app_usage_tracker/widget_config';

/// Wraps the app's own MethodChannel used for widget configuration —
/// distinct from home_widget's built-in channel. Two things it does that
/// home_widget doesn't:
///
/// - Hands control back to the native widget configuration Activity once
///   the user picks an app in the Flutter config screen (see
///   android/.../widgets/WidgetConfigChannel.kt and
///   BaseWidgetConfigActivity). Android won't finish placing a
///   configurable widget until that Activity calls setResult+finish, and
///   Flutter code can't do that directly.
/// - Discovers which widget instances are currently placed
///   (getAppWidgetIds isn't otherwise exposed to Dart), so the app knows
///   which instances to push data for.
class WidgetConfigService {
  final MethodChannel _channel;

  WidgetConfigService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  Future<void> completeConfiguration({
    required int appWidgetId,
    required String selectedValue,
  }) {
    return _channel.invokeMethod<void>('completeConfiguration', {
      'appWidgetId': appWidgetId,
      'selectedValue': selectedValue,
    });
  }

  /// [providerName] uses the same short form as the calls WidgetService
  /// makes via HomeWidget.updateWidget, e.g. 'widgets.AppUsageWidgetProvider'.
  Future<List<int>> getActiveWidgetIds(String providerName) async {
    final ids = await _channel.invokeListMethod<int>('getActiveWidgetIds', {
      'providerName': providerName,
    });
    return ids ?? const [];
  }
}
