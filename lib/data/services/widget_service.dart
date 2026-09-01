import 'package:home_widget/home_widget.dart';

const _totalTimeKey = 'today_overview_total_time';
const _topAppNameKey = 'today_overview_top_app_name';

/// The native AppWidgetProvider lives in the `widgets` sub-package (see
/// android/.../widgets/TodayOverviewWidgetProvider.kt). HomeWidget.updateWidget
/// resolves `name` as `<applicationId>.<name>`, so the sub-package must be
/// included here — passing just the bare class name would resolve to a
/// nonexistent top-level class and fail with a silent ClassNotFoundException
/// on the native side.
const _todayOverviewProviderName = 'widgets.TodayOverviewWidgetProvider';

/// Pushes data to the native "Today Overview" home screen widget and asks
/// Android to refresh it immediately, on top of its own ~30 minute
/// automatic update cycle.
class WidgetService {
  Future<void> updateTodayOverviewWidget(
    String formattedTotal,
    String topAppName,
  ) async {
    await HomeWidget.saveWidgetData<String>(_totalTimeKey, formattedTotal);
    await HomeWidget.saveWidgetData<String>(_topAppNameKey, topAppName);
    await HomeWidget.updateWidget(name: _todayOverviewProviderName);
  }
}
