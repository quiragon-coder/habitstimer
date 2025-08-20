import 'package:flutter_riverpod/flutter_riverpod.dart';

// STUB de stats provisoire : renvoie des valeurs neutres pour débloquer la compilation.
// On reconnectera aux vraies données DB ensuite, proprement.

class DailyStat {
  final DateTime day;
  final int minutes;
  const DailyStat({required this.day, required this.minutes});
}

class HourlyBucket {
  final int hour;
  final int minutes;
  const HourlyBucket({required this.hour, required this.minutes});
}

final statsTodayProvider = FutureProvider.family<int, String>((ref, activityId) async {
  return 0;
});

final statsLast7DaysProvider = FutureProvider.family<List<DailyStat>, String>((ref, activityId) async {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
  return List.generate(7, (i) {
    final d = DateTime(start.year, start.month, start.day).add(Duration(days: i));
    return DailyStat(day: d, minutes: 0);
  });
});

final hourlyTodayProvider = FutureProvider.family<List<HourlyBucket>, String>((ref, activityId) async {
  return List.generate(24, (h) => HourlyBucket(hour: h, minutes: 0));
});
