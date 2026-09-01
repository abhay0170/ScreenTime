import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme_variant.dart';

const _themeVariantPrefsKey = 'app_theme_variant';

class ThemeNotifier extends Notifier<AppThemeVariant> {
  @override
  AppThemeVariant build() {
    _restore();
    return AppThemeVariant.materialFlow;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString(_themeVariantPrefsKey);
    if (storedName == null) return;

    for (final variant in AppThemeVariant.values) {
      if (variant.name == storedName) {
        state = variant;
        return;
      }
    }
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    state = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeVariantPrefsKey, variant.name);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeVariant>(
  ThemeNotifier.new,
);
