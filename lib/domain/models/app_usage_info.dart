import 'dart:typed_data';

/// An app's usage total for whatever period the caller asked for — today,
/// a week, a custom range. The period isn't tracked on the model itself;
/// it's implied by which repository method produced the list.
class AppUsageInfo {
  final String packageName;
  final String appName;
  final Uint8List? iconBytes;
  final Duration totalTime;

  const AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.iconBytes,
    required this.totalTime,
  });
}
