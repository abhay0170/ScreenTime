import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/core/theme/app_theme_variant.dart';
import 'package:flutter_app_usage_tracker/core/theme/theme_provider.dart';
import 'package:flutter_app_usage_tracker/core/theme/themes.dart';
import 'package:flutter_app_usage_tracker/data/services/notification_service.dart';
import 'package:flutter_app_usage_tracker/data/services/usage_stats_service.dart';
import 'package:flutter_app_usage_tracker/features/settings/presentation/settings_screen.dart';

class MockUsageStatsService extends Mock implements UsageStatsService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockUsageStatsService usageStatsService;
  late MockNotificationService notificationService;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    usageStatsService = MockUsageStatsService();
    notificationService = MockNotificationService();
    when(
      () => notificationService.areNotificationsEnabled(),
    ).thenAnswer((_) async => true);
    when(() => usageStatsService.requestPermission()).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    container = ProviderContainer(
      overrides: [
        usageStatsServiceProvider.overrideWithValue(usageStatsService),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
    );
    addTearDown(container.dispose);

    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) {
          final variant = ref.watch(themeProvider);
          return MaterialApp(
            theme: themeForVariant(variant),
            home: const SettingsScreen(),
          );
        },
      ),
    );
  }

  testWidgets('tapping a theme card switches the active theme', (tester) async {
    when(
      () => usageStatsService.checkPermission(),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(container.read(themeProvider), AppThemeVariant.materialFlow);

    await tester.tap(find.text('Night Focus'));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider), AppThemeVariant.nightFocus);

    await tester.tap(find.text('Calm Balance'));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider), AppThemeVariant.calmBalance);

    await tester.tap(find.text('Material Flow'));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider), AppThemeVariant.materialFlow);
  });

  testWidgets('shows granted Usage Access status without a re-grant button', (
    tester,
  ) async {
    when(
      () => usageStatsService.checkPermission(),
    ).thenAnswer((_) async => true);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Granted'), findsOneWidget);
    expect(find.text('Re-grant'), findsNothing);
  });

  testWidgets(
    'shows not-granted Usage Access status with a working re-grant button',
    (tester) async {
      when(
        () => usageStatsService.checkPermission(),
      ).thenAnswer((_) async => false);

      // The screen's content is taller than the default test surface;
      // widen it so the "Re-grant" button actually mounts.
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Not granted'), findsOneWidget);
      expect(find.text('Re-grant'), findsOneWidget);

      await tester.tap(find.text('Re-grant'));
      await tester.pump();

      verify(() => usageStatsService.requestPermission()).called(1);
    },
  );
}
