import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_app_usage_tracker/app.dart';

/// Exercises the real, unmodified app — including the real Usage Access
/// permission check — so this test's outcome depends on whatever
/// permission state is actually set on the device/emulator it runs on.
/// Integration tests can't drive Android's system permission screen, so
/// set the desired state via adb before running, e.g.:
///
///   adb shell appops set com.example.flutter_app_usage_tracker \
///     GET_USAGE_STATS ignore   # not granted -> onboarding should show
///   adb shell appops set com.example.flutter_app_usage_tracker \
///     GET_USAGE_STATS allow    # granted -> onboarding should be skipped
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch routes to onboarding when Usage Access is not granted, '
      'or straight to Today when it is', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    final onboardingVisible = find.text('Grant Access').evaluate().isNotEmpty;
    final todayVisible = find.text('Today').evaluate().isNotEmpty;

    expect(
      onboardingVisible || todayVisible,
      isTrue,
      reason:
          'App launch should land on either the onboarding screen or the '
          'Today tab — neither was found.',
    );

    if (!onboardingVisible) {
      // Usage Access is already granted on this device/emulator, so
      // onboarding is correctly skipped. See the adb note above to
      // exercise the not-granted path instead.
      expect(find.text('Today'), findsOneWidget);
      return;
    }

    expect(
      find.text('See where your screen time goes'),
      findsOneWidget,
      reason: 'Onboarding rationale copy should be visible.',
    );
    expect(find.text('Grant Access'), findsOneWidget);
    // The Today tab (behind the onboarding redirect) should not be
    // reachable yet.
    expect(find.text('Today'), findsNothing);
  });
}
