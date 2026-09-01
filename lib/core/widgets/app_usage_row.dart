import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/duration_formatter.dart';
import 'app_icon.dart';

/// One app's icon, name, and duration, with a bar showing its usage
/// relative to [relativeToSeconds] (typically the top app's total in the
/// same list) — a comparison, not tied to any limit. Shared by Today's
/// top-apps list and Trends' ranked list.
class AppUsageRow extends StatelessWidget {
  final Uint8List? iconBytes;
  final String appName;
  final Duration duration;
  final int relativeToSeconds;
  final VoidCallback? onTap;

  const AppUsageRow({
    super.key,
    required this.iconBytes,
    required this.appName,
    required this.duration,
    required this.relativeToSeconds,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppIcon(bytes: iconBytes),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatDuration(duration),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: relativeToSeconds == 0
                        ? 0
                        : duration.inSeconds / relativeToSeconds,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: content,
    );
  }
}
