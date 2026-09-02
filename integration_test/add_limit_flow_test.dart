import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app_usage_tracker/app.dart';
import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/data/services/usage_stats_service.dart';

/// The app under test is always genuinely installed on whatever device runs
/// this test, so using its own package as the fake "used today" app gives
/// the real AppInfoResolver (installed_apps) a real, resolvable app to
/// work with — without depending on whatever else happens to have real
/// usage on this particular device/emulator.
const _selfPackageName = 'com.example.flutter_app_usage_tracker';

class _FakeUsageStatsService extends UsageStatsService {
  @override
  Future<bool> checkPermission() async => true;

  @override
  Future<PackageUsageSeconds> queryUsageForRange(
    DateTime start,
    DateTime end,
  ) async {
    return {_selfPackageName: 1800}; // 30 minutes.
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Add limit: pick an app, set a duration, save, and see it in Active '
    'limits',
    (tester) async {
      final overrides = [
        usageStatsServiceProvider.overrideWithValue(_FakeUsageStatsService()),
      ];

      await tester.pumpWidget(
        ProviderScope(overrides: overrides, child: const App()),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(App));
      final container = ProviderScope.containerOf(context);

      // Defensive cleanup in case a previous run of this test crashed
      // before its own tearDown ran and left a stale limit behind — that
      // would make the self-app disappear from the "unlimited" picker
      // below and fail this run for an unrelated reason.
      await container
          .read(limitsRepositoryProvider)
          .deleteLimit(_selfPackageName);
      addTearDown(
        () => container
            .read(limitsRepositoryProvider)
            .deleteLimit(_selfPackageName),
      );

      final selfAppInfo = await container
          .read(appInfoResolverProvider)
          .resolve(_selfPackageName);
      expect(
        selfAppInfo,
        isNotNull,
        reason:
            'The app under test must resolve its own installed app info '
            'for this test to have a real, deterministic app to pick.',
      );
      final selfAppName = selfAppInfo!.name;

      await tester.tap(find.text('Limits'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add limit'));
      await tester.pumpAndSettle();

      expect(find.text('Choose an app'), findsOneWidget);
      expect(find.text(selfAppName), findsOneWidget);
      await tester.tap(find.text(selfAppName));
      await tester.pumpAndSettle();

      // Set a duration distinct from the default (1h 0m): +15 minutes via
      // the stepper (3 taps at the 5-minute step), for 1h 15m total.
      final increaseMinutes = find.byTooltip('Increase Minutes');
      for (var i = 0; i < 3; i++) {
        await tester.tap(increaseMinutes);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('15'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on the Limits screen, in the Active limits section, showing
      // the usage we faked (30m) against the limit we set (1h 15m).
      expect(find.text('Active limits'), findsOneWidget);
      expect(find.text(selfAppName), findsOneWidget);
      expect(find.text('30m / 1h 15m'), findsOneWidget);
    },
  );
}
