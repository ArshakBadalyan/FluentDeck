/// Daily AI practice time labels: "45 sec", "12 min", "4 h", "1 h 30 min".
/// Partial minutes round down, so "left" never overstates what remains.
String formatPracticeTime(int seconds) {
  if (seconds <= 0) return '0 min';
  if (seconds < 60) return '$seconds sec';
  final totalMinutes = seconds ~/ 60;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}

String formatPracticeMinutes(int minutes) => formatPracticeTime(minutes * 60);
