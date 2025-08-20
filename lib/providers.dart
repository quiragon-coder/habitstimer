import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits_timer/models/activity.dart';
import 'package:habits_timer/services/database_service.dart';

final dbProvider = Provider<DatabaseService>((ref) => DatabaseService());

final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final db = ref.watch(dbProvider);
  return db.getAllActivities();
});
