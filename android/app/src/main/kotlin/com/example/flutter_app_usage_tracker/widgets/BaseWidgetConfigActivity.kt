package com.example.flutter_app_usage_tracker.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Base for the two widget configuration activities Android launches when a
 * user drags a configurable widget onto their home screen (declared via
 * android:configure in each widget's info XML, e.g. app_usage_widget_info.xml).
 * Android won't finish placing the widget until this activity calls
 * setResult(RESULT_OK) and finish() — see
 * WidgetConfigChannel.completeConfiguration, invoked from the Flutter
 * config screen (lib/.../widget_config_screen.dart) this activity shows.
 *
 * This is a plain FlutterActivity with its own fresh engine, the same way
 * MainActivity works — deliberately not a second cached/shared engine, to
 * keep this simple.
 */
abstract class BaseWidgetConfigActivity : FlutterActivity() {

  /** e.g. "app_usage" or "limit_countdown" — matches WidgetConfigChannel. */
  protected abstract val mode: String

  private var appWidgetId: Int = AppWidgetManager.INVALID_APPWIDGET_ID

  override fun onCreate(savedInstanceState: Bundle?) {
    appWidgetId =
        intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

    // Default to canceled, per Android convention — covers the user
    // backing out without finishing configuration. Overwritten with
    // RESULT_OK by WidgetConfigChannel.completeConfiguration on success.
    setResult(
        Activity.RESULT_CANCELED,
        Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
    )

    super.onCreate(savedInstanceState)

    if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
      finish()
    }
  }

  override fun getInitialRoute(): String {
    return "/widget-config?mode=$mode&appWidgetId=$appWidgetId"
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    WidgetConfigChannel.register(
        activity = this,
        flutterEngine = flutterEngine,
        appWidgetId = appWidgetId,
        configuringMode = mode,
    )
  }
}
