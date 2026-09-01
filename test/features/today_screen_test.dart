import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/core/theme/themes.dart';
import 'package:flutter_app_usage_tracker/data/local/database.dart';
import 'package:flutter_app_usage_tracker/data/repositories/usage_repository.dart';
import 'package:flutter_app_usage_tracker/domain/models/app_usage_info.dart';
import 'package:flutter_app_usage_tracker/features/today/presentation/screens/today_screen.dart';

class MockUsageRepository extends Mock implements UsageRepository {}

final _fakeUsage = [
  const AppUsageInfo(
    packageName: 'com.example.social',
    appName: 'Chatter',
    iconBytes: null,
    totalTimeToday: Duration(hours: 1, minutes: 30),
  ),
  const AppUsageInfo(
    packageName: 'com.example.game',
    appName: 'Puzzle Quest',
    iconBytes: null,
    totalTimeToday: Duration(minutes: 45),
  ),
  const AppUsageInfo(
    packageName: 'com.example.reader',
    appName: 'Reader',
    iconBytes: null,
    totalTimeToday: Duration(minutes: 20),
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });

  late MockUsageRepository repository;
  late AppDatabase database;

  setUp(() {
    repository = MockUsageRepository();
    database = AppDatabase.forTesting(NativeDatabase.memory());

    when(() => repository.getTodayUsage()).thenAnswer((_) async => _fakeUsage);
    when(
      () => repository.getTotalForDate(any()),
    ).thenAnswer((_) async => const Duration(hours: 3));
  });

  tearDown(() async {
    await database.close();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        usageRepositoryProvider.overrideWithValue(repository),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: MaterialApp(theme: materialFlowTheme, home: const TodayScreen()),
    );
  }

  testWidgets("renders today's total and top app names (Material Flow theme)", (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // 1h30m + 45m + 20m = 2h35m, shown in both the hero card and the
    // widget preview card.
    expect(find.text('2h 35m'), findsNWidgets(2));
    expect(find.text('Chatter'), findsOneWidget);
    expect(find.text('Puzzle Quest'), findsOneWidget);
    expect(find.text('Reader'), findsOneWidget);
  });
}
