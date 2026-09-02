import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:installed_apps/installed_apps.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme_style.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../domain/models/app_usage_info.dart';
import '../../../domain/models/time_limit.dart';
import '../../trends/presentation/charts/daily_totals_bar_chart.dart';

class AppDetailScreen extends StatelessWidget {
  final String packageName;

  const AppDetailScreen({super.key, required this.packageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AppHeaderSection(packageName: packageName),
            const SizedBox(height: 24),
            _TodayUsageSection(packageName: packageName),
            const SizedBox(height: 24),
            Text('Last 7 days', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _WeekChartSection(packageName: packageName),
            const SizedBox(height: 24),
            _LimitSection(packageName: packageName),
            const SizedBox(height: 24),
            _OpenAppButton(packageName: packageName),
          ],
        ),
      ),
    );
  }
}

class _AppHeaderSection extends ConsumerWidget {
  final String packageName;

  const _AppHeaderSection({required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfoAsync = ref.watch(appInfoForPackageProvider(packageName));
    final theme = Theme.of(context);

    return appInfoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          _header(theme, name: packageName, iconBytes: null),
      data: (info) => _header(
        theme,
        name: info?.name ?? packageName,
        iconBytes: info?.icon,
      ),
    );
  }

  Widget _header(
    ThemeData theme, {
    required String name,
    required Uint8List? iconBytes,
  }) {
    return Row(
      children: [
        AppIcon(bytes: iconBytes, radius: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              // Real app-to-category mapping is a later step; this is a
              // placeholder chip for now.
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: const Text('Uncategorized'),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayUsageSection extends ConsumerWidget {
  final String packageName;

  const _TodayUsageSection({required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(todayUsageProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's usage", style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        usageAsync.when(
          loading: () => const SkeletonBox(width: 120, height: 32, radius: 6),
          error: (error, stackTrace) => Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                'Failed to load',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => ref.invalidate(todayUsageProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (usage) {
            final duration = _findDuration(usage, packageName);
            return Text(
              duration == null ? '—' : formatDuration(duration),
              style: theme.textTheme.headlineMedium,
            );
          },
        ),
      ],
    );
  }
}

class _WeekChartSection extends ConsumerWidget {
  final String packageName;

  const _WeekChartSection({required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(appDetailDailyTotalsProvider(packageName));

    return chartAsync.when(
      data: (data) => DailyTotalsBarChart(data: data),
      loading: () => const SkeletonBox(height: 180, radius: 20),
      error: (error, stackTrace) => SizedBox(
        height: 180,
        child: AsyncErrorView(
          compact: true,
          onRetry: () =>
              ref.invalidate(appDetailDailyTotalsProvider(packageName)),
        ),
      ),
    );
  }
}

class _LimitSection extends ConsumerWidget {
  final String packageName;

  const _LimitSection({required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitAsync = ref.watch(limitForPackageProvider(packageName));
    final usageAsync = ref.watch(todayUsageProvider);

    final usedToday = usageAsync.maybeWhen(
      data: (usage) => _findDuration(usage, packageName) ?? Duration.zero,
      orElse: () => Duration.zero,
    );

    return limitAsync.when(
      loading: () => const SkeletonBox(height: 96, radius: 16),
      error: (error, stackTrace) => AsyncErrorView(
        compact: true,
        onRetry: () => ref.invalidate(limitForPackageProvider(packageName)),
      ),
      data: (limit) => limit == null
          ? _AddLimitPrompt(packageName: packageName)
          : _LimitStatusCard(limit: limit, usedToday: usedToday),
    );
  }
}

class _LimitStatusCard extends StatelessWidget {
  final TimeLimit limit;
  final Duration usedToday;

  const _LimitStatusCard({required this.limit, required this.usedToday});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;
    final limitDuration = Duration(minutes: limit.dailyLimitMinutes);
    final progress = limitDuration.inSeconds == 0
        ? 0.0
        : usedToday.inSeconds / limitDuration.inSeconds;
    final remaining = limitDuration - usedToday;

    final Color barColor;
    if (progress >= 1.0) {
      barColor = theme.colorScheme.error;
    } else if (progress >= 0.8) {
      barColor = Colors.amber.shade700;
    } else {
      barColor = theme.colorScheme.primary;
    }

    return Container(
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
                child: Text('Daily limit', style: theme.textTheme.titleSmall),
              ),
              TextButton(
                onPressed: () =>
                    context.push('/limits/edit/${limit.packageName}'),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${formatDuration(usedToday)} / ${formatDuration(limitDuration)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: barColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining.isNegative
                ? 'Limit reached'
                : '${formatDuration(remaining)} remaining',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AddLimitPrompt extends StatelessWidget {
  final String packageName;

  const _AddLimitPrompt({required this.packageName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(style.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'No daily limit set for this app.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/limits/add', extra: packageName),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add limit'),
          ),
        ],
      ),
    );
  }
}

class _OpenAppButton extends ConsumerWidget {
  final String packageName;

  const _OpenAppButton({required this.packageName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appInfoAsync = ref.watch(appInfoForPackageProvider(packageName));
    final appName = appInfoAsync.valueOrNull?.name;

    return FilledButton.icon(
      onPressed: () => InstalledApps.startApp(packageName),
      icon: const Icon(Icons.open_in_new),
      label: Text(appName == null ? 'Open app' : 'Open $appName'),
    );
  }
}

Duration? _findDuration(List<AppUsageInfo> usage, String packageName) {
  for (final app in usage) {
    if (app.packageName == packageName) return app.totalTime;
  }
  return null;
}
