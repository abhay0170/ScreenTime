/// Compares today's usage total against yesterday's for the Today screen's
/// hero card.
class UsageTrend {
  final Duration today;
  final Duration yesterday;

  const UsageTrend({required this.today, required this.yesterday});

  Duration get difference => today - yesterday;

  bool get isLower => difference < Duration.zero;
  bool get isHigher => difference > Duration.zero;

  /// Percent change vs yesterday, or null if yesterday had no usage to
  /// compare against.
  int? get percentChange {
    if (yesterday.inSeconds <= 0) return null;
    return ((difference.inSeconds.abs() / yesterday.inSeconds) * 100).round();
  }

  String get label {
    final percent = percentChange;
    if (percent == null) return 'No data for yesterday yet';
    if (percent == 0) return 'About the same as yesterday';
    return isLower
        ? '$percent% less than yesterday'
        : '$percent% more than yesterday';
  }
}

String blobCardSubtitle(UsageTrend? trend) {
  if (trend == null) return "Here's how today looks so far.";
  if (trend.isLower) return "You've had a calmer day.";
  if (trend.isHigher) return 'A bit more screen time than yesterday.';
  return 'About the same pace as yesterday.';
}
