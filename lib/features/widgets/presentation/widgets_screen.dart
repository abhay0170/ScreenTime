import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme_style.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../domain/models/app_usage_info.dart';

class WidgetsScreen extends ConsumerWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(todayUsageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Widgets')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Add these to your home screen for at-a-glance stats.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _TodayOverviewWidgetCard(usage: usageAsync.valueOrNull),
          const SizedBox(height: 16),
          _ConfigurableWidgetCard(
            title: 'App Usage',
            description: "Track one app's usage right from your home screen.",
            icon: Icons.apps_rounded,
            onTap: () => showAddWidgetInstructions(context, 'App Usage'),
          ),
          const SizedBox(height: 16),
          _ConfigurableWidgetCard(
            title: 'Limit Countdown',
            description: 'See how much time is left before you hit a limit.',
            icon: Icons.hourglass_bottom_rounded,
            onTap: () => showAddWidgetInstructions(context, 'Limit Countdown'),
          ),
        ],
      ),
    );
  }
}

/// Shows the "how to add this widget" bottom sheet — Android requires
/// this to be done from the home screen, an app can't place a widget
/// itself. Shared by all three widget gallery cards.
void showAddWidgetInstructions(BuildContext context, String widgetName) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _AddWidgetInstructionsSheet(widgetName: widgetName),
  );
}

class _TodayOverviewWidgetCard extends StatelessWidget {
  final List<AppUsageInfo>? usage;

  const _TodayOverviewWidgetCard({required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;

    final apps = usage ?? const <AppUsageInfo>[];
    final total = apps.fold<Duration>(
      Duration.zero,
      (sum, app) => sum + app.totalTime,
    );
    final topAppName = apps.isEmpty ? 'No usage yet' : apps.first.appName;

    return InkWell(
      borderRadius: BorderRadius.circular(style.cardRadius),
      onTap: () => showAddWidgetInstructions(context, 'Today Overview'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(style.cardRadius),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Today Overview',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: 'NO SETUP',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Shows today's total screen time and your top app.",
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _TodayOverviewPreview(total: total, topAppName: topAppName),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap for setup instructions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors the native RemoteViews layout
/// (android/.../res/layout/today_overview_widget.xml) so the in-app
/// preview matches what actually appears on the home screen.
class _TodayOverviewPreview extends StatelessWidget {
  final Duration total;
  final String topAppName;

  const _TodayOverviewPreview({required this.total, required this.topAppName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TODAY',
            style: TextStyle(
              color: Color(0xFF9A9AA2),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatDuration(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A63A),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  topAppName,
                  style: const TextStyle(
                    color: Color(0xFFC7C7CC),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gallery card for a widget type that needs a configuration step (App
/// Usage, Limit Countdown) — unlike Today Overview, there's no single
/// "the" instance to preview since each placed widget has its own
/// selected app/limit, so this just explains what it does.
class _ConfigurableWidgetCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ConfigurableWidgetCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;

    return InkWell(
      borderRadius: BorderRadius.circular(style.cardRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(style.cardRadius),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(
              label: 'SETUP REQUIRED',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWidgetInstructionsSheet extends StatelessWidget {
  final String widgetName;

  const _AddWidgetInstructionsSheet({required this.widgetName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add the $widgetName widget', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text(
            'Long-press your home screen → Widgets → ScreenTime → '
            '$widgetName',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Drag it onto your home screen to add it.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            "Android doesn't let apps place widgets automatically — this "
            'has to be done from your home screen.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}
