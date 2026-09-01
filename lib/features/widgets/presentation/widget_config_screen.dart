import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../domain/models/limit_with_usage.dart';

const modeAppUsage = 'app_usage';
const modeLimitCountdown = 'limit_countdown';

/// Shown by the native BaseWidgetConfigActivity (a fresh FlutterActivity,
/// see android/.../widgets/BaseWidgetConfigActivity.kt) right after the
/// user drags a configurable widget onto their home screen. Android won't
/// finish placing the widget until [WidgetConfigService.completeConfiguration]
/// is called — that happens as soon as the user taps an app below.
class WidgetConfigScreen extends ConsumerStatefulWidget {
  final String mode;
  final int appWidgetId;

  const WidgetConfigScreen({
    super.key,
    required this.mode,
    required this.appWidgetId,
  });

  @override
  ConsumerState<WidgetConfigScreen> createState() => _WidgetConfigScreenState();
}

class _WidgetConfigScreenState extends ConsumerState<WidgetConfigScreen> {
  bool _completing = false;

  Future<void> _select(String packageName) async {
    if (_completing) return;
    setState(() => _completing = true);

    // Hands control back to native code, which finishes this activity —
    // there's nothing further to do here once this returns.
    await ref
        .read(widgetConfigServiceProvider)
        .completeConfiguration(
          appWidgetId: widget.appWidgetId,
          selectedValue: packageName,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_completing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAppUsage = widget.mode == modeAppUsage;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAppUsage ? 'App Usage widget' : 'Limit Countdown widget'),
      ),
      body: isAppUsage
          ? _AppUsagePicker(onSelected: _select)
          : _LimitCountdownPicker(onSelected: _select),
    );
  }
}

class _AppUsagePicker extends ConsumerWidget {
  final ValueChanged<String> onSelected;

  const _AppUsagePicker({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(todayUsageProvider);
    final theme = Theme.of(context);

    return usageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load apps: $error')),
      data: (apps) {
        if (apps.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No usage recorded yet today. Open ScreenTime and use a '
                'few apps first, then try adding this widget again.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Choose an app', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final app in apps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: AppIcon(bytes: app.iconBytes),
                title: Text(app.appName),
                subtitle: Text('${formatDuration(app.totalTime)} today'),
                onTap: () => onSelected(app.packageName),
              ),
          ],
        );
      },
    );
  }
}

class _LimitCountdownPicker extends ConsumerWidget {
  final ValueChanged<String> onSelected;

  const _LimitCountdownPicker({required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(limitsWithUsageProvider);
    final theme = Theme.of(context);

    return limitsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text('Failed to load limits: $error')),
      data: (limits) {
        if (limits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No limits set yet. Set a daily limit for an app in '
                'ScreenTime first, then try adding this widget again.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Choose a limit', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final entry in limits)
              _LimitTile(entry: entry, onTap: onSelected),
          ],
        );
      },
    );
  }
}

class _LimitTile extends StatelessWidget {
  final LimitWithUsage entry;
  final ValueChanged<String> onTap;

  const _LimitTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(bytes: entry.iconBytes),
      title: Text(entry.appName),
      subtitle: Text(
        '${formatDuration(Duration(minutes: entry.limit.dailyLimitMinutes))} '
        'daily limit',
      ),
      onTap: () => onTap(entry.limit.packageName),
    );
  }
}
