/// Total screen time for a single day, used to plot the Trends/App Detail
/// bar charts. [date] is day-granularity (time-of-day is zeroed).
class DailyTotal {
  final DateTime date;
  final Duration total;

  const DailyTotal({required this.date, required this.total});
}
