import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/core/theme/themes.dart';
import 'package:flutter_app_usage_tracker/data/repositories/limits_repository.dart';
import 'package:flutter_app_usage_tracker/data/repositories/usage_repository.dart';
import 'package:flutter_app_usage_tracker/data/services/widget_config_service.dart';
import 'package:flutter_app_usage_tracker/domain/models/app_usage_info.dart';
import 'package:flutter_app_usage_tracker/domain/models/limit_with_usage.dart';
import 'package:flutter_app_usage_tracker/domain/models/time_limit.dart';
import 'package:flutter_app_usage_tracker/features/widgets/presentation/widget_config_screen.dart';

class MockUsageRepository extends Mock implements UsageRepository {}

class MockLimitsRepository extends Mock implements LimitsRepository {}

class MockWidgetConfigService extends Mock implements WidgetConfigService {}

void main() {
  late MockUsageRepository usageRepository;
  late MockLimitsRepository limitsRepository;
  late MockWidgetConfigService configService;

  setUp(() {
    usageRepository = MockUsageRepository();
    limitsRepository = MockLimitsRepository();
    configService = MockWidgetConfigService();

    when(() => usageRepository.getTodayUsage()).thenAnswer(
      (_) async => const [
        AppUsageInfo(
          packageName: 'com.example.social',
          appName: 'Chatter',
          iconBytes: null,
          totalTime: Duration(hours: 1),
        ),
      ],
    );
    when(() => limitsRepository.getLimitsWithUsage()).thenAnswer(
      (_) async => [
        LimitWithUsage(
          limit: TimeLimit(
            packageName: 'com.example.game',
            dailyLimitMinutes: 90,
            notifyAt80: true,
            notifyAt100: true,
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          appName: 'Puzzle Quest',
          iconBytes: null,
          usedToday: const Duration(minutes: 30),
        ),
      ],
    );
    when(
      () => configService.completeConfiguration(
        appWidgetId: any(named: 'appWidgetId'),
        selectedValue: any(named: 'selectedValue'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildSubject({required String mode}) {
    return ProviderScope(
      overrides: [
        usageRepositoryProvider.overrideWithValue(usageRepository),
        limitsRepositoryProvider.overrideWithValue(limitsRepository),
        widgetConfigServiceProvider.overrideWithValue(configService),
      ],
      child: MaterialApp(
        theme: materialFlowTheme,
        home: WidgetConfigScreen(mode: mode, appWidgetId: 42),
      ),
    );
  }

  testWidgets('app_usage mode lists apps with usage today and completes '
      'configuration on tap', (tester) async {
    await tester.pumpWidget(buildSubject(mode: modeAppUsage));
    await tester.pumpAndSettle();

    expect(find.text('Chatter'), findsOneWidget);

    await tester.tap(find.text('Chatter'));
    await tester.pump();

    verify(
      () => configService.completeConfiguration(
        appWidgetId: 42,
        selectedValue: 'com.example.social',
      ),
    ).called(1);
  });

  testWidgets(
    'limit_countdown mode lists apps with an active limit and completes '
    'configuration on tap',
    (tester) async {
      await tester.pumpWidget(buildSubject(mode: modeLimitCountdown));
      await tester.pumpAndSettle();

      expect(find.text('Puzzle Quest'), findsOneWidget);

      await tester.tap(find.text('Puzzle Quest'));
      await tester.pump();

      verify(
        () => configService.completeConfiguration(
          appWidgetId: 42,
          selectedValue: 'com.example.game',
        ),
      ).called(1);
    },
  );
}
