import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitstimer/models/stats.dart';
import 'package:habitstimer/services/database_service.dart';
import 'providers.dart';

final statsTodayProvider = FutureProvider.family<int, String>((ref, activityId) async {
  final db = ref.read(dbProvider);
  return db.minutesForActivityOnDay(activityId, DateTime.now());
});

final statsLast7DaysProvider = FutureProvider.family<List<DailyStat>, String>((ref, activityId) async {
  final db = ref.read(dbProvider);
  return db.last7DaysStats(activityId);
});

final hourlyTodayProvider = FutureProvider.family<List<HourlyBucket>, String>((ref, activityId) async {
  final db = ref.read(dbProvider);
  return db.hourlyDistribution(activityId, DateTime.now());
});
