import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../domain/models/app_usage_info.dart';
import '../../../domain/models/limit_with_usage.dart';

class LimitsScreen extends ConsumerWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(limitsWithUsageProvider);
    final usageAsync = ref.watch(todayUsageProvider);

    Widget body;
    if (limitsAsync.isLoading || usageAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (limitsAsync.hasError) {
      body = _ErrorMessage(message: '${limitsAsync.error}');
    } else if (usageAsync.hasError) {
      body = _ErrorMessage(message: '${usageAsync.error}');
    } else {
      body = _LimitsBody(
        limitsWithUsage: limitsAsync.requireValue,
        usage: usageAsync.requireValue,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Limits'),
        actions: [
          IconButton(
            tooltip: 'Add limit',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/limits/add'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(limitsWithUsageProvider);
          ref.invalidate(todayUsageProvider);
          await ref.read(limitsWithUsageProvider.future);
        },
        child: body,
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 48),
        Center(child: Text('Something went wrong: $message')),
      ],
    );
  }
}

class _LimitsBody extends StatelessWidget {
  final List<LimitWithUsage> limitsWithUsage;
  final List<AppUsageInfo> usage;

  const _LimitsBody({required this.limitsWithUsage, required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limitedPackages = limitsWithUsage
        .map((entry) => entry.limit.packageName)
        .toSet();
    final otherApps = usage
        .where((app) => !limitedPackages.contains(app.packageName))
        .toList();

    if (limitsWithUsage.isEmpty && otherApps.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [SizedBox(height: 80), _EmptyLimitsState()],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (limitsWithUsage.isNotEmpty) ...[
          Text('Active limits', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final entry in limitsWithUsage) _ActiveLimitTile(entry: entry),
          const SizedBox(height: 24),
        ],
        if (otherApps.isNotEmpty) ...[
          Text('Other apps', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final app in otherApps) _OtherAppTile(app: app),
        ],
      ],
    );
  }
}

class _EmptyLimitsState extends StatelessWidget {
  const _EmptyLimitsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No limits set yet',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Once you use a few apps today, you can set a daily limit for '
            'any of them here.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActiveLimitTile extends StatelessWidget {
  final LimitWithUsage entry;

  const _ActiveLimitTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limitDuration = Duration(minutes: entry.limit.dailyLimitMinutes);
    final progress = limitDuration.inSeconds == 0
        ? 0.0
        : entry.usedToday.inSeconds / limitDuration.inSeconds;

    final Color barColor;
    if (progress >= 1.0) {
      barColor = theme.colorScheme.error;
    } else if (progress >= 0.8) {
      barColor = Colors.amber.shade700;
    } else {
      barColor = theme.colorScheme.primary;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/limits/edit/${entry.limit.packageName}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _AppIcon(bytes: entry.iconBytes),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.appName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatDuration(entry.usedToday)} / '
                        '${formatDuration(limitDuration)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: barColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherAppTile extends StatelessWidget {
  final AppUsageInfo app;

  const _OtherAppTile({required this.app});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _AppIcon(bytes: app.iconBytes),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.appName, overflow: TextOverflow.ellipsis),
                Text(
                  '${formatDuration(app.totalTimeToday)} today',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () =>
                context.push('/limits/add', extra: app.packageName),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add limit'),
          ),
        ],
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final Uint8List? bytes;

  const _AppIcon({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: bytes != null ? MemoryImage(bytes!) : null,
      child: bytes == null ? const Icon(Icons.apps, size: 18) : null,
    );
  }
}
