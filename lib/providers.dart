import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/activity.dart';
import 'services/database_service.dart';

final dbProvider = Provider<DatabaseService>((ref) => DatabaseService());

final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final db = ref.watch(dbProvider);
  return db.getActivities();
});
