package com.example.flutter_app_usage_tracker.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.flutter_app_usage_tracker.MainActivity
import com.example.flutter_app_usage_tracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the "Today Overview" home screen widget from data written by
 * Dart's WidgetService (via home_widget's saveWidgetData), which lands in
 * the same SharedPreferences store [widgetData] reads here.
 *
 * Key names must match lib/data/services/widget_service.dart exactly.
 */
class TodayOverviewWidgetProvider : HomeWidgetProvider() {

  companion object {
    private const val KEY_TOTAL_TIME = "today_overview_total_time"
    private const val KEY_TOP_APP_NAME = "today_overview_top_app_name"
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.today_overview_widget).apply {
            setTextViewText(
                R.id.widget_total_time,
                widgetData.getString(KEY_TOTAL_TIME, null) ?: "0m",
            )
            setTextViewText(
                R.id.widget_top_app_label,
                widgetData.getString(KEY_TOP_APP_NAME, null) ?: "No usage yet",
            )

            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_container, pendingIntent)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
