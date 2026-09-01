package com.example.flutter_app_usage_tracker.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import com.example.flutter_app_usage_tracker.MainActivity
import com.example.flutter_app_usage_tracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the "App Usage" home screen widget for whichever app the user
 * picked in AppUsageWidgetConfigActivity. Each widget instance
 * (appWidgetId) tracks its own selected app, so data keys are namespaced
 * per id: `app_usage_widget_<id>` holds the selected package name
 * (written natively at configure time via WidgetConfigChannel);
 * `app_usage_widget_<id>_name` / `_usage` / `_icon` hold the display data
 * Dart pushes on each sync. Key names must match
 * lib/data/services/widget_service.dart exactly.
 */
class AppUsageWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.app_usage_widget).apply {
            setTextViewText(
                R.id.widget_app_name,
                widgetData.getString("app_usage_widget_${widgetId}_name", null)
                    ?: "Syncing…",
            )
            setTextViewText(
                R.id.widget_app_usage,
                widgetData.getString("app_usage_widget_${widgetId}_usage", null) ?: "0m",
            )

            val iconPath = widgetData.getString("app_usage_widget_${widgetId}_icon", null)
            val bitmap = iconPath?.let { BitmapFactory.decodeFile(it) }
            if (bitmap != null) {
              setImageViewBitmap(R.id.widget_app_icon, bitmap)
              setViewVisibility(R.id.widget_app_icon, View.VISIBLE)
            } else {
              setViewVisibility(R.id.widget_app_icon, View.GONE)
            }

            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_container, pendingIntent)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
