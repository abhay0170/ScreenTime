package com.example.flutter_app_usage_tracker.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.example.flutter_app_usage_tracker.MainActivity
import com.example.flutter_app_usage_tracker.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the "Limit Countdown" home screen widget for whichever app the
 * user picked in LimitCountdownWidgetConfigActivity. Data keys are
 * namespaced per widget instance the same way as AppUsageWidgetProvider —
 * see that file and lib/data/services/widget_service.dart.
 *
 * `limit_countdown_widget_<id>_remaining_ms` holds the remaining
 * milliseconds as of Dart's last sync (a String, to avoid ambiguity
 * between SharedPreferences' int/long storage for values that may or may
 * not exceed 32 bits). The Chronometer's base is computed fresh from
 * SystemClock.elapsedRealtime() every time onUpdate runs; between syncs
 * it keeps ticking live via the widget host process, with no further
 * app-side updates needed.
 */
class LimitCountdownWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.limit_countdown_widget).apply {
            setTextViewText(
                R.id.widget_limit_app_name,
                widgetData.getString("limit_countdown_widget_${widgetId}_name", null)
                    ?: "Syncing…",
            )

            val remainingMs =
                widgetData
                    .getString("limit_countdown_widget_${widgetId}_remaining_ms", null)
                    ?.toLongOrNull()

            when {
              remainingMs == null -> showFallback(this, "No limit set")
              remainingMs <= 0L -> showFallback(this, "Limit reached")
              else -> {
                setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                setViewVisibility(R.id.widget_limit_fallback, View.GONE)
                val base = SystemClock.elapsedRealtime() + remainingMs
                setChronometer(R.id.widget_countdown, base, "%s", true)
                // API 24+ — this app's minSdkVersion is already 24.
                setChronometerCountDown(R.id.widget_countdown, true)
              }
            }

            val pendingIntent =
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_container, pendingIntent)
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun showFallback(views: RemoteViews, text: String) {
    views.setViewVisibility(R.id.widget_countdown, View.GONE)
    views.setViewVisibility(R.id.widget_limit_fallback, View.VISIBLE)
    views.setTextViewText(R.id.widget_limit_fallback, text)
  }
}
