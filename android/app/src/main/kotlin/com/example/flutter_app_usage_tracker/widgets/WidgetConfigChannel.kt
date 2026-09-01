package com.example.flutter_app_usage_tracker.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import es.antonborri.home_widget.HomeWidgetPlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Shared MethodChannel wiring for widget configuration. Registered by both
 * MainActivity — so the running app can discover which widget instances
 * are placed, to sync data for them — and BaseWidgetConfigActivity — so
 * the Flutter config screen it shows can hand control back to native code
 * to finish placing a widget.
 *
 * Key names written by [completeConfiguration] must match
 * lib/data/services/widget_service.dart exactly.
 */
object WidgetConfigChannel {
  const val NAME = "com.example.flutter_app_usage_tracker/widget_config"

  /**
   * Registers the channel on [flutterEngine]. [appWidgetId] and
   * [configuringMode] are only meaningful (non-default) when [activity] is
   * itself a widget configuration activity currently placing a widget —
   * that's what `completeConfiguration` operates on.
   */
  fun register(
      activity: Activity,
      flutterEngine: FlutterEngine,
      appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID,
      configuringMode: String? = null,
  ) {
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NAME).setMethodCallHandler {
        call,
        result ->
      when (call.method) {
        "completeConfiguration" -> {
          if (configuringMode == null ||
              appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            result.error(
                "NOT_CONFIGURING",
                "Not running inside a widget configuration activity",
                null,
            )
            return@setMethodCallHandler
          }

          val selectedValue = call.argument<String>("selectedValue")
          val prefs = HomeWidgetPlugin.getData(activity).edit()
          prefs.putString("${configuringMode}_widget_$appWidgetId", selectedValue)
          prefs.apply()

          val providerClass = providerClassFor(configuringMode)
          if (providerClass != null) {
            val updateIntent =
                Intent(activity, providerClass).apply {
                  action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                  putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
                }
            activity.sendBroadcast(updateIntent)
          }

          result.success(true)

          // Real usage/limit data for this widget is pushed by Dart's next
          // sync (WidgetService.updateAppUsageWidgets /
          // updateLimitCountdownWidgets) — see widget_service.dart.
          val resultIntent = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
          activity.setResult(Activity.RESULT_OK, resultIntent)
          activity.finish()
        }
        "getActiveWidgetIds" -> {
          val providerName = call.argument<String>("providerName")
          if (providerName == null) {
            result.error("MISSING_ARGUMENT", "providerName is required", null)
            return@setMethodCallHandler
          }
          try {
            val javaClass = Class.forName("${activity.packageName}.$providerName")
            val ids =
                AppWidgetManager.getInstance(activity.applicationContext)
                    .getAppWidgetIds(ComponentName(activity, javaClass))
            result.success(ids.toList())
          } catch (e: ClassNotFoundException) {
            result.error("NOT_FOUND", "No widget provider found for $providerName", null)
          }
        }
        else -> result.notImplemented()
      }
    }
  }

  private fun providerClassFor(mode: String): Class<*>? =
      when (mode) {
        "app_usage" -> AppUsageWidgetProvider::class.java
        "limit_countdown" -> LimitCountdownWidgetProvider::class.java
        else -> null
      }
}
