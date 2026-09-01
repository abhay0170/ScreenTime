import 'dart:typed_data';

class AppUsageInfo {
  final String packageName;
  final String appName;
  final Uint8List? iconBytes;
  final Duration totalTimeToday;

  const AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.iconBytes,
    required this.totalTimeToday,
  });
}
