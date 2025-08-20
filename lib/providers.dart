import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/activity.dart';
import 'services/database_service.dart';

/// Accès au service (in-memory pour l’instant)
final dbProvider = Provider<DatabaseService>((ref) => DatabaseService());

/// Liste des activités
final activitiesProvider = FutureProvider<List<Activity>>((ref) {
  final db = ref.watch(dbProvider);
  // IMPORTANT : aligne avec DatabaseService (getActivities)
  return db.getActivities();
});
