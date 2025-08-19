import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/database_service.dart';
import 'models/activity.dart';
import 'models/session.dart';

final dbProvider = Provider<DatabaseService>((ref) => DatabaseService());

final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final db = ref.read(dbProvider);
  return db.getActivities();
});

final runningSessionProvider = FutureProvider.family<Session?, int?>((ref, activityId) async {
  final db = ref.read(dbProvider);
  return db.getRunningSession(activityId);
});
