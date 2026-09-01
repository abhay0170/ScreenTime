import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/widgets/app_usage_row.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyTotalsProvider(_range));
          ref.invalidate(topAppsForRangeProvider(_range));
          await ref.read(dailyTotalsProvider(_range).future);
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
            dailyTotalsAsync.when(
              data: (data) => DailyTotalsBarChart(data: data),
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => SizedBox(
                height: 180,
                child: Center(child: Text('Failed to load: $error')),
              ),
            ),
            const SizedBox(height: 24),
            Text('Ranked apps', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            topAppsAsync.when(
              data: (apps) => _RankedAppsList(apps: apps),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Text('Failed to load: $error'),
            ),
          ],
        ),
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
