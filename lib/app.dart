import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/themes.dart';
import 'features/onboarding/presentation/onboarding_permission_screen.dart';
import 'features/today/presentation/screens/theme_preview_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = ref.watch(themeProvider);

    return MaterialApp(
      title: 'ScreenTime',
      debugShowCheckedModeBanner: false,
      theme: themeForVariant(variant),
      home: const _PermissionGate(),
    );
  }
}

/// Shows the Usage Access onboarding screen until permission is granted,
/// then proceeds to the (temporary) debug screen. The real navigation flow
/// arrives with go_router in a later step.
class _PermissionGate extends ConsumerStatefulWidget {
  const _PermissionGate();

  @override
  ConsumerState<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends ConsumerState<_PermissionGate> {
  bool? _granted;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await ref.read(usageStatsServiceProvider).checkPermission();
    if (!mounted) return;
    setState(() => _granted = granted);
  }

  @override
  Widget build(BuildContext context) {
    final granted = _granted;
    if (granted == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!granted) {
      return OnboardingPermissionScreen(
        onGranted: () => setState(() => _granted = true),
      );
    }
    return const ThemePreviewScreen();
  }
}
