package com.example.flutter_app_usage_tracker

import com.example.flutter_app_usage_tracker.widgets.WidgetConfigChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Only getActiveWidgetIds is meaningful here (the running app, not a
    // widget configuration activity) — completeConfiguration errors out
    // gracefully if ever called from this context.
    WidgetConfigChannel.register(activity = this, flutterEngine = flutterEngine)
  }
}
