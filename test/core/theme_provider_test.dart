import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app_usage_tracker/core/theme/app_theme_variant.dart';
import 'package:flutter_app_usage_tracker/core/theme/theme_provider.dart';

const _prefsKey = 'app_theme_variant';

void main() {
  test('build() defaults to Material Flow when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferences.getInstance();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeProvider), AppThemeVariant.materialFlow);
  });

  test('restores the previously persisted theme on startup', () async {
    SharedPreferences.setMockInitialValues({
      _prefsKey: AppThemeVariant.nightFocus.name,
    });
    await SharedPreferences.getInstance();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // build() must return synchronously, so it starts on the default and
    // restoration from disk happens asynchronously right after.
    expect(container.read(themeProvider), AppThemeVariant.materialFlow);

    final restored = Completer<void>();
    final sub = container.listen(themeProvider, (previous, next) {
      if (next == AppThemeVariant.nightFocus) restored.complete();
    });
    addTearDown(sub.close);

    await restored.future.timeout(const Duration(seconds: 2));
    expect(container.read(themeProvider), AppThemeVariant.nightFocus);
  });

  test('ignores an unrecognized stored value and keeps the default', () async {
    SharedPreferences.setMockInitialValues({_prefsKey: 'not_a_real_variant'});
    await SharedPreferences.getInstance();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Give the fire-and-forget restore a chance to run; since nothing
    // matches, state should never move off the default.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(container.read(themeProvider), AppThemeVariant.materialFlow);
  });

  test('setVariant updates state and persists the choice to disk', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(themeProvider.notifier)
        .setVariant(AppThemeVariant.calmBalance);

    expect(container.read(themeProvider), AppThemeVariant.calmBalance);
    expect(prefs.getString(_prefsKey), AppThemeVariant.calmBalance.name);
  });

  test(
    'a variant persisted by setVariant is what a fresh container restores',
    () async {
      SharedPreferences.setMockInitialValues({});
      await SharedPreferences.getInstance();

      final first = ProviderContainer();
      await first
          .read(themeProvider.notifier)
          .setVariant(AppThemeVariant.nightFocus);
      first.dispose();

      // A new container simulates a fresh app launch reading the same
      // on-disk SharedPreferences store.
      final second = ProviderContainer();
      addTearDown(second.dispose);

      final restored = Completer<void>();
      final sub = second.listen(themeProvider, (previous, next) {
        if (next == AppThemeVariant.nightFocus) restored.complete();
      });
      addTearDown(sub.close);

      await restored.future.timeout(const Duration(seconds: 2));
      expect(second.read(themeProvider), AppThemeVariant.nightFocus);
    },
  );
}
