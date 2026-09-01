import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_style.dart';
import '../../../../domain/models/daily_total.dart';

const _weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// A bar chart of daily totals, themed off [AppThemeStyle] rather than
/// fl_chart's defaults: rounded bar tops, a muted color for most days, and
/// the theme's accent color highlighting the single highest day. Shared by
/// the Trends screen and App Detail's per-app chart.
class DailyTotalsBarChart extends StatelessWidget {
  final List<DailyTotal> data;

  const DailyTotalsBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.extension<AppThemeStyle>()!;

    final hasUsage = data.any((day) => day.total > Duration.zero);
    if (data.isEmpty || !hasUsage) {
      return _EmptyChart(cardRadius: style.cardRadius);
    }

    var peakIndex = 0;
    for (var i = 1; i < data.length; i++) {
      if (data[i].total > data[peakIndex].total) peakIndex = i;
    }
    final maxSeconds = data[peakIndex].total.inSeconds.toDouble();

    final mutedColor = theme.colorScheme.surfaceContainerHighest;
    final accentColor = style.colorScheme.primary;
    final barRadius = BorderRadius.vertical(
      top: Radius.circular((style.cardRadius / 3).clamp(4, 10)),
    );
    final barWidth = data.length > 10 ? 6.0 : 16.0;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxSeconds * 1.2,
          minY: 0,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final label = _labelFor(value.toInt());
                  if (label == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: theme.textTheme.bodySmall),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].total.inSeconds.toDouble(),
                    color: i == peakIndex ? accentColor : mutedColor,
                    width: barWidth,
                    borderRadius: barRadius,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String? _labelFor(int index) {
    if (index < 0 || index >= data.length) return null;

    if (data.length <= 7) {
      return _weekdayLabels[data[index].date.weekday - 1];
    }

    // Monthly view: a label on every 5th bar (plus the last) to avoid
    // crowding the axis.
    final isLast = index == data.length - 1;
    if (index % 5 == 0 || isLast) {
      return '${data[index].date.day}';
    }
    return null;
  }
}

class _EmptyChart extends StatelessWidget {
  final double cardRadius;

  const _EmptyChart({required this.cardRadius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Text('No usage data yet', style: theme.textTheme.bodyMedium),
    );
  }
}
