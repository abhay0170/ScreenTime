import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:installed_apps/app_category.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/platform_type.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app_usage_tracker/data/local/database.dart';
import 'package:flutter_app_usage_tracker/data/repositories/usage_repository.dart';
import 'package:flutter_app_usage_tracker/data/services/app_info_resolver.dart';
import 'package:flutter_app_usage_tracker/data/services/usage_stats_service.dart';

class MockUsageStatsService extends Mock implements UsageStatsService {}

class MockAppInfoResolver extends Mock implements AppInfoResolver {}

AppInfo _appInfo({
  required String name,
  required String packageName,
  bool isSystemApp = false,
  bool isLaunchableApp = true,
}) {
  return AppInfo(
    name: name,
    icon: null,
    packageName: packageName,
    versionName: '1.0.0',
    versionCode: 1,
    platformType: PlatformType.nativeOrOthers,
    installedTimestamp: 0,
    isSystemApp: isSystemApp,
    isLaunchableApp: isLaunchableApp,
    category: AppCategory.undefined,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });

  late MockUsageStatsService usageStatsService;
  late MockAppInfoResolver appInfoResolver;
  late AppDatabase database;
  late UsageRepository repository;

  setUp(() {
    usageStatsService = MockUsageStatsService();
    appInfoResolver = MockAppInfoResolver();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = UsageRepositoryImpl(
      usageStatsService: usageStatsService,
      appInfoResolver: appInfoResolver,
      database: database,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('sorts by usage descending and filters noise, system, and '
      'non-launchable/unresolvable apps', () async {
    when(() => usageStatsService.queryUsageForRange(any(), any())).thenAnswer(
      (_) async => {
        'com.short.lived': 5, // below the 10s noise threshold
        'com.android.systemui': 500, // system app
        'com.social.app': 1800, // 30 min
        'com.game.app': 3600, // 60 min
        'com.background.service': 200, // not launchable
        'com.unknown.app': 50, // resolver returns null
      },
    );

    when(() => appInfoResolver.resolve('com.android.systemui')).thenAnswer(
      (_) async => _appInfo(
        name: 'System UI',
        packageName: 'com.android.systemui',
        isSystemApp: true,
      ),
    );
    when(() => appInfoResolver.resolve('com.social.app')).thenAnswer(
      (_) async => _appInfo(name: 'Social', packageName: 'com.social.app'),
    );
    when(() => appInfoResolver.resolve('com.game.app')).thenAnswer(
      (_) async => _appInfo(name: 'Game', packageName: 'com.game.app'),
    );
    when(() => appInfoResolver.resolve('com.background.service')).thenAnswer(
      (_) async => _appInfo(
        name: 'Background Service',
        packageName: 'com.background.service',
        isLaunchableApp: false,
      ),
    );
    when(
      () => appInfoResolver.resolve('com.unknown.app'),
    ).thenAnswer((_) async => null);

    final result = await repository.getTodayUsage();

    expect(result.map((app) => app.packageName), [
      'com.game.app',
      'com.social.app',
    ]);
    expect(result[0].appName, 'Game');
    expect(result[0].totalTimeToday, const Duration(hours: 1));
    expect(result[1].appName, 'Social');
    expect(result[1].totalTimeToday, const Duration(minutes: 30));

    verifyNever(() => appInfoResolver.resolve('com.short.lived'));
  });

  test('returns an empty list when there is no meaningful usage', () async {
    when(
      () => usageStatsService.queryUsageForRange(any(), any()),
    ).thenAnswer((_) async => {'com.short.lived': 3});

    final result = await repository.getTodayUsage();

    expect(result, isEmpty);
    verifyNever(() => appInfoResolver.resolve(any()));
  });
}
