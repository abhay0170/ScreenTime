import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/async_state_views.dart';
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
  Object? _saveError;

  Future<void> _select(String packageName) async {
    if (_completing) return;
    setState(() {
      _completing = true;
      _saveError = null;
    });

    try {
      // Hands control back to native code, which finishes this activity —
      // there's nothing further to do here once this succeeds.
      await ref
          .read(widgetConfigServiceProvider)
          .completeConfiguration(
            appWidgetId: widget.appWidgetId,
            selectedValue: packageName,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _completing = false;
        _saveError = error;
      });
    }
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
      body: Column(
        children: [
          if (_saveError != null)
            _SaveErrorBanner(
              onDismiss: () => setState(() => _saveError = null),
            ),
          Expanded(
            child: isAppUsage
                ? _AppUsagePicker(onSelected: _select)
                : _LimitCountdownPicker(onSelected: _select),
          ),
        ],
      ),
    );
  }
}

/// Shown when [WidgetConfigService.completeConfiguration] throws (e.g. a
/// MethodChannel error) — without this, a failed save would leave the
/// picker sitting there with no indication anything went wrong, and
/// Android would never finish placing the widget.
class _SaveErrorBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const _SaveErrorBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Couldn't save the widget setup. Try selecting the app again.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Dismiss',
            color: theme.colorScheme.onErrorContainer,
            onPressed: onDismiss,
          ),
        ],
      ),
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
      error: (error, stackTrace) => Center(
        child: AsyncErrorView(
          onRetry: () => ref.invalidate(todayUsageProvider),
        ),
      ),
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
      error: (error, stackTrace) => Center(
        child: AsyncErrorView(
          onRetry: () => ref.invalidate(limitsWithUsageProvider),
        ),
      ),
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
