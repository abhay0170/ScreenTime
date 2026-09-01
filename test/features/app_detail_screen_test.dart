import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/platform_type.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/core/di/providers.dart';
import 'package:flutter_app_usage_tracker/core/theme/themes.dart';
import 'package:flutter_app_usage_tracker/data/repositories/limits_repository.dart';
import 'package:flutter_app_usage_tracker/data/repositories/trends_repository.dart';
import 'package:flutter_app_usage_tracker/data/repositories/usage_repository.dart';
import 'package:flutter_app_usage_tracker/data/services/app_info_resolver.dart';
import 'package:flutter_app_usage_tracker/domain/models/app_usage_info.dart';
import 'package:flutter_app_usage_tracker/domain/models/daily_total.dart';
import 'package:flutter_app_usage_tracker/domain/models/time_limit.dart';
import 'package:flutter_app_usage_tracker/features/app_detail/presentation/app_detail_screen.dart';

class MockAppInfoResolver extends Mock implements AppInfoResolver {}

class MockUsageRepository extends Mock implements UsageRepository {}

class MockTrendsRepository extends Mock implements TrendsRepository {}

class MockLimitsRepository extends Mock implements LimitsRepository {}

const _packageName = 'com.example.social';
const _appName = 'Chatter';

AppInfo _fakeAppInfo() {
  return const AppInfo(
    name: _appName,
    icon: null,
    packageName: _packageName,
    versionName: '1.0.0',
    versionCode: 1,
    platformType: PlatformType.nativeOrOthers,
    installedTimestamp: 0,
    isSystemApp: false,
    isLaunchableApp: true,
    category: AppCategory.social,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });

  late MockAppInfoResolver appInfoResolver;
  late MockUsageRepository usageRepository;
  late MockTrendsRepository trendsRepository;
  late MockLimitsRepository limitsRepository;

  setUp(() {
    appInfoResolver = MockAppInfoResolver();
    usageRepository = MockUsageRepository();
    trendsRepository = MockTrendsRepository();
    limitsRepository = MockLimitsRepository();

    when(
      () => appInfoResolver.resolve(_packageName),
    ).thenAnswer((_) async => _fakeAppInfo());
    when(() => usageRepository.getTodayUsage()).thenAnswer(
      (_) async => const [
        AppUsageInfo(
          packageName: _packageName,
          appName: _appName,
          iconBytes: null,
          totalTime: Duration(hours: 1, minutes: 30),
        ),
      ],
    );
    when(
      () => trendsRepository.getDailyTotalsForApp(_packageName, any(), any()),
    ).thenAnswer(
      (_) async => [
        DailyTotal(
          date: DateTime.now(),
          total: const Duration(hours: 1, minutes: 30),
        ),
      ],
    );
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        appInfoResolverProvider.overrideWithValue(appInfoResolver),
        usageRepositoryProvider.overrideWithValue(usageRepository),
        trendsRepositoryProvider.overrideWithValue(trendsRepository),
        limitsRepositoryProvider.overrideWithValue(limitsRepository),
      ],
      child: MaterialApp(
        theme: materialFlowTheme,
        home: const AppDetailScreen(packageName: _packageName),
      ),
    );
  }

  testWidgets(
    "shows the app's name, today's usage, and limit status when a limit "
    'is set',
    (tester) async {
      when(() => limitsRepository.getLimitForPackage(_packageName)).thenAnswer(
        (_) async => TimeLimit(
          packageName: _packageName,
          dailyLimitMinutes: 120,
          notifyAt80: true,
          notifyAt100: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      );

      // The screen's content is taller than the default test surface;
      // widen it so the "Open app" button at the bottom actually mounts.
      addTearDown(tester.view.resetPhysicalSize);
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text(_appName), findsOneWidget);
      expect(find.text('Open $_appName'), findsOneWidget);
      expect(find.text('1h 30m'), findsOneWidget);
      expect(find.text('1h 30m / 2h'), findsOneWidget);
      expect(find.text('30m remaining'), findsOneWidget);
      expect(find.text('Add limit'), findsNothing);
    },
  );

  testWidgets('shows an add-limit prompt when no limit is set', (tester) async {
    when(
      () => limitsRepository.getLimitForPackage(_packageName),
    ).thenAnswer((_) async => null);

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No daily limit set for this app.'), findsOneWidget);
    expect(find.text('Add limit'), findsOneWidget);
  });
}
