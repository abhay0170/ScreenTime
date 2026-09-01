import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/core/theme/themes.dart';
import 'package:flutter_app_usage_tracker/data/repositories/usage_repository.dart';
import 'package:flutter_app_usage_tracker/domain/models/app_usage_info.dart';
import 'package:flutter_app_usage_tracker/features/widgets/presentation/widgets_screen.dart';

class MockUsageRepository extends Mock implements UsageRepository {}

void main() {
  late MockUsageRepository repository;

  setUp(() {
    repository = MockUsageRepository();
    when(() => repository.getTodayUsage()).thenAnswer(
      (_) async => const [
        AppUsageInfo(
          packageName: 'com.example.social',
          appName: 'Chatter',
          iconBytes: null,
          totalTime: Duration(hours: 1, minutes: 15),
        ),
        AppUsageInfo(
          packageName: 'com.example.game',
          appName: 'Puzzle Quest',
          iconBytes: null,
          totalTime: Duration(minutes: 20),
        ),
      ],
    );
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [usageRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(theme: materialFlowTheme, home: const WidgetsScreen()),
    );
  }

  testWidgets('shows a live Today Overview preview, a NO SETUP badge, and '
      'SETUP REQUIRED cards for App Usage / Limit Countdown', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('1h 35m'), findsOneWidget); // 1h15m + 20m
    expect(find.text('Chatter'), findsOneWidget);
    expect(find.text('NO SETUP'), findsOneWidget);
    expect(find.text('App Usage'), findsOneWidget);
    expect(find.text('Limit Countdown'), findsOneWidget);
    expect(find.text('SETUP REQUIRED'), findsNWidgets(2));
  });

  testWidgets('tapping the Today Overview card shows setup instructions', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Today Overview'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Long-press your home screen'), findsOneWidget);
    expect(find.textContaining('Today Overview'), findsWidgets);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('tapping the App Usage card shows setup instructions', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('App Usage'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Long-press your home screen'), findsOneWidget);
    expect(find.text('Add the App Usage widget'), findsOneWidget);
  });
}
