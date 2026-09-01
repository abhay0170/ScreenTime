import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/utils/duration_formatter.dart';
import '../../../../domain/models/app_usage_info.dart';

/// The top apps by usage today, each with a bar showing its usage relative
/// to the top app — a comparison, not a limit (Limits doesn't exist yet).
class TodayTopAppsList extends StatelessWidget {
  final List<AppUsageInfo> apps;

  const TodayTopAppsList({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const SizedBox.shrink();

    final maxSeconds = apps.first.totalTimeToday.inSeconds;
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final app in apps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AppIcon(bytes: app.iconBytes),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              app.appName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatDuration(app.totalTimeToday),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: maxSeconds == 0
                              ? 0
                              : app.totalTimeToday.inSeconds / maxSeconds,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
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
