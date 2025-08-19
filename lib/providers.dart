import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/database_service.dart';
import 'models/activity.dart';

final dbProvider = Provider<DatabaseService>((ref) => DatabaseService());

final activitiesProvider = FutureProvider<List<Activity>>((ref) {
  final db = ref.watch(dbProvider);
  return db.getAllActivities();
});
