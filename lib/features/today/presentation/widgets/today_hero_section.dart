import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_style.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../../domain/models/app_usage_info.dart';
import '../../controller/usage_trend.dart';

/// The Today screen's hero card. The three themes use structurally
/// different layouts (not just different colors), keyed off
/// [AppThemeStyle.heroCardStyle].
class TodayHeroSection extends StatelessWidget {
  final Duration todayTotal;
  final Duration? yesterdayTotal;
  final List<AppUsageInfo> nearLimitApps;

  const TodayHeroSection({
    super.key,
    required this.todayTotal,
    required this.yesterdayTotal,
    required this.nearLimitApps,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<AppThemeStyle>()!;
    final yesterday = yesterdayTotal;
    final trend = yesterday == null
        ? null
        : UsageTrend(today: todayTotal, yesterday: yesterday);

    switch (style.heroCardStyle) {
      case HeroCardStyle.ring:
        return _RingHero(style: style, total: todayTotal, trend: trend);
      case HeroCardStyle.alertBanner:
        return _AlertBannerHero(
          style: style,
          total: todayTotal,
          trend: trend,
          nearLimitApps: nearLimitApps,
        );
      case HeroCardStyle.blobCard:
        return _BlobCardHero(style: style, total: todayTotal, trend: trend);
    }
  }
}

const _ringReference = Duration(hours: 8);

class _RingHero extends StatelessWidget {
  final AppThemeStyle style;
  final Duration total;
  final UsageTrend? trend;

  const _RingHero({required this.style, required this.total, this.trend});

  @override
  Widget build(BuildContext context) {
    final progress = (total.inSeconds / _ringReference.inSeconds).clamp(
      0.0,
      1.0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: style.heroGradient,
        color: style.heroGradient == null ? style.heroBackground : null,
        borderRadius: BorderRadius.circular(style.cardRadius),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Today's screen time",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatDuration(total),
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: style.displayFontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'of ~8h',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 16),
            Text(
              trend!.label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertBannerHero extends StatelessWidget {
  final AppThemeStyle style;
  final Duration total;
  final UsageTrend? trend;
  final List<AppUsageInfo> nearLimitApps;

  const _AlertBannerHero({
    required this.style,
    required this.total,
    required this.trend,
    required this.nearLimitApps,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = style.colorScheme.onSurface;
    final muted = style.colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: style.colorScheme.surface,
        borderRadius: BorderRadius.circular(style.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's screen time", style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          Text(
            formatDuration(total),
            style: TextStyle(
              color: onSurface,
              fontFamily: style.displayFontFamily,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Text(trend!.label, style: TextStyle(color: muted)),
          ],
          if (nearLimitApps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AlertBanner(style: style, app: nearLimitApps.first),
          ],
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final AppThemeStyle style;
  final AppUsageInfo app;

  const _AlertBanner({required this.style, required this.app});

  @override
  Widget build(BuildContext context) {
    final alertColor = style.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: alertColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${app.appName} is close to its daily limit',
              style: TextStyle(color: alertColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlobCardHero extends StatelessWidget {
  final AppThemeStyle style;
  final Duration total;
  final UsageTrend? trend;

  const _BlobCardHero({required this.style, required this.total, this.trend});

  @override
  Widget build(BuildContext context) {
    final onSurface = style.colorScheme.onSurface;

    return ClipRRect(
      borderRadius: BorderRadius.circular(style.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: style.heroBackground,
        child: Stack(
          children: [
            if (style.showDecorativeShapes) ...[
              Positioned(
                top: -30,
                right: -30,
                child: _Blob(
                  color: style.colorScheme.primary.withValues(alpha: 0.25),
                  size: 120,
                ),
              ),
              Positioned(
                bottom: -40,
                left: -30,
                child: _Blob(
                  color: style.colorScheme.secondary.withValues(alpha: 0.2),
                  size: 100,
                ),
              ),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's screen time",
                  style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 8),
                Text(
                  formatDuration(total),
                  style: TextStyle(
                    color: onSurface,
                    fontFamily: style.displayFontFamily,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  blobCardSubtitle(trend),
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
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

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
