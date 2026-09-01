import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_usage_row.dart';
import '../../../../domain/models/app_usage_info.dart';

/// The top apps by usage today, each with a bar showing its usage relative
/// to the top app — a comparison, not tied to a limit. Tapping a row opens
/// App Detail for that app.
class TodayTopAppsList extends StatelessWidget {
  final List<AppUsageInfo> apps;

  const TodayTopAppsList({super.key, required this.apps});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const SizedBox.shrink();

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
