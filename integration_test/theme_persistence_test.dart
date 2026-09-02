import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app_usage_tracker/app.dart';
import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/core/theme/app_theme_variant.dart';
import 'package:flutter_app_usage_tracker/core/theme/theme_provider.dart';
import 'package:flutter_app_usage_tracker/data/services/usage_stats_service.dart';

/// Bypasses the real Usage Access permission gate so this test only
/// depends on the thing it's actually verifying — SharedPreferences-backed
/// theme persistence — not on the device's permission state (covered
/// separately by onboarding_flow_test.dart).
class _AlwaysGrantedUsageStatsService extends UsageStatsService {
  @override
  Future<bool> checkPermission() async => true;
}

AppThemeVariant _currentVariant(WidgetTester tester) {
  final context = tester.element(find.byType(App));
  return ProviderScope.containerOf(context).read(themeProvider);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a theme chosen in Settings survives an app relaunch', (
    tester,
  ) async {
    final overrides = [
      usageStatsServiceProvider.overrideWithValue(
        _AlwaysGrantedUsageStatsService(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const App()),
    );
    await tester.pumpAndSettle();
    expect(_currentVariant(tester), AppThemeVariant.materialFlow);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Night Focus'), findsOneWidget);
    await tester.tap(find.text('Night Focus'));
    await tester.pumpAndSettle();
    expect(_currentVariant(tester), AppThemeVariant.nightFocus);

    // Give the fire-and-forget SharedPreferences write a moment to land
    // on disk before "relaunching".
    await tester.pump(const Duration(milliseconds: 300));

    // integration_test runs the whole suite in one long-lived process,
    // so there's no framework API to kill and restart the real app.
    // The idiomatic stand-in is remounting under a fresh ProviderScope:
    // that constructs a brand new ProviderContainer (and ThemeNotifier)
    // exactly as a real relaunch would, while reading back the *same*
    // on-device SharedPreferences store — which is the thing actually
    // under test here, not the in-memory provider.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const App()),
    );
    await tester.pumpAndSettle();

    // Restoration reads SharedPreferences asynchronously right after
    // build(), so the very first frame may still show the default —
    // pumpAndSettle above already waits it out, but poll briefly as a
    // safety margin against timing flakiness.
    var variant = _currentVariant(tester);
    for (var i = 0; i < 10 && variant != AppThemeVariant.nightFocus; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      variant = _currentVariant(tester);
    }

    expect(
      variant,
      AppThemeVariant.nightFocus,
      reason:
          'The theme persisted before "relaunch" should still be active '
          'after a fresh ProviderContainer restores it from disk.',
    );

    // And the UI actually reflects it too, not just the provider state.
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Night Focus'), findsOneWidget);
  });
}
