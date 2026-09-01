import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app_usage_tracker/app.dart';

void main() {
  const usageStatsChannel = MethodChannel('usage_stats');

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    // Pretend Usage Access is already granted and there's no usage yet, so
    // the permission gate lets the (temporary) debug screen through without
    // hitting a real device.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(usageStatsChannel, (call) async {
          switch (call.method) {
            case 'isUsagePermission':
              return true;
            case 'queryAndAggregateUsageStats':
              return <String, dynamic>{};
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(usageStatsChannel, null);
  });

  testWidgets('shows a theme-switch chip for each of the three themes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('Material Flow'), findsOneWidget);
    expect(find.text('Night Focus'), findsOneWidget);
    expect(find.text('Calm Balance'), findsOneWidget);
  });

  testWidgets('tapping a theme chip switches the active theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Night Focus'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.scaffoldBackgroundColor, const Color(0xFF17171B));
  });
}
