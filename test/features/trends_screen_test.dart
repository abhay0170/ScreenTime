import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/core/theme/themes.dart';
import 'package:flutter_app_usage_tracker/data/repositories/trends_repository.dart';
import 'package:flutter_app_usage_tracker/domain/models/app_usage_info.dart';
import 'package:flutter_app_usage_tracker/domain/models/daily_total.dart';
import 'package:flutter_app_usage_tracker/features/trends/presentation/trends_screen.dart';

class MockTrendsRepository extends Mock implements TrendsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });

  late MockTrendsRepository repository;

  setUp(() {
    repository = MockTrendsRepository();

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final dailyTotals = [
      for (var i = 6; i >= 0; i--)
        DailyTotal(
          date: startOfToday.subtract(Duration(days: i)),
          total: Duration(minutes: 10 * (7 - i)),
        ),
    ];

    when(
      () => repository.getDailyTotals(any(), any()),
    ).thenAnswer((_) async => dailyTotals);
    when(
      () => repository.getEarliestRecordedDate(),
    ).thenAnswer((_) async => startOfToday.subtract(const Duration(days: 6)));
    when(() => repository.getTopAppsForRange(any(), any())).thenAnswer(
      (_) async => const [
        AppUsageInfo(
          packageName: 'com.example.social',
          appName: 'Chatter',
          iconBytes: null,
          totalTime: Duration(hours: 3),
        ),
        AppUsageInfo(
          packageName: 'com.example.game',
          appName: 'Puzzle Quest',
          iconBytes: null,
          totalTime: Duration(hours: 1),
        ),
      ],
    );
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [trendsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(theme: materialFlowTheme, home: const TrendsScreen()),
    );
  }

  testWidgets('renders the chart and ranked app list from fake data', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Chatter'), findsOneWidget);
    expect(find.text('Puzzle Quest'), findsOneWidget);
    // Ranked by total descending: Chatter (3h) above Puzzle Quest (1h).
    expect(
      tester.getTopLeft(find.text('Chatter')).dy,
      lessThan(tester.getTopLeft(find.text('Puzzle Quest')).dy),
    );
  });
}
