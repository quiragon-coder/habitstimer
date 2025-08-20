import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/stats.dart';

/// STUB de stats provisoire : valeurs neutres pour débloquer la compilation.
/// On reconnectera aux vraies données DB plus tard (dans un service dédié).

// minutes du jour pour une activité (clé = id quelconque: int, String, etc.)
final statsTodayProvider =
FutureProvider.family<int, Object?>((ref, activityKey) async {
  return 0;
});

// derniers 7 jours (liste de DailyStat)
final statsLast7DaysProvider =
FutureProvider.family<List<DailyStat>, Object?>((ref, activityKey) async {
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day)
      .subtract(const Duration(days: 6));
  return List.generate(7, (i) {
    final d = DateTime(start.year, start.month, start.day)
        .add(Duration(days: i));
    return DailyStat(day: d, minutes: 0);
  });
});

// répartition horaire (24 buckets)
final hourlyTodayProvider =
FutureProvider.family<List<HourlyBucket>, Object?>(
        (ref, activityKey) async {
      return List.generate(24, (h) => HourlyBucket(hour: h, minutes: 0));
    });
