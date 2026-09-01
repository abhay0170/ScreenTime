String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }
  if (minutes > 0 || duration.inSeconds == 0) {
    return '${minutes}m';
  }
  return '${duration.inSeconds}s';
}
