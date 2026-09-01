import 'dart:typed_data';

import 'time_limit.dart';

/// A configured [TimeLimit] enriched with the display data (name, icon) and
/// today's usage needed to render the Limits screen.
class LimitWithUsage {
  final TimeLimit limit;
  final String appName;
  final Uint8List? iconBytes;
  final Duration usedToday;

  const LimitWithUsage({
    required this.limit,
    required this.appName,
    required this.iconBytes,
    required this.usedToday,
  });
}
