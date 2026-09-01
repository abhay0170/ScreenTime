import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';

/// Explains why Usage Access is needed and sends the user to Android's
/// system settings to grant it. Since there's no runtime permission dialog
/// for this permission, we watch for the app resuming (the user coming
/// back from Settings) and re-check.
class OnboardingPermissionScreen extends ConsumerStatefulWidget {
  const OnboardingPermissionScreen({super.key});

  @override
  ConsumerState<OnboardingPermissionScreen> createState() =>
      _OnboardingPermissionScreenState();
}

class _OnboardingPermissionScreenState
    extends ConsumerState<OnboardingPermissionScreen>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _recheckPermission();
    }
  }

  Future<void> _recheckPermission() async {
    final granted = await ref.read(usageStatsServiceProvider).checkPermission();
    if (!mounted) return;
    if (granted) {
      context.go('/today');
    }
  }

  Future<void> _requestAccess() async {
    setState(() => _checking = true);
    await ref.read(usageStatsServiceProvider).requestPermission();
    if (!mounted) return;
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'See where your screen time goes',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'ScreenTime needs Usage Access to see which apps you open '
                'and for how long, so it can show your stats and warn you '
                'when you hit a limit. This data never leaves your device.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _checking ? null : _requestAccess,
                child: _checking
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Grant Access'),
              ),
              const SizedBox(height: 12),
              Text(
                'This opens Android Settings — find ScreenTime and turn on '
                'Usage Access, then come back here.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
