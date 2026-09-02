import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/async_state_views.dart';
import '../../../../domain/models/app_usage_info.dart';
import '../../controller/near_limit_finder.dart';
import '../widgets/today_hero_section.dart';
import '../widgets/today_top_apps_list.dart';
import '../widgets/today_widget_preview_card.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(todayUsageProvider);
    // Runs the threshold check and pushes fresh data to the home screen
    // widgets whenever usage (re)loads; results are unused here.
    ref.watch(thresholdCheckProvider);
    ref.watch(todayOverviewWidgetSyncProvider);
    ref.watch(appUsageWidgetSyncProvider);
    ref.watch(limitCountdownWidgetSyncProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(todayUsageProvider);
            ref.invalidate(yesterdayTotalProvider);
            ref.invalidate(allLimitsProvider);
            try {
              await ref.read(todayUsageProvider.future);
            } catch (_) {
              // Surfaced via the AsyncValue.error branch below already.
            }
          },
          child: usageAsync.when(
            data: (usage) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const _TodayHeader(),
                const SizedBox(height: 24),
                if (usage.isEmpty)
                  _EmptyUsageState(
                    onRefresh: () => ref.invalidate(todayUsageProvider),
                  )
                else
                  _TodayBody(usage: usage),
              ],
            ),
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 240),
                Center(child: CircularProgressIndicator()),
              ],
            ),
            error: (error, stackTrace) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const _TodayHeader(),
                AsyncErrorView(
                  onRetry: () => ref.invalidate(todayUsageProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greetingForTime(now), style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                formatFullDate(now),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}

class _EmptyUsageState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyUsageState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return EmptyStateCard(
      icon: Icons.hourglass_empty_rounded,
      title: 'No usage yet today',
      body:
          "Once you start using your apps, today's stats will show up "
          'here.',
      actionLabel: 'Refresh',
      onAction: onRefresh,
    );
  }
}

class _TodayBody extends ConsumerWidget {
  final List<AppUsageInfo> usage;

  const _TodayBody({required this.usage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final yesterdayAsync = ref.watch(yesterdayTotalProvider);
    final limitsAsync = ref.watch(allLimitsProvider);

    final todayTotal = usage.fold<Duration>(
      Duration.zero,
      (sum, app) => sum + app.totalTime,
    );
    final topApps = usage.take(4).toList();
    final nearLimitApps = limitsAsync.maybeWhen(
      data: (limits) => findNearLimitApps(usage, limits),
      orElse: () => const <AppUsageInfo>[],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TodayHeroSection(
          todayTotal: todayTotal,
          yesterdayTotal: yesterdayAsync.valueOrNull,
          nearLimitApps: nearLimitApps,
        ),
        const SizedBox(height: 24),
        Text('Top apps', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TodayTopAppsList(apps: topApps),
        const SizedBox(height: 24),
        TodayWidgetPreviewCard(total: todayTotal),
      ],
    );
  }
}
