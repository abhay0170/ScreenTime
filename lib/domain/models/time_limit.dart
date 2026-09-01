class TimeLimit {
  final String packageName;
  final int dailyLimitMinutes;
  final bool notifyAt80;
  final bool notifyAt100;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeLimit({
    required this.packageName,
    required this.dailyLimitMinutes,
    required this.notifyAt80,
    required this.notifyAt100,
    required this.createdAt,
    required this.updatedAt,
  });
}
