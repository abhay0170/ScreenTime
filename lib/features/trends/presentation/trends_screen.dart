import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/app_theme_style.dart';
import '../../../core/widgets/app_usage_row.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../domain/models/app_usage_info.dart';
import 'charts/daily_totals_bar_chart.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  TrendsRange _range = TrendsRange.weekly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailyTotalsAsync = ref.watch(dailyTotalsProvider(_range));
    final topAppsAsync = ref.watch(topAppsForRangeProvider(_range));
    final earliestAsync = ref.watch(earliestRecordedDateProvider);

    final (rangeStart, _) = _range.resolve();
    final earliest = earliestAsync.valueOrNull;
    final hasLimitedHistory = earliest != null && earliest.isAfter(rangeStart);

    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyTotalsProvider(_range));
          ref.invalidate(topAppsForRangeProvider(_range));
          try {
            await ref.read(dailyTotalsProvider(_range).future);
          } catch (_) {
            // Surfaced via the AsyncValue.error branch below already.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _RangeToggle(
              value: _range,
              onChanged: (range) => setState(() => _range = range),
            ),
            const SizedBox(height: 20),
            if (hasLimitedHistory) ...[
              _LimitedHistoryBanner(
                daysAvailable: DateTime.now().difference(earliest).inDays + 1,
                rangeDays: _range.days,
              ),
              const SizedBox(height: 12),
            ],
            dailyTotalsAsync.when(
              data: (data) => DailyTotalsBarChart(data: data),
              loading: () => const SkeletonBox(height: 180, radius: 20),
              error: (error, stackTrace) => SizedBox(
                height: 180,
                child: AsyncErrorView(
                  compact: true,
                  onRetry: () => ref.invalidate(dailyTotalsProvider(_range)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Ranked apps', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            topAppsAsync.when(
              data: (apps) => _RankedAppsList(apps: apps),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    SkeletonBox(height: 48, radius: 12),
                    SizedBox(height: 12),
                    SkeletonBox(height: 48, radius: 12),
                    SizedBox(height: 12),
                    SkeletonBox(height: 48, radius: 12),
                  ],
                ),
              ),
              error: (error, stackTrace) => AsyncErrorView(
                compact: true,
                onRetry: () => ref.invalidate(topAppsForRangeProvider(_range)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown above the chart when there's genuine usage history, but not
/// enough of it yet to fill the selected range (e.g. a Weekly view a
/// couple of days after install) — distinct from the chart's own "no
/// usage at all" empty state.
class _LimitedHistoryBanner extends StatelessWidget {
  final int daysAvailable;
  final int rangeDays;

  const _LimitedHistoryBanner({
    required this.daysAvailable,
    required this.rangeDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;
    final shownDays = daysAvailable.clamp(1, rangeDays);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(style.cardRadius / 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing $shownDays of $rangeDays days — more history will '
              'fill in as you keep using ScreenTime.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  final TrendsRange value;
  final ValueChanged<TrendsRange> onChanged;

  const _RangeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TrendsRange>(
      segments: const [
        ButtonSegment(value: TrendsRange.weekly, label: Text('Weekly')),
        ButtonSegment(value: TrendsRange.monthly, label: Text('Monthly')),
      ],
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _RankedAppsList extends StatelessWidget {
  final List<AppUsageInfo> apps;

  const _RankedAppsList({required this.apps});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No usage recorded in this range yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final maxSeconds = apps.first.totalTime.inSeconds;

    return Column(
      children: [
        for (final app in apps)
          AppUsageRow(
            iconBytes: app.iconBytes,
            appName: app.appName,
            duration: app.totalTime,
            relativeToSeconds: maxSeconds,
            onTap: () => context.push('/app-detail/${app.packageName}'),
          ),
      ],
    );
  }
}
